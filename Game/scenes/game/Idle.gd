extends State

func enter() -> void:
	# Enter logic for Idle state
	print("Entering Idle state")

func exit() -> void:
	# Exit logic for Idle state
	print("Exiting Idle state")

func process_physics(delta: float) -> State:
	# Physics processing logic for Idle state
	# You can add movement logic for the robots here if needed
	return null

func process_input(event: InputEvent) -> State:
	# Input processing logic for Idle state
	return null

func process_frame(delta: float) -> State:
	# Frame processing logic for Idle state
	return null
