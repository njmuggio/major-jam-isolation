extends Node2D

var debug: bool = false

const physicsFps = 60 # UPDATE THIS IF PHYSICS RATE GETS UPDATED - CAN'T READ A CONSTANT FROM PROJECT SETTINGS
const gameMinutes = 1
#const rtgLifetimeMsec = 60 * 1000 * gameMinutes
const rtgLifetimeTicks = gameMinutes * 60 * physicsFps
const powerPerTick = 5
const maxBatteryPower = 10000 * gameMinutes
const idlePowerUse = 1
const reactionWheelPowerUse = 10
const tapeSize = 1000 * gameMinutes

onready var ship = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite
onready var gimbal = $UiControl/VBoxContainer/HBoxContainer/ViewportContainer/Viewport/Spatial/Gimbal
onready var satCluster = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial

onready var noiseShader = $UiControl/VBoxContainer/ViewportContainer/ColorRect

onready var targetBearing = ship.transform.basis.z
#onready var tapeBar = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/TapeBar
onready var tapeRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/TapeRes
#onready var batBar = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/BatBar
onready var batRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/BatRes
#onready var rtgBar = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/RtgBar
onready var rtgRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/RtgRes
onready var gimbalTransform = gimbal.transform

var rollRate = PI * -0.01
var pitchRate = PI * 0.01
var yawRate = PI * 0.01

var rotAccel = 0.60

var pitchMod = 0
var rollMod = 0
var yawMod = 0

var count = 0
var gameActive = true

var totalSciTransmitted = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	if debug:
		rollRate = 0
		pitchRate = 0
		yawRate = 0
	start()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not gameActive:
		$AudioStreamPlayer.pitch_scale = lerp($AudioStreamPlayer.pitch_scale, 0.5, delta)
		return
	
	if batRes.value <= 0 and rtgRes.value <= 0:
		game_over()
	
	
	
	# https://docs.godotengine.org/en/3.2/tutorials/3d/using_transforms.html
	var bearing = ship.transform.basis.z
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(bearing)))
	noiseShader.material.set_shader_param("seed", randf())
	noiseShader.material.set_shader_param("density", max(0.0, range_lerp(angle_to_earth, 30, 180, 0.0, 0.5)))
	#$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(angle_to_earth, 0, 180, 1, 10))
	$AudioStreamPlayer.pitch_scale = min(1.0, range_lerp(angle_to_earth, 30, 180, 1.0, 0.8))
	pass


func _physics_process(delta):
	if not gameActive:
		return
	
	if rtgRes.value > 0: # As long as RTG is alive, add power to battery
		batRes.apply(powerPerTick)
	batRes.apply(-idlePowerUse)
	
	# Figure out power requested for rotation
	var powerNeeded = (abs(pitchMod) + abs(rollMod) + abs(yawMod)) * reactionWheelPowerUse
	var powerFraction = 0
	if powerNeeded != 0:
		# Get as much power as we can
		var powerAvailable = batRes.request(powerNeeded)
		powerFraction = powerAvailable / powerNeeded
	
	# Reduce RTG lifetime by one tick
	rtgRes.apply(-1)
	
	pitchRate += pitchMod * rotAccel * delta * powerFraction
	rollRate += rollMod * rotAccel * delta * powerFraction
	yawRate += yawMod * rotAccel * delta * powerFraction
	
	ship.rotate_x(pitchRate * delta)
	ship.rotate_y(rollRate * delta)
	ship.rotate_z(yawRate * delta)
	
	gimbal.transform = ship.transform * gimbalTransform
	pass


func _input(event):
	if event.is_action_pressed("pitch_neg"):
		pitchMod -= 1
	if event.is_action_pressed("pitch_pos"):
		pitchMod += 1
	if event.is_action_pressed("roll_pos"):
		rollMod += 1
	if event.is_action_pressed("roll_neg"):
		rollMod -= 1
	if event.is_action_pressed("yaw_pos"):
		yawMod += 1
	if event.is_action_pressed("yaw_neg"):
		yawMod -= 1
	
	if event.is_action_released("pitch_neg"):
		pitchMod += 1
	if event.is_action_released("pitch_pos"):
		pitchMod -= 1
	if event.is_action_released("roll_pos"):
		rollMod -= 1
	if event.is_action_released("roll_neg"):
		rollMod += 1
	if event.is_action_released("yaw_pos"):
		yawMod -= 1
	if event.is_action_released("yaw_neg"):
		yawMod += 1
	pass


func start():
	# Tape setup
	tapeRes.minimum = 0
	tapeRes.maximum = tapeSize
	
	# Battery setup
	batRes.minimum = 0
	batRes.maximum = maxBatteryPower
	batRes.value = maxBatteryPower / 2
	
	# RTG setup
	rtgRes.minimum = 0
	rtgRes.maximum = rtgLifetimeTicks
	rtgRes.value = rtgLifetimeTicks
	
	# Init game
	gameActive = true
	pass


func game_over():
	print("Game should end now")
	gameActive = false
	pass
	
func signal_strength():
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(ship.transform.basis.z)))
	if angle_to_earth > 100:
		return 0
	else:
		return 1.0 - (angle_to_earth / 100.0)
	
func transmit_broadcast(sciAmount):
	totalSciTransmitted += sciAmount
	print("Broadcasting " + str(sciAmount) + " units of SCIENCE!")
	pass
# Per Sensor
# State
# On/Off
# Store/Broadcast
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
