extends Node

signal manager_did_add_available_device(device)
signal manager_did_remove_available_device(device)
signal manager_did_add_connected_device(device, type)
signal manager_did_remove_connected_device(device, type)
signal manager_did_connect_device(device, type)
signal manager_did_finish_driving(device, drive_id)

enum MANAGER_STATE {
	UNKNOWN,
	RESETTING,
	UNSUPPORTED,
	UNAUTHORIZED,
	POEWERED_OFF,
	POWERED_ON }
	
enum DEVICE_STATE { CONNECTING, CONNECTED }

enum DRIVE_DIRECTION { FORWARD, BACKWARD }

enum DEVICE_DEPARTMENT { POLICE, AMBULANCE, FIRE_BRIGADE }
	
# List of available devices that are not connected yet.
var _available_devices = []

# List of all connected devices.
var _connected_devices = {}

# Devices and their departments that have to be connected.
var _devices_in_connection = {}

# Mutex to lock the lists of available and conncted devices.
var _devices_mutex: Mutex

# The instance of the sphero manager stored as a global
var _sphero_manager: Object

func _init():
	_devices_mutex = Mutex.new()

	if Engine.has_singleton("Sphero"):
		print("Found Sphero plugin. Finding devices.")
		
		_sphero_manager = Engine.get_singleton("Sphero")
		_sphero_manager.connect("manager_state_updated", _on_manager_state_updated)
		_sphero_manager.connect("manager_did_find_device", _on_manager_did_find_device)
		_sphero_manager.connect("manager_did_disconnect_device", _on_manager_did_disconnect_device)
		
		_sphero_manager.find_devices()

func _find_devices():
	if (_sphero_manager.get_state() == MANAGER_STATE.POWERED_ON):
		_sphero_manager.find_devices()

func _on_manager_state_updated(state):
	if (state == MANAGER_STATE.POWERED_ON):
		_sphero_manager.find_devices()
	
func _on_manager_did_find_device(device):
	print("Found device {device_name}.".format({ "device_name": device.get_name() }))
	
	#_devices_mutex.lock()
	
	# If we don't have the device in the list of available devices, then add it and notify.
	var available_index = Utility.find_device_by_device(device, _available_devices)
	if available_index == -1:
		# Add the device to the list of available devices for all other controls to access.
		_available_devices.append(device);
		
		# Connect to the signals for the device so we can manage the collections.
		device.connect("device_did_update_connection_state", _on_device_did_update_connection_state)
		device.connect("device_did_finish_driving", _on_device_did_finish_driving)
		
		call_deferred("emit_signal", "manager_did_add_available_device", device)
	
	var connected_type = Utility.find_device_by_device_in_dict(device, _connected_devices)
	if connected_type != -1:
		_connected_devices.erase(connected_type)
		call_deferred("emit_signal", "manager_did_remove_connected_device", device, connected_type)
		
	#_devices_mutex.unlock()
	
func _on_manager_did_disconnect_device(device):
	#_devices_mutex.lock()
	
	var connected_type = Utility.find_device_by_device_in_dict(device, _connected_devices)
	if connected_type != -1:
		_connected_devices.erase(connected_type)
		call_deferred("emit_signal", "manager_did_remove_connected_device", device)
	
	var available_index = Utility.find_device_by_device(device, _available_devices)
	if available_index == -1:
		_available_devices.append(device)
		
		call_deferred("emit_signal", "manager_did_add_available_device", device)
	
	#_devices_mutex.unlock()
	
func _on_device_did_update_connection_state(device_name, state):
	if state == DEVICE_STATE.CONNECTED:
		#_devices_mutex.lock()
		
		var available_index = Utility.find_device_by_device_name(device_name, _available_devices)
		var device = _available_devices[available_index]

		# Add the device to the connected ones.
		var connected_type = Utility.find_device_by_device_in_dict(device, _devices_in_connection)
		if connected_type != -1:
			print("Connected device %s of type %d" % [device.get_name(), connected_type])
		
			call_deferred("emit_signal", "manager_did_connect_device", device, connected_type)
			_devices_in_connection.erase(connected_type)
			
			_connected_devices[connected_type] = device
			call_deferred("emit_signal", "manager_did_add_connected_device", device, connected_type)
		
		if available_index != -1:
			call_deferred("emit_signal", "manager_did_remove_available_device", device)
			
			_available_devices.remove_at(available_index)
			
		#_devices_mutex.unlock()
	
	
func _on_device_did_finish_driving(device_name, drive_id):
	#_devices_mutex.lock()
	
	var connected_type = Utility.find_device_by_device_name_in_dict(device_name, _devices_in_connection)
	if connected_type != -1:
		var device = _connected_devices[connected_type]
		
		call_deferred("emit_signal", "manager_did_finish_driving", device, drive_id)
		
	#_devices_mutex.unlock()
	
	
func get_all_available_devices():
	#_devices_mutex.lock()
	var available_devices_clone = _available_devices.duplicate()
	#_devices_mutex.unlock()
	
	return available_devices_clone
	
	
func get_available_device(index):
	#_devices_mutex.lock()
	var device = _available_devices[index]
	#_devices_mutex.unlock()
	
	return device
	
	
func get_all_connected_devices():
	#_devices_mutex.lock()
	var connected_devices_clone = _connected_devices.duplicate()
	#_devices_mutex.unlock()
	
	return connected_devices_clone
	
	
func get_connected_device(type: DEVICE_DEPARTMENT):
	#_devices_mutex.lock()
	var device = _connected_devices[type]
	#_devices_mutex.unlock()
	
	return device
	
	
func is_connecting_device():
	#_devices_mutex.lock()
	var has_elements = _devices_in_connection.size() > 0
	#_devices_mutex.lock()
	
	return has_elements
	
	
func connect_to_device(device, type: DEVICE_DEPARTMENT):
	#_devices_mutex.lock()
	_devices_in_connection[type] = device
	device.try_connect()
	#_devices_mutex.lock()
	
	
func _are_all_departments_populated():
	return _connected_devices.size() == 3

