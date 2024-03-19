extends Node3D

const MOVE_SPEED = 50
const MOVE_TIME = 0.4
const EXTRA_MOVE_TIME = 0.15

const DIRECTIONS = [ Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1) ]
const MOVE_DIRECTION_HEADINGS = [ 0, 90, 180, 270 ]

var _drive_ids = []
var _current_drive_id = 0

var _heading_per_device = {}

var _time_to_target = 0.0
var _total_travel_time = 0.0
var _target_location: Vector2i

var _event_popup = preload("res://scenes/game/EventWindow.tscn") as PackedScene

# 2 meters per second if at maximum speed.
const MESH_MOVE_SPEED_PER_SEC = 2.0 * (float(MOVE_SPEED) / 255.0)
const RELATIVE_LOCATION = Vector2i(-36, -262)

@onready var hud = $CanvasLayer3/HUD as HUD
@onready var sphero_mesh = $SpheroMesh
@onready var navigation = $CameraArm as CameraNavigation
@onready var camera = $CameraArm/Camera as Camera3D

@onready var _event_system: EventSystem = $EventSystem

var _event_popup_instance = null

var _event_timer = 0.0
var _has_active_event = false

# Called when the node enters the scene tree for the first time.
func _ready():
	hud.hud_pressed_move_button.connect(_on_hud_pressed_move_button)
	
	DeviceManager.manager_did_finish_driving.connect(_on_device_manager_did_finish_driving)
	
	_target_location = Vector2i(int(sphero_mesh.global_position.x), int(sphero_mesh.transform.origin.z))
	
	_event_system.event_system_did_process_event.connect(_on_event_system_did_process_event)
	_event_system.schedule_event_after_seconds(15)


func _on_device_manager_did_finish_driving(device, drive_id):
	var found_index = _drive_ids.find(drive_id)
	
	if found_index != -1:
		_drive_ids.remove_at(found_index)


func _process(delta):
	if _time_to_target > 0.0:
		_time_to_target -= delta
		_time_to_target = max(_time_to_target, 0.0)
		
		var alpha = 1.0 - _time_to_target / _total_travel_time
		
		var final_location = Vector3(_target_location.x, sphero_mesh.transform.origin.y, _target_location.y)
		sphero_mesh.global_position = lerp(sphero_mesh.global_position, final_location, alpha)
	
	if _has_active_event:
		if _event_timer >= 0.0:	
			_event_timer -= delta
		
		if _event_timer <= 0.0:
			_on_event_failed()
		
		if (RELATIVE_LOCATION + 16 * _event_system.current_event.goal_location - _target_location).length() < 4:
			_on_event_success()
		
		
func _on_event_failed():
	_has_active_event = false
	_event_timer = 0.0
	
	_event_system.schedule_event_after_seconds(15)
	
	
func _on_event_success():
	_has_active_event = false
	_event_timer = 0.0
	
	_event_system.schedule_event_after_seconds(15)
	
	hud.add_score(100.0 + _event_timer)
	

func _get_total_time(device, heading):
	var old_heading = _heading_per_device[device.get_name()]
	var total_time = MOVE_TIME
	
	if old_heading != heading:
		total_time += EXTRA_MOVE_TIME
	
	return total_time
	
	
func _move_device_with_heading(device, direction: HUD.MoveDirection):
	# Stop adding new move events if we already have something scheduled.
	if _drive_ids.size() > 0:
		return
		
	_current_drive_id += 1
	
	var heading = MOVE_DIRECTION_HEADINGS[direction]
	var move_time = _get_total_time(device, heading)
	_heading_per_device[device.get_name()] = heading
	
	device.drive(MOVE_SPEED, heading, DeviceManager.DRIVE_DIRECTION.FORWARD, move_time, _current_drive_id)


func _move_entity(direction: HUD.MoveDirection):
	_target_location += 16 * DIRECTIONS[direction]
	_time_to_target += MESH_MOVE_SPEED_PER_SEC
	
	# If the object is outside the frustom recenter.
	if !camera.is_position_in_frustum(sphero_mesh.global_position):
		navigation.current_camera_focus_point = sphero_mesh.global_position
	
	if _drive_ids.size() > 0:
		_total_travel_time += MESH_MOVE_SPEED_PER_SEC
	else:
		_total_travel_time = MESH_MOVE_SPEED_PER_SEC


func _on_hud_pressed_move_button(direction: HUD.MoveDirection):
	if _event_system.current_event.department == null:
		return
		
	_move_entity(direction)
	
	var device = DeviceManager.get_connected_device(_event_system.current_event.department)
	_move_device_with_heading(device, direction)
	
	
func _on_event_system_did_process_event(event: EventSystem.Event):
	_event_popup_instance = _event_popup.instantiate()
	_event_popup_instance.name = "event_popup"
	_event_popup_instance.event = event
	_event_popup_instance.connect("event_popup_did_accept", _on_event_popup_did_accept)
	_event_popup_instance.connect("event_popup_did_decline", _on_vent_popup_did_decline)
	hud.add_child(_event_popup_instance)
	

func _on_event_popup_did_accept():
	hud.remove_child(_event_popup_instance)
	
	_has_active_event = true
	_event_timer = 45.0
	
	
func _on_vent_popup_did_decline():
	hud.remove_child(_event_popup_instance)
	
	_has_active_event = false
	_event_system.schedule_event_after_seconds(15)
	
