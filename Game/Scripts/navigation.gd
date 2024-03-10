extends Node3D

const RAY_LENGTH = 1000

@export var initial_distance: float
@export var min_zoom: float
@export var max_zoom: float
@export var min_bbox: Vector2
@export var max_bbox: Vector2
@export var terrain: Terrain3D

@onready var camera = $Camera

var current_camera_focus_point: Vector3
var current_camera_dist: float
	
func _move(event: InputEventScreenDrag):
	var delta_x := event.relative.y * (0.1 + 0.1 * smoothstep(min_zoom, max_zoom, current_camera_dist))
	var expected_x := global_transform.origin.x + delta_x
	
	#if expected_x > min_bbox.x and expected_x < max_bbox.x:
	current_camera_focus_point.x += delta_x
	
	var delta_z := event.relative.x * (0.1 + 0.1 * smoothstep(min_zoom, max_zoom, current_camera_dist))
	var expected_z := global_transform.origin.z + delta_z
	
	#if expected_z > min_bbox.y and expected_z < max_bbox.y:
	current_camera_focus_point.z -= delta_z
	

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
	# var storage: Terrain3DStorage = load("res://resources/terrain_storage.res")
	# terrain.set_storage(storage)
	terrain.set_camera(camera)
	
	# Raycast from the original camera position to the terrain to reposition it at the initial distance.
	var camera_origin = camera.global_transform.origin
	var camera_dir = -camera.global_transform.basis.z
	var hit_pos = terrain.get_intersection(camera_origin, camera_dir)
	
	#if hit_pos != null:
	current_camera_focus_point = hit_pos
	#else:
	#current_camera_focus_point = Vector3(0.0, 0.0, 0.0)
		
	current_camera_dist = initial_distance

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
