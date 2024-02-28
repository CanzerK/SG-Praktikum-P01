extends Node3D

const RAY_LENGTH = 1000

@export var initial_distance: float
@export var min_zoom: float
@export var max_zoom: float

@export var terrain: Terrain3D

@onready var camera = $Camera

var current_camera_focus_point: Vector3
var current_camera_dist: float
	
func _move(event: InputEventScreenDrag):
	current_camera_focus_point.x += event.relative.y * (0.1 + 0.1 * smoothstep(min_zoom, max_zoom, current_camera_dist))
	current_camera_focus_point.z -= event.relative.x * (0.1 + 0.1 * smoothstep(min_zoom, max_zoom, current_camera_dist))

func _zoom(event: InputEventScreenPinch):
	var li = event.distance
	var lf = event.distance - event.relative
	
	var zi = current_camera_dist
	var zf = (li * zi) / lf
	var zd = zf - zi
	
	if zf <= min_zoom and sign(zd) < 0:
		zf = min_zoom
		zd = zf - zi
	elif zf >= max_zoom and sign(zd) > 0:
		zf = max_zoom
		zd = zf - zi
		
	current_camera_dist = zf

func _ready():
	# Set the terrain camera - seems important.
	terrain.set_camera(camera)
	
	# Raycast from the original camera position to the terrain to reposition it at the initial distance.
	var camera_origin = camera.get_global_transform().origin
	var camera_dir = get_global_transform().basis.z
	var hit_position = terrain.get_intersection(camera_origin, -camera_dir)
	
	current_camera_dist = initial_distance
	current_camera_focus_point = hit_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var camera_dir = get_global_transform().basis.z
	position = position.lerp(current_camera_focus_point + camera_dir * current_camera_dist, delta * 14)

func _input(event):
	# Move the camera on drag.
	if event is InputEventScreenDrag:
		_move(event as InputEventScreenDrag)
		
	if event is InputEventScreenPinch:
		_zoom(event as InputEventScreenPinch)
