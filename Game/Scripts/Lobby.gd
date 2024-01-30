extends Control

var availableDevices: ItemList
var connectedDevices: ItemList

# Called when the node enters the scene tree for the first time.
func _ready():
	availableDevices = get_node("CenterContainer/HSplitContainer/AvailableDevices")
	availableDevices.add_item("Device 1");
	availableDevices.add_item("Device 2");
	availableDevices.add_item("Device 3");

	connectedDevices = get_node("CenterContainer/HSplitContainer/ConnectedDevices");
	connectedDevices.add_item("Device 1");
	connectedDevices.add_item("Device 2");


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

	
func _on_connected_devices_item_selected(index):
	pass


func _on_available_devices_item_selected(index):
	pass
