extends Node2D

@export var speed: float = 300.0
@export var max_distance: float = 200.0  # ¡Fácil de ajustar!
@export var damage: int = 10

var start_position: Vector2

func _ready():
	start_position = position

func _process(delta):
	position += Vector2.RIGHT * speed * delta
	if position.distance_to(start_position) > max_distance:
		queue_free()
