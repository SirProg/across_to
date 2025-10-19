class_name Projectile
extends Area2D
## Boss projectile for ranged attacks
## Auto-destroys on impact or after timeout

@export var lifetime: float = 5.0
@export var sprite_color: Color = Color.RED

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: int = 10
var has_hit: bool = false

@onready var lifetime_timer: Timer = Timer.new()
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null


func _ready() -> void:
    # Setup lifetime timer
    lifetime_timer.wait_time = lifetime
    lifetime_timer.one_shot = true
    lifetime_timer.timeout.connect(_on_lifetime_timeout)
    add_child(lifetime_timer)
    lifetime_timer.start()

    # Connect collision signals
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

    # Set collision layers
    collision_layer = 4  # Projectile layer
    collision_mask = 1   # Hit player layer

    # Visual setup
    if sprite:
        sprite.modulate = sprite_color

    # Rotate sprite to face direction
    rotation = direction.angle()


func _physics_process(delta: float) -> void:
    position += direction * speed * delta


func initialize(proj_direction: Vector2, proj_speed: float, proj_damage: int) -> void:
    direction = proj_direction.normalized()
    speed = proj_speed
    damage = proj_damage


func _on_body_entered(body: Node2D) -> void:
    if has_hit:
        return

    # Check if it's the player or damageable object
    if body.has_method("take_damage"):
        body.take_damage(damage, global_position)
        _destroy()


func _on_area_entered(_area: Area2D) -> void:
    # Hit something else, destroy
    if not has_hit:
        _destroy()


func _on_lifetime_timeout() -> void:
    _destroy()


func _destroy() -> void:
    if has_hit:
        return

    has_hit = true

    # Optional: spawn impact effect here
    SignalBus.projectile_impact.emit(global_position)

    queue_free()
