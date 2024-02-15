extends Control


var ready
var username
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setReady(readyText):
	$Ready.text = readyText
	ready = readyText
	
func setUsername(currentUsername):
	$UserName.text = currentUsername
	username = currentUsername
