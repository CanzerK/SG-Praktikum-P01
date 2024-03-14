extends Node3D

var time = 0
var rand_dir = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	rand_dir = Vector2(randf_range(0.0, 1.0), randf_range(0.0, 1.0)).normalized()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	var old_pos = transform.origin
	old_pos.x += 0.02 * sin(0.5 * rand_dir.x * time)
	old_pos.z += 0.01 * cos(0.5 * rand_dir.y * time)
	transform.origin = old_pos
