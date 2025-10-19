extends CanvasLayer

@onready var btn_left = $BtnLeft
@onready var btn_right = $BtnRight
@onready var btn_jump = $BtnJump
@onready var btn_shoot = $BtnShoot
@onready var btn_special = $BtnSpecial

func _ready():
	btn_left.pressed.connect(InputManager.on_move_left_press)
	btn_left.released.connect(InputManager.on_move_left_release)
	btn_right.pressed.connect(InputManager.on_move_right_press)
	btn_right.released.connect(InputManager.on_move_right_release)
	btn_jump.pressed.connect(InputManager.on_jump_press)
	btn_shoot.pressed.connect(InputManager.on_shoot_normal_press)
	btn_special.pressed.connect(InputManager.on_special_ability_press)
