extends Node3D

enum BluetoothManagerState {
	CBManagerStateUnknown = 0,
	CBManagerStateResetting,
	CBManagerStateUnsupported,
	CBManagerStateUnauthorized,
	CBManagerStatePoweredOff,
	CBManagerStatePoweredOn,
};

class Device
{
	String name
}

class Player
{
	Array devices
	String name
}

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.has_singleton("Sphero"):
		var spheroManager = Engine.get_singleton("Sphero")
		
func managerStateUpdated(state):
	if (state == int(BluetoothManagerState.CBManagerStatePoweredOn)):
		if Engine.has_singleton("Sphero"):
			var spheroManager = Engine.get_singleton("Sphero")
			spheroManager.findDevices()
			
func managerDidFindDevice(device):
	listOfDevice.add(device)
	
func selectDevice(device):
	device.wake()
	device.resetYaw()
	device.resetLocation()
	device.setColor(Color(1.0, 0.0, 0.0))
	
	players[2].addDevice(device)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
