extends Area2D

var is_collected: bool = false # Verificar si fue recolectado

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	
	print("🟣🟣 Pickup Special Recolectado por: ", body.name)
	if body.name == "Bolon":
		body._on_SpecialPickupDetector_area_entered()
		is_collected = true
		queue_free()
