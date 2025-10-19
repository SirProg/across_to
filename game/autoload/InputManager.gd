extends Node

signal move_left_pressed
signal move_left_released
signal move_right_pressed
signal move_right_released
signal jump_requested
signal shoot_requested
signal melee_requested
signal special_requested
signal size_pickup_collected(amount)

func on_move_left_press(): emit_signal("move_left_pressed")
func on_move_left_release(): emit_signal("move_left_released")
func on_move_right_press(): emit_signal("move_right_pressed")
func on_move_right_release(): emit_signal("move_right_released")
func on_jump_press(): emit_signal("jump_requested")
func on_shoot_press(): emit_signal("shoot_requested")
func on_melee_press(): emit_signal("melee_requested")
func on_special_press(): emit_signal("special_requested")
