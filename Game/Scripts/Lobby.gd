extends Control

# UI elements in the view.
var _available_devices_container: TextureRect
var _available_devices_list: HBoxContainer
var _texture: Texture2D = load("res://assets/ui/icons/png/White/2x/phone.png")

const GAME_SCENE_PATH : String = "res://scenes/game/game.tscn"

@onready var _game_scene = preload(GAME_SCENE_PATH) as PackedScene

@onready var _continue_button: Button = $Continue_Button

@onready var _police_container: Button = $Police_Container
@onready var _ambulance_container: Button = $Ambulance_Container
@onready var _fire_brigade_container: Button = $Fire_Brigade_Container

@onready var _police_tex = $Police_Container/AspectRatioContainer/CenterContainer2/Control/SubViewportContainer/SubViewport/TextureCatcher
@onready var _ambulance_tex = $Ambulance_Container/AspectRatioContainer/CenterContainer2/Control/SubViewportContainer/SubViewport/TextureCatcher
@onready var _fire_brigade_tex = $Fire_Brigade_Container/AspectRatioContainer/CenterContainer2/Control/SubViewportContainer/SubViewport/TextureCatcher

@onready var _police_button: Button = $Police_Container/Police_Button/Police
@onready var _ambulance_button: Button = $Ambulance_Container/Ambulance_Button/Ambulance
@onready var _fire_brigade_button: Button = $Fire_Brigade_Container/FireBrigade_Button/Fire

var _current_time = 0.0
var _current_department = -1

const BLINK_DURATION = 1.5

const COLORS = { DeviceManager.DEVICE_DEPARTMENT.POLICE: [Color(0.9, 0.1, 0.1), Color(0.1, 0.1, 0.9)],
	DeviceManager.DEVICE_DEPARTMENT.AMBULANCE: [Color(0.9, 0.1, 0.1), Color(0.9, 0.9, 0.9)],
	DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE: [Color(0.9, 0.1, 0.1), Color(0.9, 0.1, 0.1)] }

# Called when the node enters the scene tree for the first time.
func _ready():
	_continue_button.visible = false
	
	_available_devices_container = get_node("Available_Devices")
	_available_devices_container.hide()
	
	_available_devices_list = get_node("Available_Devices/ScrollContainer/HBoxContainer")
	
	var available_devices = DeviceManager.get_all_available_devices()
	for device in available_devices:
		var new_node = _create_new_button(device.get_name())
		_available_devices_list.add_child(new_node)
		
	DeviceManager.connect("manager_did_add_available_device", _on_manager_did_add_available_device)
	DeviceManager.connect("manager_did_remove_available_device", _on_manager_did_remove_available_device)
	DeviceManager.connect("manager_did_remove_connected_device", _on_manager_did_remove_connected_device)
	DeviceManager.connect("manager_did_connect_device", _on_manager_did_connect_device)
	
	
func _create_new_button(device_name):
	var new_button = Button.new()
	new_button.flat = true
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.name = device_name
	new_button.text = device_name
	new_button.icon = _texture
	new_button.button_up.connect(_on_available_devices_item_selected.bind(device_name))
	
	return new_button

	
func _on_manager_did_add_available_device(device):
	var new_node = _create_new_button(device.get_name())
	_available_devices_list.add_child(new_node)


func _on_manager_did_remove_available_device(device):
	var device_index = Utility.find_device_by_device_name_in_container(device.get_name(), _available_devices_list)
	var child = _available_devices_list.get_child(device_index)
	
	_available_devices_list.remove_child(child)
	
	
func _on_manager_did_connect_device(device, type):
	device.wake()
	
	print("Connected device of type %d" % type)
		
	var colors = COLORS[type]	
	device.set_all_colors(colors[0], colors[1])
	
	_available_devices_container.hide()
	
	if type == DeviceManager.DEVICE_DEPARTMENT.POLICE:
		_police_button.disabled = true
		_police_container.disabled = true
		_police_tex.should_rotate = false
	elif type == DeviceManager.DEVICE_DEPARTMENT.AMBULANCE:
		_ambulance_button.disabled = true
		_ambulance_container.disabled = true
		_ambulance_tex.should_rotate = false
	elif type == DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE:
		_fire_brigade_button.disabled = true
		_fire_brigade_container.disabled = true
		_fire_brigade_tex.should_rotate = false
		
	# If we have added all departments we should show the continue button.
	if DeviceManager._are_all_departments_populated():
		_continue_button.visible = true
	
	
func _on_manager_did_remove_connected_device(device):
	pass


func _process(delta):
	_current_time += delta
	
	if _current_time > BLINK_DURATION:
		while _current_time > BLINK_DURATION:
			_current_time -= BLINK_DURATION


func _on_available_devices_item_selected(device_name):
	if DeviceManager.is_connecting_device():
		return
		
	var device_index = Utility.find_device_by_device_name_in_container(device_name, _available_devices_list)
	var device = DeviceManager.get_available_device(device_index)
	
	DeviceManager.connect_to_device(device, _current_department)


func _on_police_button_up():
	_available_devices_container.show()
	_current_department = DeviceManager.DEVICE_DEPARTMENT.POLICE


func _on_ambulance_button_up():
	_available_devices_container.show()
	_current_department = DeviceManager.DEVICE_DEPARTMENT.AMBULANCE


func _on_fire_brigade_button_up():
	_available_devices_container.show()
	_current_department = DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE


func _on_continue_button_button_up():
	get_tree().change_scene_to_packed(_game_scene)
