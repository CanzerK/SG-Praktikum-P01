extends Node3D

@onready var _mesh = $Node3D/Mesh

@export var mesh_scene: Node3D
@export var mesh_rotation = 120.0

var should_rotate = true

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_scene.rotate_object_local(Vector3(0.0, 1.0, 0.0), deg_to_rad(mesh_rotation))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if should_rotate:
		mesh_scene.rotate_object_local(Vector3(0.0, 1.0, 0.0), deg_to_rad(delta * 15.0))
	else:
		mesh_scene.rotation.y = deg_to_rad(mesh_rotation)
