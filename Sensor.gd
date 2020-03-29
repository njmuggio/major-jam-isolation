extends Control

enum DataUsage { storage, broadcast}

# Sensor Configuration
export(int) var sensorNumber = 0
export(Color) var sensorColor = Color.green
# Sensor State
export(bool) var enabled = false
export(DataUsage) var usage = DataUsage.storage
# Sensor Attributes
export(int) var sciPerTick = 1
export(int) var powerPerTick = 1
export(Color) var disabledColor = Color.gray

onready var powerButton = $EnabledButton
onready var storeButton = $StoreButton
onready var broadcastButton = $BroadcastButton
var battery
var storageTape
var mainLevel



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
	battery = get_parent().get_parent().get_node("BatRes")
	storageTape = get_parent().get_parent().get_node("TapeRes")
	mainLevel = get_tree().root.get_node("Node2D")
	SetEnabled(enabled)
	SetUsage(usage)
	$PowerStatus.value = powerPerTick
	$ScienceStatus.value = sciPerTick
	$BroadcastStatus.max_value = sciPerTick
	pass


# Called every physics tick. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if enabled:
		# Request Power
		if battery.reserve(powerPerTick):
			if usage == DataUsage.storage:
				# Power down sensors if insufficient storage available
				if !storageTape.try_change_value("Sensor"+str(sensorNumber), sciPerTick):
					SetEnabled(false)
				
			else:
				var sciToSend = storageTape.get_value("Sensor"+str(sensorNumber))
				var directLink = false
				if sciToSend <= 0:
					directLink = true
					sciToSend = sciPerTick
				elif sciToSend > sciPerTick:
					sciToSend = sciPerTick
				var broadcastAmount = mainLevel.try_broadcast(sciToSend, directLink)
				if !directLink:
					storageTape.try_change_value("Sensor"+str(sensorNumber), -broadcastAmount)
				$BroadcastStatus.value = broadcastAmount
				
		# Power down sensor if insufficient power
		else:
			SetEnabled(false)
	pass

# Sets the Sensors to the Enabled/Disabled state based on newStatus boolean
func SetEnabled(newStatus):
	enabled = newStatus
	if enabled:
		powerButton.modulate = sensorColor
	else:
		powerButton.modulate = disabledColor
	pass

# Sets the Sensors to Store or Broadcast data based on usageType (DataUsage.storage or DataUsage.broadcast)
func SetUsage(usageType):
	match usageType:
		DataUsage.storage:
			usage = DataUsage.storage
			storeButton.modulate = sensorColor
			broadcastButton.modulate = disabledColor
		DataUsage.broadcast:
			usage = DataUsage.broadcast
			broadcastButton.modulate = sensorColor
			storeButton.modulate = disabledColor
		_:
			print(str(usageType) + " is not a valid usage type, only DataUsage.storage and DataUsage.broadcast!")
	pass

func _on_EnabledButton_pressed():
	SetEnabled(!enabled)
	pass
	
func _on_StoreButton_pressed():
	SetUsage(DataUsage.storage)
	pass

func _on_BroadcastButton_pressed():
	SetUsage(DataUsage.broadcast)
	pass
