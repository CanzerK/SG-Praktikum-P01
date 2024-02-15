extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_register_button_down():
	var username = $UsernameText.text.strip_edges()
	var password = $PasswordText.text.strip_edges()
	var email = $EmailText.text.strip_edges()
	
	var session = await Online.nakama_client.authenticate_email_async(email, password, username, true)
	if session.is_exception():
		print(session.get_exception().message)
	Online.nakama_session = session
	self.hide()
	pass # Replace with function body.


func _on_login_button_down():
	var username = $UsernameText.text.strip_edges()
	var password = $PasswordText.text.strip_edges()
	var email = $EmailText.text.strip_edges()
	
	var session = await Online.nakama_client.authenticate_email_async(email, password, null, false)
	if session.is_exception():
		print(session.get_exception().message)
	Online.nakama_session = session
	self.hide()
	pass # Replace with function body.
