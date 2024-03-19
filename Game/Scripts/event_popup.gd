extends Control

signal event_popup_did_accept()
signal event_popup_did_decline()

@onready var event_text: Label = $ColorRect/EventText

var event: EventSystem.Event

# Called when the node enters the scene tree for the first time.
func _ready():
	event_text.text = event.event_text_main


func _on_accept_button_up():
	event_popup_did_accept.emit()


func _on_decline_button_up():
	event_popup_did_decline.emit()
