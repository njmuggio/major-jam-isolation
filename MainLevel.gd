extends Node2D

var debug: bool = true

const physicsFps = 60 # UPDATE THIS IF PHYSICS RATE GETS UPDATED - CAN'T READ A CONSTANT FROM PROJECT SETTINGS
const gameMinutes = 1
#const rtgLifetimeMsec = 60 * 1000 * gameMinutes
const rtgLifetimeTicks = gameMinutes * 60 * physicsFps
const powerPerTick = 5
const maxBatteryPower = 10000 * gameMinutes
const idlePowerUse = 1
const reactionWheelPowerUse = 10
const tapeSize = 100 * gameMinutes

onready var ship = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite
onready var gimbal = $UiControl/VBoxContainer/HBoxContainer/ViewportContainer/Viewport/Spatial/Gimbal
onready var satCluster = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial

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
var tickCount = 0
var gameActive = true
var batteryPower = 0


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
#	var sliderVal = $UiControl/VBoxContainer/HBoxContainer/GridContainer/HSlider.value
#	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = sliderVal
#	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(abs(rad2deg(Vector3(0, -1, 0).angle_to(ray.cast_to.rotated(Vector3(-1, 0, 0), deg2rad(90))))), 0, 180, 1, 10))
	
	if not gameActive:
		$AudioStreamPlayer.pitch_scale = lerp($AudioStreamPlayer.pitch_scale, 0.5, delta)
		return
	
#	var msecRemaining = rtgLifetimeMsec - (OS.get_ticks_msec() - startTime)
	rtgRes.value = rtgLifetimeTicks - tickCount
	batRes.value = batteryPower
	
	if batteryPower <= 0 and tickCount >= rtgLifetimeTicks:
		game_over()
	
	# https://docs.godotengine.org/en/3.2/tutorials/3d/using_transforms.html
	var bearing = ship.transform.basis.z
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(bearing)))
	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(angle_to_earth, 0, 180, 1, 10))
	$AudioStreamPlayer.pitch_scale = min(1.0, range_lerp(angle_to_earth, 30, 180, 1.0, 0.8))
	
	count += 1
#	if count % 10 == 0:
#		print(str(bearing) + ' ' + str(targetBearing))
#		print(angle_to_earth)
	pass


func _physics_process(delta):
	if not gameActive:
		return
	
	tickCount += 1
	
	var powerGen = powerPerTick as float
#	var msecRemaining = rtgLifetimeMsec - (OS.get_ticks_msec() - startTime)
	if tickCount >= rtgLifetimeTicks:
		powerGen = 0
	var powerUsed = (abs(pitchMod) + abs(rollMod) + abs(yawMod)) * reactionWheelPowerUse + idlePowerUse
	var powerFraction = 1.0
	if powerUsed > 0:
		powerFraction = clamp((batteryPower + powerGen) / (powerUsed), 0.0, 1.0)
	batteryPower = clamp(batteryPower + (powerGen - powerUsed), 0, maxBatteryPower)
		
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
	tapeRes.value = 0
	
	# Battery setup
	batRes.minimum = 0
	batRes.maximum = maxBatteryPower
	batRes.value = 0
	
	# RTG setup
	rtgRes.minimum = 0
	rtgRes.maximum = rtgLifetimeTicks
	rtgRes.value = rtgLifetimeTicks
	
	# Init game
	tickCount = 0
	gameActive = true
	pass


func game_over():
	print("Game should end now")
	gameActive = false
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
