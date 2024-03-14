extends Control

# UI elements in the view.
var _available_devices_list: ItemList
var _connected_devices_list: ItemList
var _texture: Texture2D = load("res://assets/ui/icons/png/White/2x/phone.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	_available_devices_list = get_node("CenterContainer/HSplitContainer/AvailableDevices")
	_connected_devices_list = get_node("CenterContainer/HSplitContainer/ConnectedDevices")
	
	var available_devices = DeviceManager.get_all_available_devices()
	for device in available_devices:
		_available_devices_list.add_item(device.get_name(), _texture)
	
	var connected_devices = DeviceManager.get_all_connected_devices()
	for device in connected_devices:
		_connected_devices_list.add_item(device.get_name(), _texture)
		
	DeviceManager.connect("manager_did_add_available_device", _on_manager_did_add_available_device)
	DeviceManager.connect("manager_did_remove_available_device", _on_manager_did_remove_available_device)
	DeviceManager.connect("manager_did_add_connected_device", _on_manager_did_add_connected_device)
	DeviceManager.connect("manager_did_remove_connected_device", _on_manager_did_remove_connected_device)
		
	
func _on_manager_did_add_available_device(device):
	_available_devices_list.add_item(device.get_name(), _texture)


func _on_manager_did_remove_available_device(device):
	var index = Utility.find_device_by_device_in_list(device, _available_devices_list)
	_available_devices_list.remove_item(index)
	
	
func _on_manager_did_add_connected_device(device):
	_connected_devices_list.add_item(device.get_name(), _texture)
	
	
func _on_manager_did_remove_connected_device(device):
	var index = Utility.find_device_by_device_in_list(device, _connected_devices_list)
	_connected_devices_list.remove_item(index)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _on_connected_devices_item_selected(index):
	var device = DeviceManager.get_connected_device(index)
	
	print("Waking device %s" % device.get_name());
	
	device.wake()
	device.set_all_colors(Color(0.5, 0.1, 0.1), Color(0.1, 0.5, 0.1))
	device.drive(100, 90, DeviceManager.DRIVE_DIRECTION.FORWARD, 2.5, 0)
	device.sleep()

	
func _on_available_devices_item_selected(index):
	var device = DeviceManager.get_available_device(index)
	device.try_connect()
	
