extends Node3D

@export var path: Path3D

@onready var path_follow: PathFollow3D = $PathFollow

var current_distance = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var len := path.curve.get_baked_length()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var len := path.curve.get_baked_length()
	current_distance += delta * 8.0
	
	if current_distance > len:
		current_distance = len - current_distance
		
	var sampled_point := path.curve.sample_baked_with_rotation(current_distance, true, true)
	global_transform.origin = path.global_transform.origin + sampled_point.origin
	global_transform.basis = sampled_point.basis * Basis(Vector3(0, 1, 0), deg_to_rad(180.0))
