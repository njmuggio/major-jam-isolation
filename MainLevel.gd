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

onready var initialTransform = ship.transform
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
	preload("res://textures/sensors/icons_decay.png"),
	preload("res://textures/sensors/icons_happi.png"),
	preload("res://textures/sensors/icons_heat.png"),
	preload("res://textures/sensors/icons_immDes.png"),
	preload("res://textures/sensors/icons_pineapple.png"),
	preload("res://textures/sensors/icons_radiation.png"),
	preload("res://textures/sensors/icons_radio.png"),
	preload("res://textures/sensors/icons_spectro.png"),
#	preload("res://textures/sensors/icons_ufo1.png"),
	preload("res://textures/sensors/icons_ufo2.png")
]

var rollRate = PI * -0.01
var pitchRate = PI * 0.01
var yawRate = PI * 0.01

var rotAccel = 0.60

var pitchMod = 0
var rollMod = 0
var yawMod = 0

var gameOverWorldRate = 1.0

var count = 0
var gameActive = false
var gameOver = false

var powerPerSci = 3
var totalSciTransmitted = 0
var totalLifetime = 0
var change_sensor_mode = false


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if debug:
		rollRate = 0
		pitchRate = 0
		yawRate = 0
	var colorDict = {}
	for sensor in sensors:
		sensor.reset()
		colorDict["Sensor" + str(sensor.sensorNumber)] = sensor.sensorColor
	tapeRes.colors = colorDict
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var bearing = ship.transform.basis.z
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(bearing)))
	noiseShader.material.set_shader_param("seed", randf())
	noiseShader.material.set_shader_param("density", clamp(range_lerp(angle_to_earth, 30, 180, 0.0, 0.5), 0.0, 0.5))
	noiseShader.material.set_shader_param("noise1", rand_range(35, 45))
	noiseShader.material.set_shader_param("noise2", rand_range(10, 20))
	noiseShader.material.set_shader_param("noise3", rand_range(45000, 65000))
	
	if not gameActive:
		if gameOver:
			$AudioStreamPlayer.pitch_scale = gameOverWorldRate#lerp(gameOverWorldRate, 0.5, delta)
		return
	
	if batRes.value <= 0 and rtgRes.value <= 0:
		game_over()
	
	totalLifetime += 1
	$ScienceLbl.text = "Science: " + str(totalSciTransmitted)
	$LifetimeLbl.text = "Lifetime: %d days" % (totalLifetime / 10)
	
	# https://docs.godotengine.org/en/3.2/tutorials/3d/using_transforms.html
	
#	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(angle_to_earth, 0, 180, 1, 10))
	$AudioStreamPlayer.pitch_scale = min(1.0, range_lerp(angle_to_earth, 30, 180, 1.0, 0.8))
	pass


func _physics_process(delta):
	if not gameActive:
		if Input.is_action_just_pressed("ui_accept"):
			start()
		elif gameOver:
			gameOverWorldRate = lerp(gameOverWorldRate, 0.5, delta)
			ship.rotate_x(pitchRate * delta * gameOverWorldRate)
			ship.rotate_y(rollRate * delta * gameOverWorldRate)
			ship.rotate_z(yawRate * delta * gameOverWorldRate)
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
	if event.is_action_pressed("sensor_mode_toggle"):
		change_sensor_mode = true
	if event.is_action_released("sensor_mode_toggle"):
		change_sensor_mode = false
	if event.is_action_pressed("sensor_1"):
		_sensor_input(0)
	if event.is_action_pressed("sensor_2"):
		_sensor_input(1)
	if event.is_action_pressed("sensor_3"):
		_sensor_input(2)
	if event.is_action_pressed("sensor_4"):
		_sensor_input(3)
	if event.is_action_pressed("sensor_5"):
		_sensor_input(4)
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
	
	# Randomize sensor params
	for sensor in sensors:
		sensor.reset()
		sensor.sciPerTick = randi() % 13 + 1
		sensor.powerPerTick = randi() % 13 + 1
	
	$StartLabel.visible = false
	
	var selections = []
	for i in range(sensorTexes.size()):
		selections.append(i)
	for _i in range(selections.size() - 5):
		selections.remove(randi() % selections.size())
	for i in range(selections.size()):
		var other = randi() % selections.size()
		var t = selections[other]
		selections[other] = selections[i]
		selections[i] = t
	for i in range(selections.size()):
		sensors[i].sensorTexture = sensorTexes[selections[i]]
	
	# Random starting velocity
	rollRate = PI * rand_range(-0.02, 0.02)
	pitchRate = PI * rand_range(-0.02, 0.02)
	yawRate = PI * rand_range(-0.02, 0.02)
	ship.transform = initialTransform
	
	# Init game
	totalLifetime = 0
	gameOver = false
	gameActive = true
	pass


func game_over():
	$StartLabel.visible = true
	gameOverWorldRate = 1.0
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
		totalSciTransmitted += sciSent
		return sciSent
	else:
		return 0

func _sensor_input(sensor):
	if sensor < 0 or sensor >= sensors.size():
		print("Invalid Sensor input for sensor: " + str(sensor))
		return
	if change_sensor_mode:
		sensors[sensor].toggle_usage()
	else:
		sensors[sensor].toggle_power()
	pass
