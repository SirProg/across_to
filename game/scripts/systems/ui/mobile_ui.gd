extends CanvasLayer

@onready var btn_left = $LeftButton
@onready var btn_right = $RightButton
@onready var btn_jump = $JumpButton
@onready var btn_shoot = $ThrowButton
@onready var btn_special = $SpecialButton
@onready var btn_melee = $AttackButton

@onready var health_progress = $MarginContainer/HBoxContainer/VBoxContainer/TextureProgressBar
@onready var stamina_progress = $MarginContainer/HBoxContainer/VBoxContainer/TextureProgressBar2

#@onready var menu_pausa = preload("res://scenes/ui/MenuPausa.tscn")

func _ready():
	btn_left.pressed.connect(InputManager.on_move_left_press)
	btn_left.released.connect(InputManager.on_move_left_release)
	btn_right.pressed.connect(InputManager.on_move_right_press)
	btn_right.released.connect(InputManager.on_move_right_release)
	btn_jump.pressed.connect(InputManager.on_jump_press)
	btn_shoot.pressed.connect(InputManager.on_shoot_press)
	btn_special.pressed.connect(InputManager.on_special_press)
	btn_melee.pressed.connect(InputManager.on_melee_press)

#func _on_menu_pressed() -> void:
#	var popup = menu_pausa.instantiate()
#	add_child(popup)
#	popup.popup_centered()  # Abre centrado
