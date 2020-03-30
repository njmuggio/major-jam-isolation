extends Node2D

var debug: bool = false

const physicsFps = 60 # UPDATE THIS IF PHYSICS RATE GETS UPDATED - CAN'T READ A CONSTANT FROM PROJECT SETTINGS
const gameMinutes = 2
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

onready var sensors = [
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor0,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor1,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor2,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor3,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor4
]

onready var sensorTexes = [
	load("res://textures/sensors/icons_decay.png"),
	load("res://textures/sensors/icons_happi.png"),
	load("res://textures/sensors/icons_heat.png"),
	load("res://textures/sensors/icons_immDes.png"),
	load("res://textures/sensors/icons_pineapple.png"),
	load("res://textures/sensors/icons_radiation.png"),
	load("res://textures/sensors/icons_radio.png"),
	load("res://textures/sensors/icons_spectro.png"),
#	load("res://textures/sensors/icons_ufo1.png"),
	load("res://textures/sensors/icons_ufo2.png")
]

var rollRate = PI * -0.01
var pitchRate = PI * 0.01
var yawRate = PI * 0.01

var rotAccel = 0.60

var pitchMod = 0
var rollMod = 0
var yawMod = 0

var count = 0
var gameActive = false
var gameOver = false

var powerPerSci = 3
var totalSciTransmitted = 0
var totalLifetime = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if debug:
		rollRate = 0
		pitchRate = 0
		yawRate = 0
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not gameActive:
		if gameOver:
			$AudioStreamPlayer.pitch_scale = lerp($AudioStreamPlayer.pitch_scale, 0.5, delta)
		return
	
	if batRes.value <= 0 and rtgRes.value <= 0:
		game_over()
	
	totalLifetime += 1
	$ScienceLbl.text = "Science: " + str(totalSciTransmitted)
	$LifetimeLbl.text = "Lifetime: %d days" % (totalLifetime / 10)
	
	# https://docs.godotengine.org/en/3.2/tutorials/3d/using_transforms.html
	var bearing = ship.transform.basis.z
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(bearing)))
	noiseShader.material.set_shader_param("seed", randf())
	noiseShader.material.set_shader_param("density", max(0.0, range_lerp(angle_to_earth, 30, 180, 0.0, 0.5)))
#	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(angle_to_earth, 0, 180, 1, 10))
	$AudioStreamPlayer.pitch_scale = min(1.0, range_lerp(angle_to_earth, 30, 180, 1.0, 0.8))
	pass


func _physics_process(delta):
	if not gameActive:
		if Input.is_action_just_pressed("ui_accept"):
			start()
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
	for field in tapeRes.fields:
		tapeRes.try_set_value(field, 0)
	
	# Battery setup
	batRes.minimum = 0
	batRes.maximum = maxBatteryPower
	batRes.value = int(maxBatteryPower / 2.0)
	
	# RTG setup
	rtgRes.minimum = 0
	rtgRes.maximum = rtgLifetimeTicks
	rtgRes.value = rtgLifetimeTicks
	
	# Randomize sensor params and copy colors to tape bar
	var colorDict = {}
	for sensor in sensors:
		sensor.reset()
		sensor.sciPerTick = randi() % 13 + 1
		sensor.powerPerTick = randi() % 13 + 1
		colorDict["Sensor" + str(sensor.sensorNumber)] = sensor.sensorColor
	tapeRes.colors = colorDict
	
	$StartLabel.visible = false
	
	var selections = []
	for i in range(sensorTexes.size()):
		selections.append(i)
# warning-ignore:unused_variable
	for i in range(selections.size() - 5):
		selections.remove(randi() % selections.size())
	for i in range(selections.size()):
		var other = randi() % selections.size()
		var t = selections[other]
		selections[other] = selections[i]
		selections[i] = t
	for i in range(selections.size()):
		sensors[i].sensorTexture = sensorTexes[selections[i]]
	
	# Init game
	totalLifetime = 0
	gameOver = false
	gameActive = true
	pass


func game_over():
	$StartLabel.visible = true
	gameActive = false
	gameOver = true
	pass


func try_broadcast(sciAmount, directLink):
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(ship.transform.basis.z)))
	var powerNeeded = 0
	var powerAvailable = batRes.value
	
	# Check power needed to transmit requested amount
	if angle_to_earth > 100:
		return 0
	elif angle_to_earth < 30:
		powerNeeded = powerPerSci * sciAmount
	else:
		powerNeeded = ((4*(angle_to_earth - 30)/70.0) + 1) * powerPerSci * sciAmount
	
	if batRes.reserve(powerNeeded):
		totalSciTransmitted += sciAmount
		return sciAmount
	elif directLink:
		# Should drain the battery
		batRes.reserve(powerAvailable)
		var sciSent = (powerAvailable / powerNeeded) * sciAmount
		print("Direct Link at low power: sent " + str(sciSent) + " instead of " + str(sciAmount))
		totalSciTransmitted += sciSent
		return sciSent
	else:
		return 0
