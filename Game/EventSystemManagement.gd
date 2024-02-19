# Event System with Date and Time

class EventReader:
	var name: String
	var event_date: Dictionary  # Dictionary to store date components
	var event_time: Dictionary  # Dictionary to store time components

	func _init(name, event_date, event_time):
		self.name = name
		self.event_date = event_date
		self.event_time = event_time

# Main Event System
class EventSystem:
	var events: Array = []

	# Function to show an event
	func show_event(event):
		print("Showing Event:", event.name)

	# Function to schedule an event
	func schedule_event(event, date, time):
		event.event_date = date
		event.event_time = time
		events.append(event)
		#events.sort_custom(self, "_compare_events")

	# Function to complete an event
	func complete_event(event):
		events.erase(events.find(event))

	# Function to compare events based on date and time
	func _compare_events(a, b):
		var a_unix_time = _get_unix_time(a.event_date, a.event_time)
		var b_unix_time = _get_unix_time(b.event_date, b.event_time)
		return a_unix_time - b_unix_time

	# Function to convert date and time components to Unix timestamp
	func _get_unix_time(date, time):
		return date["year"] * 31536000 + date["month"] * 2592000 + date["day"] * 86400 + time["hour"] * 3600 + time["minute"] * 60 + time["second"]

	# Process function called in every frame
	func _process(delta):
		var current_unix_time = _get_unix_time({
			"year": 2024,  # Replace with the current year
			"month": 2,     # Replace with the current month
			"day": 18       # Replace with the current day
		}, {
			"hour": 12,     # Replace with the current hour
			"minute": 0,    # Replace with the current minute
			"second": 0     # Replace with the current second
		})
		
		for event in events:
			var event_unix_time = _get_unix_time(event.event_date, event.event_time)
			if event_unix_time <= current_unix_time:
				show_event(event)
				complete_event(event)
