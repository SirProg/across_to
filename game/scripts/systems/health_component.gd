class_name HealthComponent
extends Node
## Reusable health component for any entity (player, enemies, boss)
## Handles health management, damage, healing, and death
## Emits signals for UI updates and game events

signal health_changed(current_health: int, max_health: int)
signal health_percentage_changed(percentage: float)
signal took_damage(amount: int, source_position: Vector2)
signal healed(amount: int)
signal died
signal revived

@export var max_health: int = 100
@export var start_at_max: bool = true
@export var can_die: bool = true
@export var invulnerability_time: float = 0.0

var current_health: int = 0
var is_dead: bool = false
var is_invulnerable: bool = false

@onready var invulnerability_timer: Timer = Timer.new()


func _ready() -> void:
    if start_at_max:
        current_health = max_health
    else:
        current_health = 0

    _setup_invulnerability_timer()

    # Emit initial state
    _emit_health_signals()


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> bool:
    if is_dead or is_invulnerable or amount <= 0:
        return false

    var actual_damage = min(amount, current_health)
    current_health -= actual_damage

    took_damage.emit(actual_damage, source_position)
    _emit_health_signals()

    # Start invulnerability if configured
    if invulnerability_time > 0.0:
        is_invulnerable = true
        invulnerability_timer.start()

    # Check for death
    if current_health <= 0 and can_die:
        die()

    return true


func heal(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    var previous_health = current_health
    current_health = min(current_health + amount, max_health)

    var actual_heal = current_health - previous_health

    if actual_heal > 0:
        healed.emit(actual_heal)
        _emit_health_signals()


func die() -> void:
    if is_dead:
        return

    is_dead = true
    current_health = 0
    died.emit()
    _emit_health_signals()


func revive(restore_health: int = -1) -> void:
    if not is_dead:
        return

    is_dead = false

    if restore_health < 0:
        current_health = max_health
    else:
        current_health = min(restore_health, max_health)

    revived.emit()
    _emit_health_signals()


func set_max_health(new_max: int, adjust_current: bool = true) -> void:
    max_health = new_max

    if adjust_current:
        current_health = min(current_health, max_health)

    _emit_health_signals()


func get_health_percentage() -> float:
    if max_health == 0:
        return 0.0
    return float(current_health) / float(max_health)


func is_at_max_health() -> bool:
    return current_health >= max_health


func is_below_percentage(percentage: float) -> bool:
    return get_health_percentage() < percentage


func _setup_invulnerability_timer() -> void:
    invulnerability_timer.name = "InvulnerabilityTimer"
    invulnerability_timer.wait_time = invulnerability_time
    invulnerability_timer.one_shot = true
    invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
    add_child(invulnerability_timer)


func _emit_health_signals() -> void:
    health_changed.emit(current_health, max_health)
    health_percentage_changed.emit(get_health_percentage())


func _on_invulnerability_timeout() -> void:
    is_invulnerable = false
