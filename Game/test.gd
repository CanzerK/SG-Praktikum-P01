extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.has_singleton("Sphero"):
		var spheroManager = Engine.get_singleton("Sphero")
		spheroManager.findDevices()
		
func managerStateUpdated(state):
	print(state);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
