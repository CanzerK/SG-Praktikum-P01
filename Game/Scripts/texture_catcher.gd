extends Node3D

@onready var _sub_viewport = $SubViewport
@onready var _mesh = $SubViewport/Node3D/Mesh

@export var _mesh_scene: Node3D

var _mesh_rotation = 120.0

# Called when the node enters the scene tree for the first time.
func _ready():
	_mesh.rotation_degrees.y = _mesh_rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_mesh_rotation += delta * 5.0
	_mesh.rotation_degrees.y = _mesh_rotation
