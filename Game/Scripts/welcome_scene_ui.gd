class_name MainMenu
extends Control

const LOBBY_SCENE_PATH : String = "res://scenes/ui/ui_lobby.tscn"

@onready var start_button = $Button as Button
@onready var exit_button = $Button2 as Button
@onready var start_game = preload(LOBBY_SCENE_PATH) as PackedScene

func _ready():
	start_button.button_up.connect(_on_start_pressed)
	exit_button.button_up.connect(_on_exit_pressed)
	
	
func _on_start_pressed():
	get_tree().change_scene_to_packed(start_game)
	
	
func _on_exit_pressed():
	get_tree().quit()
