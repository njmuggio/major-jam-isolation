extends Control

enum DataUsage { storage, broadcast}

# Sensor Configuration
export(int) var sensorNumber = 0
export(Color) var sensorColor = Color.green
# Sensor State
export(bool) var enabled = false
export(DataUsage) var usage = DataUsage.storage
# Sensor Attributes
export(float) var sciPerTick = 1.0
export(float) var powerPerTick = 1.0

onready var powerButton = $EnabledButton
onready var storeButton = $StoreButton
onready var broadcastButton = $BroadcastButton

var disabledColor = Color.gray

# Broadcast sends data from storage first, sends live data once storage
#
# Power/tick required
# 'Science'/tick - Same for broadcast or store
# Keep track of Science broadcast per sensor
#
# Call request power function -> power function returns whether or not sufficient power is available
# Call request store function -> store function returns how much it was able to store
#
# Turn off sensors that don't receive full power


# Called when the node enters the scene tree for the first time.
func _ready():
	SetEnabled(enabled)
	SetUsage(usage)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	if enabled:
		# Request Power
#		if usage == DataUsage.broadcast:
			# SciAmount? += sciPerTick
#		else:
			# Request Storage?
	pass

# Sets the Sensors to the Enabled/Disabled state based on newStatus boolean
func SetEnabled(newStatus):
	enabled = newStatus
	if enabled:
		powerButton.modulate = sensorColor
		match usage:
			DataUsage.storage:
				storeButton.modulate = sensorColor
			DataUsage.broadcast:
				broadcastButton.modulate = sensorColor
			_:
				print(str(usage) + " is not a valid usage, only DataUsage.storage and DataUsage.broadcast!")
		print("Sensor " + str(sensorNumber) + " Enabled!")
	else:
		powerButton.modulate = disabledColor
		storeButton.modulate = disabledColor
		broadcastButton.modulate = disabledColor
		print("Sensor " + str(sensorNumber) + " Disabled!")
	pass

# Sets the Sensors to Store or Broadcast data based on usageType (DataUsage.storage or DataUsage.broadcast)
func SetUsage(usageType):
	match usageType:
		DataUsage.storage:
			usage = DataUsage.storage
			if enabled:
				storeButton.modulate = sensorColor
			else:
				storeButton.modulate = disabledColor
			broadcastButton.modulate = disabledColor
			print("Sensor " + str(sensorNumber) + " set to store data!")
		DataUsage.broadcast:
			usage = DataUsage.broadcast
			if enabled:
				broadcastButton.modulate = sensorColor
			else:
				broadcastButton.modulate = disabledColor
			storeButton.modulate = disabledColor
			print("Sensor " + str(sensorNumber) + " set to broadcast data!")
		_:
			print(str(usageType) + " is not a valid usage type, only DataUsage.storage and DataUsage.broadcast!")
	pass

func _on_EnabledButton_pressed():
	if enabled:
		SetEnabled(false)
	else:
		SetEnabled(true)
	pass
	
func _on_StoreButton_pressed():
	SetUsage(DataUsage.storage)
	pass

func _on_BroadcastButton_pressed():
	SetUsage(DataUsage.broadcast)
	pass
