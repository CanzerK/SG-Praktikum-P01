extends Node
class_name EventSystem

const ALL_EVENTS = [
	"res://Events/JSON_Files/CarAccident.json",
	"res://Events/JSON_Files/CatTree.json",
	"res://Events/JSON_Files/FastCar.json",
	"res://Events/JSON_Files/GraffitiInPart.json",
	"res://Events/JSON_Files/LostBook.json" ]

const EVENT_DEPARTMENTS = [ DeviceManager.DEVICE_DEPARTMENT.POLICE,
	DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE,
	DeviceManager.DEVICE_DEPARTMENT.AMBULANCE,
	DeviceManager.DEVICE_DEPARTMENT.POLICE,
	DeviceManager.DEVICE_DEPARTMENT.FIRE_BRIGADE ]

const EVENT_LOCATIONS = [ Vector2i(-5, 5),
	Vector2i(-4, 2),
	Vector2i(8, 3),
	Vector2i(-16, -7),
	Vector2i(28, 0) ]


class EventReader:
	var name: String
	var event_time: Dictionary  # Dictionary to store time components

	func _init(name, event_time):
		self.name = name
		self.event_time = event_time
		
		
class Event:
	var event_id: int
	var event_name: String
	var event_text_main: String
	var event_text_fail: String
	var event_text_ok: String
	var img_fail: Texture2D = null
	var img_ok: Texture2D = null
	var timestamp: int
	var complete_timestamp: int
	var is_processed: bool = false
	var goal_location: Vector2i
	var department: DeviceManager.DEVICE_DEPARTMENT

signal event_system_did_process_event(event)

var _current_event_index = 0
var current_event: Event = null
var upcoming_events = []

func _ready():
	#Loading of random events in the array
	for i in range(0, 29):
		upcoming_events.append(i)
		
	for i in range(0, 17):
		var random_int = randi_range(0, upcoming_events.size() - 1)
		upcoming_events.erase(random_int)


func _read_event(path):
	var itemData = load_json_file(path)
	
	var new_event = Event.new()
	new_event.event_id = itemData["EventId"]
	new_event.event_name = itemData["EventName"]
	
	if "ImgOK" in itemData and itemData["ImgOK"] != null:
		new_event.img_ok = load(itemData["ImgOK"])
		
	if "ImgFail" in itemData and itemData["ImgFail"] != null:
		new_event.img_fail = load(itemData["ImgFail"])
	
	if "EventTextMain" in itemData:
		new_event.event_text_main = itemData["EventTextMain"]
		
	if "EventTextOK" in itemData:
		new_event.event_text_ok = itemData["EventTextOK"]
		
	if "EventTextFail" in itemData:
		new_event.event_text_fail = itemData["EventTextFail"]
	
	return new_event

	
func load_json_file(filePath : String):
	if FileAccess.file_exists(filePath):
		var dataFile = FileAccess.open(filePath, FileAccess.READ)
		var parsedResults = JSON.parse_string(dataFile.get_as_text())
	
		if parsedResults is Dictionary:
			return parsedResults
		else:
			print("Error reading file. Probably JSON-File is corrupted.")
		
	else:
		print("File doesn't exists!")


# Function to schedule an event
func schedule_event(time):
	var path = ALL_EVENTS[_current_event_index]
	current_event = _read_event(path)
	current_event.timestamp = int(time)
	current_event.complete_timestamp = int(time) + 45
	current_event.goal_location = EVENT_LOCATIONS[_current_event_index]
	current_event.department = EVENT_DEPARTMENTS[_current_event_index]
	
	_current_event_index += 1


func schedule_event_after_seconds(seconds):
	var time = Time.get_unix_time_from_system()
	time += seconds
	schedule_event(time)


# Function to complete an event
func complete_event(event):
	current_event = null


# Process function called in every frame
func _process(delta):
	var current_unix_time = Time.get_unix_time_from_system()
	
	if current_event != null and current_event.timestamp <= current_unix_time and current_event.is_processed == false:
		event_system_did_process_event.emit(current_event)
		
		current_event.is_processed = true
