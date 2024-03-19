class_name PauseMenu
extends Control

@onready var resume_button = $ResumeButton as Button
@onready var exit_button = $ExitButton as Button
@onready var pause_menu = $"."

func _ready():
	resume_button.button_down.connect(on_resume_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	
	
func on_resume_pressed() -> void:
	Engine.time_scale = 1
	pause_menu.hide()
	
	
func on_exit_pressed() -> void:
	get_tree().quit()
