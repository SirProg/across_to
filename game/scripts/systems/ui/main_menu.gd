extends Control

func _ready():
	pass


func _on_iniciar_boton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level1/ecuador_level.tscn")
	pass # Replace with function body.

func _on_salir_pressed() -> void: get_tree().quit()
