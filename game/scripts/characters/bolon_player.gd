# res://scripts/Player.gd
extends CharacterBody2D

# --- EXPORTS (ajustables en el inspector) ---
@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var normal_projectile_scene: PackedScene
@export var special_projectile_scene: PackedScene

@export var shoot_cooldown: float = 0.3
@export var special_cooldown: float = 5.0
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

var base_sprite_scale: Vector2 = Vector2(1, 1)
var base_collision_size: Vector2

@onready var collision_shape = $CollisionShape2D
@onready var sprite = $AnimatedSprite2D

@onready var melee_hitbox = $MeleeHitbox
@onready var pickup_detector = $PickupDetector

@onready var animation_player = $AnimatedSprite2D

func _ready():
	if collision_shape.shape is RectangleShape2D:
		base_collision_size = collision_shape.shape.size
	elif collision_shape.shape is CircleShape2D:
		base_collision_size = Vector2(collision_shape.shape.radius, collision_shape.shape.radius)
	elif collision_shape.shape is CapsuleShape2D:
		base_collision_size = Vector2(collision_shape.shape.radius * 2, collision_shape.shape.height)

	current_scale = Vector2(1, 1)
	_apply_scale()
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

	print("🔵 PLAYER: Initialized at position:", global_position)

	# Conecta las señales de los TouchScreenButtons
	# Esto se hace en el nivel principal (ver paso 5)

# --- APLICA ESCALA A SPRITE Y COLISIÓN ---
func _apply_scale():
	sprite.scale = current_scale
	pickup_detector.scale = current_scale
	if collision_shape.shape is RectangleShape2D:
		var new_size = base_collision_size * current_scale
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.size = new_size

	elif collision_shape.shape is CircleShape2D:
		var new_radius = base_collision_size.x * max(current_scale.x, current_scale.y)
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.radius = new_radius

	elif collision_shape.shape is CapsuleShape2D:
		var new_radius = base_collision_size.x * max(current_scale.x, current_scale.y) / 2.0
		var new_height = base_collision_size.y * current_scale.y
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.radius = new_radius
		collision_shape.shape.height = new_height

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
	animation_player.play("walk")
	move_direction = -1.0
	animation_player.flip_h = true

func move_right():
	animation_player.play("walk")
	move_direction = 1.0
	animation_player.flip_h = false

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
		print("🔵 PLAYER: Shoot on cooldown")
		return
	if not normal_projectile_scene:
		print("🔵 PLAYER: ERROR - normal_projectile_scene not assigned")
		return
	if current_scale.x <= min_scale:
		print("🔵 PLAYER: Too small to shoot")
		return

	print("🔵 PLAYER: Shooting normal projectile...")

	# Instantiate projectile
	var proj = normal_projectile_scene.instantiate()

	# Determine direction based on player facing
	var is_facing_left = sprite.flip_h
	var shoot_direction = Vector2.LEFT if is_facing_left else Vector2.RIGHT
	var offset_x = -30 if is_facing_left else 30
	
	
	# Calculate spawn position
	var spawn_pos = global_position + Vector2(offset_x, 0)

	# Initialize projectile BEFORE adding to tree (if it has initialize method)
	if proj.has_method("initialize"):
		proj.initialize(shoot_direction, 300.0, 25)

	# CRITICAL: Set position BEFORE adding to scene tree
	# This ensures _ready() uses the correct starting position
	proj.position = spawn_pos

	# Add to scene tree (this calls _ready())
	get_parent().add_child(proj)

	print("🔵 PLAYER: Projectile spawned at", proj.global_position, " Direction:", shoot_direction)

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
		print("🔵 PLAYER: Special on cooldown")
		return
	if not special_projectile_scene:
		print("🔵 PLAYER: ERROR - special_projectile_scene not assigned")
		return
	if current_scale.x <= min_scale:
		print("🔵 PLAYER: Too small to use special")
		return

	print("🔵 PLAYER: ⚡ Using SPECIAL attack!")

	# Instantiate projectile
	var proj = special_projectile_scene.instantiate()

	# Determine direction based on player facing
	var is_facing_left = sprite.flip_h
	var shoot_direction = Vector2.LEFT if is_facing_left else Vector2.RIGHT
	var offset_x = -40 if is_facing_left else 40

	# Calculate spawn position
	var spawn_pos = global_position + Vector2(offset_x, 0)

	# Initialize projectile BEFORE adding to tree (if it has initialize method)
	if proj.has_method("initialize"):
		proj.initialize(shoot_direction, 250.0, 50)

	# CRITICAL: Set position BEFORE adding to scene tree
	# This ensures _ready() uses the correct starting position
	proj.position = spawn_pos

	# Add to scene tree (this calls _ready())
	get_parent().add_child(proj)

	print("🔵 PLAYER: Special spawned at", proj.global_position, " Direction:", shoot_direction)

	_reduce_size(special_size_loss)
	time_since_special = 0.0

# --- MANEJO DE TAMAÑO ---
func _reduce_size(factor: float):
	current_scale *= factor
	current_scale = current_scale.clamp(
		Vector2(min_scale, min_scale),
		Vector2(max_scale, max_scale)
	)

# --- RECOLECCIÓN DE PICKUP (¡aquí está la magia!) ---
func _on_PickupDetector_area_entered():
	current_scale *= size_gain_per_pickup
	current_scale = current_scale.clamp(
		Vector2(min_scale, min_scale),
		Vector2(max_scale, max_scale)
	)
	_apply_scale()
	

# --- DAMAGE HANDLING ---
func take_damage(damage: int, source_position: Vector2 = Vector2.ZERO) -> void:
	var old_scale = current_scale.x
	print("🔵 PLAYER: TOOK DAMAGE! Damage:", damage, " Current size:", old_scale)

	# Apply knockback
	if source_position != Vector2.ZERO:
		var knockback_direction = (global_position - source_position).normalized()
		velocity += knockback_direction * 300.0
		print("🔵 PLAYER: Knockback applied -", knockback_direction)

	# Reduce size as damage
	var damage_scale_factor = 1.0 - (damage * 0.01)  # 1% size loss per damage point
	current_scale *= damage_scale_factor
	current_scale = current_scale.clamp(
		Vector2(min_scale, min_scale),
		Vector2(max_scale, max_scale)
	)
	sprite.scale = current_scale

	var new_scale = current_scale.x
	print("🔵 PLAYER: Size changed:", old_scale, "→", new_scale)

	# Check if player is too small (death condition)
	if current_scale.x <= min_scale:
		print("🔵 PLAYER: ☠️ DIED! Size reached minimum")
		SignalBus.player_died.emit()

	# Emit damage signal
	SignalBus.player_took_damage.emit(source_position)
