extends Area2D

@export var respawn_item: float = 7.0 # Tiempo de aparicion
var is_collected: bool = false # Verificar si fue recolectado

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	
	print("🟣🟣 Pickup Recolectado por: ", body.name)
	if body.name == "Bolon":
		body._on_PickupDetector_area_entered()
		is_collected = true
	disable()
	
func disable():
	# Desactivar colision y hacer visible
	monitoring = false
	monitorable = false
	visible = false
	
	await get_tree().create_timer(respawn_item).timeout
	_enable()
	
func _enable():
	is_collected = false
	# Reactiva colisión y hace visible
	monitoring = true
	monitorable = true
	visible = true
