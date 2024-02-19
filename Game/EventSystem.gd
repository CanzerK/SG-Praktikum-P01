# Assuming you have buttons named $AcceptButton, $RejectButton, and $PostponeButton

func _ready():
	$Accept.connect("pressed", self, "_on_accept_button_pressed")
	$Reject.connect("pressed", self, "_on_reject_button_pressed")
	$Postpone.connect("pressed", self, "_on_postpone_button_pressed")

# Function to handle accepting an event
func _on_accept_button_pressed() -> void:
	if current_event_index < events.size():
		complete_event(events[current_event_index])
		current_event_index += 1
		# Update UI for the next event if available
		if current_event_index < events.size():
			show_event(events[current_event_index])
		else:
			# No more events, clear or hide UI elements
			$EventImage.texture = null
			$EventText.text = ""

# Function to handle rejecting an event (you can implement this based on your game logic)
func _on_reject_button_pressed() -> void:
	# Your rejection logic here

# Function to handle postponing an event (you can implement this based on your game logic)
func _on_postpone_button_pressed() -> void:
	# Your postponement logic here
