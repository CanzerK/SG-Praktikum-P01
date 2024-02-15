extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	OnlineMatch.connect("matchmaker_matched", self, "OnMatchFound")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func OnMatchFound(players):
	print("players")
	self.hide()
	pass

func _on_find_match_button_down():
	$"Find Match".hide()
	
	if not Online.is_nakama_socket_connected():
		Online.connect_nakama_socket()
		await Online.socket_connected
		
	print("Looking for a match...")
	
	var data = {
		min_count = 2
	}
	
	OnlineMatch.start_matchmaking(Online.nakama_socket, data)
	pass # Replace with function body.
