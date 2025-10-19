# res://scripts/Player.gd
extends CharacterBody2D

# --- EXPORTS (ajustables en el inspector) ---
@export var move_speed: float = 150.0
@export var jump_velocity: float = -400.0
@export var normal_projectile_scene: PackedScene
@export var special_projectile_scene: PackedScene

@export var shoot_cooldown: float = 0.3
@export var special_cooldown: float = 20.0
@export var melee_duration: float = 0.2

@export var normal_size_loss: float = 0.97  # 3% de pérdida
@export var special_size_loss: float = 0.94 # 6% de pérdida
@export var size_gain_per_pickup: float = 1.1
@export var min_scale: float = 0.7
@export var max_scale: float = 2.0

# --- Estado interno ---
var move_direction: float = 0.0
var time_since_shoot: float = 0.0
var time_since_special: float = 0.0
var current_scale: Vector2 = Vector2(1, 1)

@onready var sprite = $Sprite2D
@onready var melee_hitbox = $MeleeHitbox
@onready var pickup_detector = $PickupDetector

func _ready():
	current_scale = Vector2(1, 1)
	sprite.scale = current_scale
	melee_hitbox.monitoring = false
	InputManager.move_left_pressed.connect(move_left)
	InputManager.move_left_released.connect(stop_horizontal)
	InputManager.move_right_pressed.connect(move_right)
	InputManager.move_right_released.connect(stop_horizontal)
	InputManager.jump_requested.connect(jump)
	InputManager.shoot_requested.connect(shoot_normal)
	InputManager.melee_requested.connect(attack_melee)
	InputManager.special_requested.connect(use_special)

	# Conecta las señales de los TouchScreenButtons
	# Esto se hace en el nivel principal (ver paso 5)

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Movimiento horizontal
	velocity.x = move_direction * move_speed

	# Cooldowns
	time_since_shoot += delta
	time_since_special += delta

	move_and_slide()
	sprite.scale = current_scale

# --- MOVIMIENTO ---
func move_left():
	move_direction = -1.0

func move_right():
	move_direction = 1.0

func stop_horizontal():
	move_direction = 0.0

# --- SALTO ---
func jump():
	if is_on_floor():
		velocity.y = jump_velocity

# --- DISPARO NORMAL ---
func shoot_normal():
	# Verifica cooldown, escena asignada Y tamaño suficiente
	if time_since_shoot < shoot_cooldown:
		print("En cooldown")
		return
	if not normal_projectile_scene:
		print("normal_projectile_scene no asignado")
		return
	if current_scale.x <= min_scale:
		print("Tamaño mínimo alcanzado: no puedes disparar normal")
		return

	print("Disparando normal...")
	var proj = normal_projectile_scene.instantiate()
	proj.position = position + Vector2(20 * sign(move_direction) if move_direction != 0 else 20, 0)
	get_parent().add_child(proj)

	_reduce_size(normal_size_loss)
	time_since_shoot = 0.0

# --- ATAQUE CUERPO A CUERPO ---
func attack_melee():
	if not melee_hitbox:
		print("no pegando")
		return
	melee_hitbox.monitoring = true
	print("pegando")
	await get_tree().create_timer(melee_duration).timeout
	melee_hitbox.monitoring = false

# --- HABILIDAD ESPECIAL ---
func use_special():
	if time_since_special < special_cooldown:
		print("Habilidad en cooldown")
		return
	if not special_projectile_scene:
		print("special_projectile_scene no asignado")
		return
	if current_scale.x <= min_scale:
		print("Tamaño mínimo alcanzado: no puedes usar habilidad especial")
		return

	print("Usando habilidad especial...")
	var proj = special_projectile_scene.instantiate()
	proj.position = position + Vector2(30 * sign(move_direction) if move_direction != 0 else 30, 0)
	get_parent().add_child(proj)

	_reduce_size(special_size_loss)
	time_since_special = 0.0

# --- MANEJO DE TAMAÑO ---
func _reduce_size(factor: float):
	current_scale *= factor
	current_scale = current_scale.clamp(
		Vector2(min_scale, min_scale),
		Vector2(max_scale, max_scale)
	)

func _on_PickupDetector_area_entered(area):
	if area.is_in_group("size_pickup"):
		area.queue_free()
		current_scale *= size_gain_per_pickup
		current_scale = current_scale.clamp(
			Vector2(min_scale, min_scale),
			Vector2(max_scale, max_scale)
		)
		$Sprite2D.scale = current_scale

		# ✅ Emite señal global
		InputManager.emit_signal("size_pickup_collected", size_gain_per_pickup)
