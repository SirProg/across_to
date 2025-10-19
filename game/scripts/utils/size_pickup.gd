extends Area2D

func _ready():
    add_to_group("size_pickup")
    # Auto-destrucción después de 15s
    await get_tree().create_timer(15.0).timeout
    queue_free()
