extends Control

# UI elements in the view.
var _available_devices_container: TextureRect
var _available_devices_list: HBoxContainer
var _texture: Texture2D = load("res://assets/ui/icons/png/White/2x/phone.png")
var _devices_name_to_list_index: Dictionary = {}

@onready var _police_container: VSplitContainer = $Police_Button
@onready var _ambulance_container: VSplitContainer = $Ambulance_Button
@onready var _fire_brigade_container: VSplitContainer = $FireBrigade_Button

var _current_time = 0.0
var _current_department = -1

const BLINK_DURATION = 1.5

const COLORS = { DeviceManager.DEVICE_DEPARTMENT.POLICE: [Color(0.9, 0.1, 0.1), Color(0.1, 0.1, 0.9)],
	DeviceManager.DEVICE_DEPARTMENT.AMBULANCE: [Color(0.9, 0.1, 0.1), Color(0.9, 0.9, 0.9)],
	DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE: [Color(0.9, 0.1, 0.1), Color(0.9, 0.1, 0.1)] }

# Called when the node enters the scene tree for the first time.
func _ready():
	_available_devices_container = get_node("TextureRect")
	_available_devices_container.hide()
	
	_available_devices_list = get_node("TextureRect/ScrollContainer/HBoxContainer")
	
	var available_devices = DeviceManager.get_all_available_devices()
	for device in available_devices:
		var new_node = _create_new_button(device.get_name())
		_devices_name_to_list_index[device.get_name()] = _available_devices_list.get_child_count()
		_available_devices_list.add_child(new_node)
		
	print(_devices_name_to_list_index)
		
	DeviceManager.connect("manager_did_add_available_device", _on_manager_did_add_available_device)
	DeviceManager.connect("manager_did_remove_available_device", _on_manager_did_remove_available_device)
	DeviceManager.connect("manager_did_add_connected_device", _on_manager_did_add_connected_device)
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
	_devices_name_to_list_index[device.get_name()] = _available_devices_list.get_child_count()
	_available_devices_list.add_child(new_node)
	
	print(_devices_name_to_list_index)


func _on_manager_did_remove_available_device(device):
	var device_index = _devices_name_to_list_index[device.get_name()]
	
	for key in _devices_name_to_list_index:
		if _devices_name_to_list_index[key] > device_index:
			_devices_name_to_list_index[key] -= 1
			
	_devices_name_to_list_index.erase(device.get_name())
	var child = _available_devices_list.get_child(device_index)
	_available_devices_list.remove_child(child)
	
	print("Removing %s at index %d" % [device.get_name(), device_index])
	
	
func _on_manager_did_connect_device(device, type):
	var device_index = _devices_name_to_list_index[device.get_name()]
	
	if _current_department == DeviceManager.DEVICE_DEPARTMENT.POLICE:
		_police_container.disable()
	elif _current_department == DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE:
		_fire_brigade_container.disable()
	elif _current_department == DeviceManager.DEVICE_DEPARTMENT.AMBULANCE:
		_ambulance_container.disable()
		
	
func _on_manager_did_add_connected_device(device, type):
	device.wake()
		
	var colors = COLORS[type]	
	device.set_all_colors(colors[0], colors[1])
	
	_available_devices_container.hide()
	
	
func _on_manager_did_remove_connected_device(device):
	pass


func _process(delta):
	_current_time += delta
	
	if _current_time > BLINK_DURATION:
		while _current_time > BLINK_DURATION:
			_current_time -= BLINK_DURATION


func _on_available_devices_item_selected(device_name):
	var index = _devices_name_to_list_index[device_name]
	var device = DeviceManager.get_available_device(index)
	DeviceManager.connect_to_device(device, _current_department)
	
	print("Connecting %s at index %d" % [device.get_name(), index])


func _on_police_button_up():
	_available_devices_container.show()
	_current_department = DeviceManager.DEVICE_DEPARTMENT.POLICE


func _on_ambulance_button_up():
	_available_devices_container.show()
	_current_department = DeviceManager.DEVICE_DEPARTMENT.AMBULANCE


func _on_fire_brigade_button_up():
	_available_devices_container.show()
	_current_department = DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE
