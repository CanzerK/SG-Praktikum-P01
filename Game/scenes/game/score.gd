extends Node

# Initialize scores for success and failure
var successScore := 0
var failureScore := 0

# Function to increment success score
func incrementSuccessScore(amount: int = 1) -> void:
	successScore += amount
	updateScore()

# Function to increment failure score
func incrementFailureScore(amount: int = 1) -> void:
	failureScore += amount
	updateScore()

# Function to update score display
func updateScore() -> void:
	print("Success Score: ", successScore)
	print("Failure Score: ", failureScore)
	# You can display the scores in UI elements or anywhere else as needed
