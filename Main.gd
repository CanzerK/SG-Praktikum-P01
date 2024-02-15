extends Node2D

func _get_custom_rpc_methods():
	return [
		"playerIsReady"
	]

# Called when the node enters the scene tree for the first time.
func _ready():
	$Control/ReadyScreen.connect("PlayerReady", self, "playerReady")
	pass # Replace with function body.

func playerReady():
	OnlineMatch.custom_rpc_sync(self, "playerIsReady", [OnlineMatch.get_my_session_id()])

func playerIsReady(id):
	$Control/ReadyScreen.setReadyStatus(id, "Ready")
	
	if OnlineMatch.is_network_server()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
