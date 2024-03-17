extends CharacterBody2D

# Here we want to move the robots if 

@onready
var animations = $animations

@onready
var state_machine = $state_machine

var successPopup # Variable to hold the success popup reference

func _ready() -> void:
	# Initialize the state machine, passing a reference of the player to the states,
	# that way they can move and react accordingly
	state_machine.init(self)

	# Connect to the success event 
	#Connect to the success event from here
	#connect("success_event", self, "_on_success_event")

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)

# Function to emit success event
func emit_success_event() -> void:
	emit_signal("success_event")

# Function to handle success event
func _on_success_event() -> void:
	# Show the success popup
	successPopup.show()

