# res://scripts/Player.gd
extends CharacterBody2D

@export var SPEED: float = 150.0
@export var JUMP_VELOCITY: float = -400.0
@export var normal_bullet_scene: PackedScene
@export var special_bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.3
@export var special_cooldown: float = 20.0

# Tamaño base
@export var base_scale: Vector2 = Vector2(1, 1)
var current_scale: Vector2 = Vector2(1, 1)

# Estado"res://assets/sprites/ui/controlers/basic/ButtonRight.png"
var move_direction: float = 0.0
var time_since_shoot: float = 0.0
var time_since_special: float = 0.0

@onready var _sprite = $Sprite2D
@onready var _melee_area = $MeleeAttack  # Opcional: si usas melee

func _ready():
	# Restaura escala base
	current_scale = base_scale
	_sprite.scale = current_scale

	# Conecta señales
	InputManager.move_left_pressed.connect(_on_move_left_press)
	InputManager.move_left_released.connect(_on_move_left_release)
	InputManager.move_right_pressed.connect(_on_move_right_press)
	InputManager.move_right_released.connect(_on_move_right_release)
	InputManager.jump_pressed.connect(_on_jump_press)
	InputManager.shoot_normal_pressed.connect(_on_shoot_normal)
	InputManager.special_ability_pressed.connect(_on_special_ability)

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Movimiento horizontal
	velocity.x = move_direction * SPEED

	# Cooldowns
	time_since_shoot += delta
	time_since_special += delta

	move_and_slide()

	# Actualiza escala visual
	_sprite.scale = current_scale

# --- MOVIMIENTO ---
func _on_move_left_press(): move_direction = -1.0
func _on_move_left_release(): 
	if move_direction < 0: move_direction = 0.0
func _on_move_right_press(): move_direction = 1.0
func _on_move_right_release():
	if move_direction > 0: move_direction = 0.0

# --- SALTO ---
func _on_jump_press():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

# --- DISPARO NORMAL ---
func _on_shoot_normal():
	if time_since_shoot >= shoot_cooldown:
		_shoot_normal()
		time_since_shoot = 0.0

func _shoot_normal():
	if not normal_bullet_scene: return
	var bullet = normal_bullet_scene.instantiate()
	bullet.position = position + Vector2(20 * sign(move_direction) if move_direction != 0 else 20, 0)
	bullet.damage = 10
	get_parent().add_child(bullet)

	# Reduce tamaño ligeramente
	_reduce_size(0.95)

# --- HABILIDAD ESPECIAL ---
func _on_special_ability():
	if time_since_special >= special_cooldown:
		_use_special_ability()
		time_since_special = 0.0

func _use_special_ability():
	if not special_bullet_scene: return

	# Dispara 5 balas en abanico
	for i in range(5):
		var offset = -30 + i * 15  # -30°, -15°, 0°, +15°, +30°
		var angle = deg_to_rad(offset)
		var dir = Vector2.RIGHT.rotated(angle)
		if move_direction < 0:
			dir = Vector2.LEFT.rotated(-angle)

		var bullet = special_bullet_scene.instantiate()
		bullet.position = position + Vector2(30, 0)
		bullet.move_direction = dir
		bullet.damage = 30
		get_parent().add_child(bullet)

	# Reduce tamaño drásticamente
	_reduce_size(0.7)

# --- MANEJO DE TAMAÑO ---
func _reduce_size(factor: float):
	current_scale *= factor
	# Límite mínimo para no desaparecer
	current_scale = current_scale.clamped(Vector2(0.3, 0.3), Vector2(2.0, 2.0))

# --- RECOLECCIÓN DE ÍTEMS ---
func _on_SizePickup_area_entered(pickup):
	pickup.queue_free()
	# Aumenta tamaño
	current_scale *= 1.2
	current_scale = current_scale.clamped(Vector2(0.3, 0.3), Vector2(2.0, 2.0))
