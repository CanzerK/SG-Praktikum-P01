extends Control
extends State

@onready var sprite_node: Sprite2D
@onready 
var text_node
var state_machine_event = $state_machine_event



# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	#Initialize the statee machine, passing a reference of the player to the states, 
	#that way they can move and react accordingly
	state_machine_event.init(self)
	# Replace with function body.
	
	
func _unhandled_input(event: InputEvent)  -> void:
	state_machine_event.set_process_input(event)


func _physics_process(delta : float) -> void:
	state_machine_event.process_physics(delta)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	state_machine_event.process_frame(delta)
