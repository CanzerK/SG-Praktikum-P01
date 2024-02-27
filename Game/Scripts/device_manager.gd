extends Node

signal manager_did_add_available_device(device)
signal manager_did_remove_available_device(device)
signal manager_did_add_connected_device(device)
signal manager_did_remove_connected_device(device)
signal manager_did_connect_device(device)

enum MANAGER_STATE {
	UNKNOWN,
	RESETTING,
	UNSUPPORTED,
	UNAUTHORIZED,
	POEWERED_OFF,
	POWERED_ON }
	
enum DEVICE_STATE { CONNECTING, CONNECTED }
	
# List of available devices that are not connected yet.
var _available_devices = []

# List of all connected devices.
var _connected_devices = []

# Mutex to lock the lists of available and conncted devices.
var _devices_mutex: Mutex

# The instance of the sphero manager stored as a global
var _sphero_manager: Object

func _init():
	_devices_mutex = Mutex.new()

	if Engine.has_singleton("Sphero"):
		_sphero_manager = Engine.get_singleton("Sphero")
		_sphero_manager.connect("manager_state_updated", _on_manager_state_updated)
		_sphero_manager.connect("manager_did_find_device", _on_manager_did_find_device)
		_sphero_manager.connect("manager_did_disconnect_device", _on_manager_did_disconnect_device)

func _find_devices():
	if (_sphero_manager.get_state() == MANAGER_STATE.POWERED_ON):
		_sphero_manager.find_devices()

func _on_manager_state_updated(state):
	if (state == MANAGER_STATE.POWERED_ON):
		_sphero_manager.find_devices()
	
	
func _on_manager_did_find_device(device):
	print("Found device {device_name}.".format({ "device_name": device.get_name() }))
	
	_devices_mutex.lock()
	
	# If we don't have the device in the list of available devices, then add it and notify.
	var available_index = Utility.find_device_by_device(device, _available_devices)
	if available_index == -1:
		# Add the device to the list of available devices for all other controls to access.
		_available_devices.append(device);
		
		# Connect to the signals for the device so we can manage the collections.
		device.connect("device_did_update_connection_state", _on_device_did_update_connection_state)
		
		call_deferred("emit_signal", "manager_did_add_available_device", device)
	
	var connected_index = Utility.find_device_by_device(device, _connected_devices)
	if connected_index != -1:
		_connected_devices.remove_at(connected_index)
		call_deferred("emit_signal", "manager_did_remove_connected_device", device)
		
	_devices_mutex.unlock()
	
func _on_manager_did_disconnect_device(device):
	_devices_mutex.lock()
	
	var connected_index = Utility.find_device_by_device(device, _connected_devices)
	if connected_index != -1:
		_connected_devices.remove_at(connected_index)
		call_deferred("emit_signal", "manager_did_remove_connected_device", device)
	
	var available_index = Utility.find_device_by_device(device, _available_devices)
	if available_index == -1:
		_available_devices.append(device)
		
		call_deferred("emit_signal", "manager_did_add_available_device", device)
	
	_devices_mutex.unlock()
	
func _on_device_did_update_connection_state(device_name, state):
	print("Device {device_name} has state {state}.".format({ "device_name": device_name, "state": state }))
	
	if state == DEVICE_STATE.CONNECTED:
		_devices_mutex.lock()
		
		var available_index = Utility.find_device_by_device_name(device_name, _available_devices)
		var device = _available_devices[available_index]
		
		var connected_index = Utility.find_device_by_device_name(device_name, _connected_devices)
		
		if connected_index == -1:
			_connected_devices.append(device)
			call_deferred("emit_signal", "manager_did_add_connected_device", device)
		
		if available_index != -1:
			_available_devices.remove_at(available_index)
			call_deferred("emit_signal", "manager_did_remove_available_device", device)
			
		_devices_mutex.unlock()
	
	
func get_all_available_devices():
	_devices_mutex.lock()
	var available_devices_clone = _available_devices.duplicate()
	_devices_mutex.unlock()
	
	return available_devices_clone
	
	
func get_available_device(index):
	_devices_mutex.lock()
	var device = _available_devices[index]
	_devices_mutex.unlock()
	
	return device
	
	
func get_all_connected_devices():
	_devices_mutex.lock()
	var connected_devices_clone = _connected_devices.duplicate()
	_devices_mutex.unlock()
	
	return connected_devices_clone
	
	
func _process(delta):
	pass

