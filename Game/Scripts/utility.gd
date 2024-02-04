extends Object

class_name Utility

static func find_device_by_device(device, collection):
	for index in len(collection):
		var other_device = collection[index]
		
		if device.get_name() == other_device.get_name():
			return index
			
	return -1
	
	
static func find_device_by_device_name(device_name, collection):
	for index in len(collection):
		var device = collection[index]
		
		if device.get_name() == device_name:
			return index
			
	return -1


static func find_device_by_device_in_list(device, list: ItemList):
	for index in list.item_count:
		var other_device_name = list.get_item_text(index)
		
		if device.get_name() == other_device_name:
			return index
			
	return -1
	
	
static func find_device_by_device_name_in_list(device_name, list: ItemList):
	for index in list.item_count:
		var other_device_name = list.get_item_text(index)
		
		if device_name == other_device_name:
			return index
			
	return -1
