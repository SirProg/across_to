extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body._on_PickupDetector_area_entered()
	queue_free()
	pass # Replace with function body.
