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
	pass


# Called every physics tick. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if enabled:
		# Request Power
		if battery.reserve(powerPerTick):
			if usage == DataUsage.storage:
				# Power down sensors if insufficient storage available
				if !storageTape.try_change_value("Sensor"+str(sensorNumber), sciPerTick):
					SetEnabled(false)
				
			else:
				# SciAmount? += sciPerTick
				# 'Broadcast' from stored data first
				# query storage, do I have > 0
				# use that amount or sciPerTick, whichever is smaller
				# if storage is empty, then also send sciPerTick
				# tell main to TRY to broadcast that amount
				# main checks power needed to transmit that amount of sci (based on angle)
				# have base Powerpersci (if within 30 degrees), scale up to 10x until 100 degrees, after that always deny transmission
				# main will need to know storage/broadcast
				# storage will transmit all data at variable power
				# direct link will transmit up to sciPerTick based on available power
				# main reports 'amount sci' sent and update blue bar
				
				var amount_to_send = int(mainLevel.signal_strength * sciPerTick)
				if storageTape.fields["Sensor"+str(sensorNumber)].value >= amount_to_send:
					storageTape.try_change_value("Sensor"+str(sensorNumber), -amount_to_send)
				var amount_sent = mainLevel.transmit_broadcast(amount_to_send)
				
				
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
