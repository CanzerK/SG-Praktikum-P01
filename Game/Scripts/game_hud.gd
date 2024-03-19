class_name HUD
extends Control

@onready var pause_button = $PauseButton as Button
@onready var pause_menu = $PauseMenu
@onready var score_label = $HFlowContainer/ScoreNumber

var _current_score = 0

enum MoveDirection { NORTH, EAST, SOUTH, WEST }

signal hud_pressed_move_button(direction: MoveDirection)

func _ready():
	pause_button.button_up.connect(_on_pause_pressed)
	
	
func _on_pause_pressed():
	if !Engine.time_scale:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0


func add_score(score):
	_current_score += score
	
	score_label.text = "%d" % _current_score


func _on_up_button_pressed():
	hud_pressed_move_button.emit(MoveDirection.NORTH)


func _on_left_button_pressed():
	hud_pressed_move_button.emit(MoveDirection.WEST)


func _on_right_button_pressed():
	hud_pressed_move_button.emit(MoveDirection.EAST)


func _on_down_button_pressed():
	hud_pressed_move_button.emit(MoveDirection.SOUTH)
