extends Area2D
## Player's special projectile - more powerful, damages enemies on contact

@export var speed: float = 250.0
@export var max_distance: float = 500.0  # More range than normal
@export var damage: int = 50  # Double damage of normal

var start_position: Vector2
var direction: Vector2 = Vector2.RIGHT
var has_hit: bool = false

func _ready():
	start_position = global_position

	# Set up collision layers
	collision_layer = 16  # Player projectile layer (layer 5)
	collision_mask = 2    # Hit enemies (layer 2)

	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	print("⭐⭐ PLAYER SPECIAL: Spawned at", global_position, " Damage:", damage)

func _process(delta):
	# Move projectile
	global_position += direction * speed * delta

	# Check distance traveled
	if global_position.distance_to(start_position) > max_distance:
		print("⭐⭐ PLAYER SPECIAL: Max distance reached, destroying")
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return

	print("⭐⭐ PLAYER SPECIAL: Hit body -", body.name)

	# CRITICAL: Don't hit the player who shot it!
	if body.name == "Bolon" or body.is_in_group("player"):
		print("⭐⭐ PLAYER SPECIAL: Ignoring player collision")
		return

	# Check if it's an enemy
	if body.has_method("take_damage"):
		print("⭐⭐ PLAYER SPECIAL: Dealing", damage, "MEGA damage to", body.name, "!!!")
		body.take_damage(damage, global_position)
		_destroy()
	elif body is TileMapLayer or body is StaticBody2D:
		print("⭐⭐ PLAYER SPECIAL: Hit wall, destroying")
		_destroy()

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return

	print("⭐⭐ PLAYER SPECIAL: Hit area -", area.name)

	# Check if it's an enemy hitbox
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		print("⭐⭐ PLAYER SPECIAL: Dealing", damage, "MEGA damage to", area.get_parent().name, "!!!")
		area.get_parent().take_damage(damage, global_position)
		_destroy()

func _destroy() -> void:
	if has_hit:
		return

	has_hit = true
	print("⭐⭐ PLAYER SPECIAL: Destroyed")
	queue_free()

# Call this when spawning to set custom direction
func initialize(proj_direction: Vector2, proj_speed: float = speed, proj_damage: int = damage) -> void:
	direction = proj_direction.normalized()
	speed = proj_speed
	damage = proj_damage
	print("⭐⭐ PLAYER SPECIAL: Initialized - Dir:", direction, " Speed:", speed)
