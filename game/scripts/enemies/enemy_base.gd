class_name EnemyBase
extends CharacterBody2D
## Base class for all enemies
## Provides core functionality: health, movement, damage handling, and death
## All specific enemy types should inherit from this class

@export_group("Enemy Stats")
@export var max_health: int = 100
@export var movement_speed: float = 100.0
@export var damage_to_player: int = 10
@export var score_value: int = 100
@export var knockback_resistance: float = 0.5 ## 0 = full knockback, 1 = no knockback

@export_group("Physics")
@export var gravity: float = 980.0
@export var is_flying: bool = false

@export_group("Combat")
@export var invulnerability_time: float = 0.1 ## Time between damage instances
@export var death_duration: float = 1.0 ## How long death animation plays

var current_health: int
var is_dead: bool = false
var is_invulnerable: bool = false
var player: CharacterBody2D = null
var direction_to_player: Vector2 = Vector2.ZERO

@onready var invulnerability_timer: Timer = Timer.new()
@onready var death_timer: Timer = Timer.new()


func _ready() -> void:
	current_health = max_health
	_setup_timers()
	_on_ready()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity if not flying
	if not is_flying and not is_on_floor():
		velocity.y += gravity * delta

	# Update player tracking
	_update_player_tracking()

	# Custom physics (override in child classes)
	_process_physics(delta)

	move_and_slide()


## Virtual methods - Override in child classes
func _on_ready() -> void:
	pass


func _process_physics(_delta: float) -> void:
	pass


func _on_take_damage(_damage: int, _source_position: Vector2) -> void:
	pass


func _on_death() -> void:
	pass


## Public methods
func take_damage(damage: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invulnerable:
		return

	current_health -= damage
	current_health = max(0, current_health)

	# Start invulnerability period
	is_invulnerable = true
	invulnerability_timer.start()

	# Apply knockback
	if source_position != Vector2.ZERO:
		_apply_knockback(source_position)

	# Custom damage response
	_on_take_damage(damage, source_position)

	# Check for death
	if current_health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	# Emit signal for score/game tracking
	SignalBus.enemy_defeated.emit(get_enemy_type(), global_position)

	# Custom death behavior
	_on_death()

	# Start death timer
	death_timer.start()


func get_enemy_type() -> String:
	return "base_enemy"


func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)


func set_player_reference(player_node: CharacterBody2D) -> void:
	player = player_node


## Private methods
func _setup_timers() -> void:
	# Invulnerability timer
	invulnerability_timer.wait_time = invulnerability_time
	invulnerability_timer.one_shot = true
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	add_child(invulnerability_timer)

	# Death timer
	death_timer.wait_time = death_duration
	death_timer.one_shot = true
	death_timer.timeout.connect(_on_death_timer_timeout)
	add_child(death_timer)


func _update_player_tracking() -> void:
	if player and is_instance_valid(player):
		direction_to_player = (player.global_position - global_position).normalized()


func _apply_knockback(source_position: Vector2) -> void:
	var knockback_direction = (global_position - source_position).normalized()
	var knockback_strength = (1.0 - knockback_resistance) * 300.0
	velocity += knockback_direction * knockback_strength


func _on_invulnerability_timeout() -> void:
	is_invulnerable = false


func _on_death_timer_timeout() -> void:
	queue_free()
