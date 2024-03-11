extends Node3D

const RAY_LENGTH = 1000

@export var initial_distance: float
@export var min_zoom: float
@export var max_zoom: float
@export var min_bbox: Vector2
@export var max_bbox: Vector2
@export var terrain: Terrain3D

@onready var camera = $Camera

var touch_points: Dictionary = {}
var start_zoom: Vector2
var start_dist: float
var current_dist: float
var last_dist: float
var current_camera_focus_point: Vector3
var current_camera_dist: float
		
func _handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)
		
	if touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		start_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		current_dist = start_dist
		last_dist = start_dist
	elif touch_points.size() < 2:
		start_dist = 0
		current_dist = 0
		last_dist = 0

func _handle_drag(event: InputEventScreenDrag):
	touch_points[event.index] = event.position
	
	if touch_points.size() == 1:
		_move(event)
	elif touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		last_dist = current_dist
		current_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		
		_zoom()
		
func _move(event: InputEventScreenDrag):
	var delta_x := event.relative.y * (0.1 + 0.1 * smoothstep(min_zoom, max_zoom, current_camera_dist))
	var expected_x := global_transform.origin.x + delta_x
	
	#if expected_x > min_bbox.x and expected_x < max_bbox.x:
	current_camera_focus_point.x += delta_x
	
	var delta_z := event.relative.x * (0.1 + 0.1 * smoothstep(min_zoom, max_zoom, current_camera_dist))
	var expected_z := global_transform.origin.z + delta_z
	
	#if expected_z > min_bbox.y and expected_z < max_bbox.y:
	current_camera_focus_point.z -= delta_z
	
func _zoom():
	var li = last_dist
	var lf = current_dist
	
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
	terrain.set_camera(camera)
	
	current_camera_dist = initial_distance

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var camera_dir = get_global_transform().basis.z
	position = position.lerp(current_camera_focus_point + camera_dir * current_camera_dist, delta * 14)
		
func _input(event):
	# Move the camera on drag.
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
