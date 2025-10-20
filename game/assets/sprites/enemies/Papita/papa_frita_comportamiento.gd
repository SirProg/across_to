extends CharacterBody2D

@export var SPEED = 40.0
@export var CHASE_SPEED = 200.0
@export var REACTION_TIME = 0.6
@export var JUMP_IMPULSE_VERTICAL = 360.0
@export var JUMP_IMPULSE_HORIZONTAL = 200.0
@export var LIFE = 100

var direccion = 1
var following = false
var preparing_to_follow = false
var vision = 0
var can_jump = true
var dumbness = 0
var current_anim = "" # Almacena la animación actual

@onready var as_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var rc_right: RayCast2D = $RayCastRight
@onready var rc_left: RayCast2D = $RayCastLeft
@onready var player = get_tree().get_first_node_in_group("Player") 

func _ready():
	# Inicialización de la "tontería" del enemigo
	dumbness = randi_range(1, 3)
	match dumbness:
		1:
			print("Es demasiado idiota")
			vision = 150
		2:
			print("Es un poco tonto")
			vision = 225
		_:
			print("Es tontito")
			vision = 300
	
	# Solución: Conectar la señal para manejar el fin de las animaciones temporales
	as_2d.connect("animation_finished", _on_animation_finished)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# --- Detección y Lógica de Seguimiento ---
	
	# Detectar jugador a través de RayCasts
	if rc_right.is_colliding() and rc_right.get_collider().is_in_group("Player"):
		start_follow_delay()
	elif rc_left.is_colliding() and rc_left.get_collider().is_in_group("Player"):
		start_follow_delay()

	# Dejar de seguir si está muy lejos
	if abs(player.position.x - position.x) > vision:
		following = false
		preparing_to_follow = false

	# Actualizar dirección visual
	update_sprite_direction()

	# --- Movimiento y Animación ---
	
	if following:
		# MODIFICACIÓN CLAVE: Usar animación "walking" en lugar de "running"
		set_animation("walking") 
		
		SPEED = CHASE_SPEED # ¡Pero mantiene la velocidad alta!
		direccion = sign(player.position.x - position.x)
		
		# Lógica de salto (depende de dumbness)
		if dumbness >= 2 and randf() > 0.98:
			saltar(0.99)
		elif dumbness > 2:
			saltar(0.99)
		
	elif not preparing_to_follow:
		# Movimiento de patrulla (caminar)
		SPEED = 80.0
		# Animación de caminar a velocidad normal (la misma "walking")
		set_animation("walking") 
		
		if is_on_wall() and is_on_floor():
			direccion *= -1
			position.x += direccion * 2
	else:
		# Estado de espera
		SPEED = 0.0
		# Establece la animación "idle"
		set_animation("idle")

	# Gravedad y movimiento final
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = SPEED * direccion

	move_and_slide()
	detect_damage()


func start_follow_delay() -> void:
	if following or preparing_to_follow:
		return
	
	preparing_to_follow = true
	SPEED = 0.0
	velocity.x = 0.0
	print("Esperando antes de seguir...")

	set_animation("idle")

	await get_tree().create_timer(REACTION_TIME).timeout
	
	# Salta justo al empezar a seguir (opcional, con baja probabilidad)
	saltar(0.5) 
	
	preparing_to_follow = false
	following = true
	print("¡Siguiendo!")


func saltar(prob: float) -> void:
	if randf() > prob and is_on_floor(): 
		print("Salta")
		var dir_x = sign(player.position.x - position.x)
		direccion = dir_x
		velocity.x = dir_x * (JUMP_IMPULSE_HORIZONTAL * 0.6)
		velocity.y = -JUMP_IMPULSE_VERTICAL
		# Establece la animación de salto
		set_animation("jump")


func detect_damage():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Asume que el Player tiene un método get_damage()
		if collider.is_in_group("Player") and collider.has_method("get_damage"):
			var damage = collider.get_damage()
			LIFE -= damage
			print("Recibió daño: " + str(damage))
			print("Vida restante: " + str(LIFE))
			
			# Establece la animación de daño
			set_animation("get_damage") 
			
			# Efecto de empuje hacia atrás
			direccion = -sign(player.position.x - position.x)
			velocity.x = direccion * (300 * 0.6)
			velocity.y = -JUMP_IMPULSE_VERTICAL + 100
			
			set_animation("walking") 
			if LIFE <= 0:
				queue_free()


# === FUNCIONES AUXILIARES ===

func _on_animation_finished():
	# Si la animación terminada es "jump" o "get_damage", 
	# reseteamos current_anim para forzar una nueva animación de movimiento 
	# (walking/idle) en el siguiente _physics_process.
	if current_anim == "jump" or current_anim == "get_damage":
		current_anim = "" 

func update_sprite_direction():
	# Voltear sprite según dirección
	as_2d.flip_h = direccion > 0


func set_animation(name: String):
	# Cambia animación solo si es diferente
	if current_anim != name:
		current_anim = name
		as_2d.play(name)
