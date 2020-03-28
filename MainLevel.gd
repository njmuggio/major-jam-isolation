extends Node2D

var debug: bool = true

const gameMinutes = 1
const rtgLifetimeMsec = 60 * 1000 * gameMinutes
const powerPerTick = 5
const maxBatteryPower = 10000 * gameMinutes
const idlePowerUse = 1
const reactionWheelPowerUse = 10

onready var ship = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite
onready var satCross = $satCrosshair
onready var ray = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite/RayCast
onready var collShape = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Area/CollisionShape
onready var box = collShape.get_shape()
onready var satCluster = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial
onready var targetBearing = ship.transform.basis.z
onready var tapeBar = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/TapeBar
onready var batBar = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/BatBar
#onready var rtgBar = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/RtgBar
onready var rtgRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/RtgRes
var rollRate = PI * -0.01
var pitchRate = PI * 0.01
var rotAccel = 0.60
var pitchMod = 0
var rollMod = 0
var count = 0
var startTime: int = 0
var gameActive = true
var batteryPower = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	if debug:
		rollRate = 0
		pitchRate = 0
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
	
	var msecRemaining = rtgLifetimeMsec - (OS.get_ticks_msec() - startTime)
	rtgRes.value = msecRemaining
#	var hue = range_lerp(msecRemaining, 0, rtgLifetimeMsec, 0, 120)
#	rtgBar.value = msecRemaining
#	rtgBar.tint_progress = Color.from_hsv(hue / 360, 1, 1)
	
	var hue = range_lerp(batteryPower, 0, maxBatteryPower, 0, 120)
	batBar.value = batteryPower
	batBar.tint_progress = Color.from_hsv(hue / 360, 1, 1)
	
	if batteryPower <= 0 and msecRemaining <= 0:
		game_over()
	
	# https://docs.godotengine.org/en/3.2/tutorials/3d/using_transforms.html
	var bearing = ship.transform.basis.z
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(bearing)))
	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(angle_to_earth, 0, 180, 1, 10))
	$AudioStreamPlayer.pitch_scale = min(1.0, range_lerp(angle_to_earth, 30, 180, 1.0, 0.8))
	
	satCross.global_position[0] = range_lerp(ray.get_collision_point()[0], satCluster.translation[0] - box.extents[0], satCluster.translation[0] + box.extents[0], 9, 93)
	satCross.global_position[1] = range_lerp(ray.get_collision_point()[2], satCluster.translation[2] - box.extents[2], satCluster.translation[2] + box.extents[2], 207, 291)
	pass


func _physics_process(delta):
	if not gameActive:
		return
	
	var powerGen = powerPerTick as float
	var msecRemaining = rtgLifetimeMsec - (OS.get_ticks_msec() - startTime)
	if msecRemaining <= 0:
		powerGen = 0
	var powerUsed = (abs(pitchMod) + abs(rollMod)) * reactionWheelPowerUse + idlePowerUse
	var powerFraction = 1.0
	if powerUsed > 0:
		powerFraction = clamp((batteryPower + powerGen) / (powerUsed), 0.0, 1.0)
	batteryPower = clamp(batteryPower + (powerGen - powerUsed), 0, maxBatteryPower)
	
	count += 1
#	if count % 5 == 0:
	if powerFraction < 1:
		print(str(powerUsed) + '\t' + str(batteryPower) + '\t' + str(powerGen) + '\t' + str(powerFraction))
	
	pitchRate += pitchMod * rotAccel * delta * powerFraction
	rollRate += rollMod * rotAccel * delta * powerFraction
	ship.rotate_object_local(Vector3(0, 1, 0), rollRate * delta)
	ship.rotate_object_local(Vector3(1, 0, 0), pitchRate * delta)
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
	if event.is_action_released("pitch_neg"):
		pitchMod += 1
	if event.is_action_released("pitch_pos"):
		pitchMod -= 1
	if event.is_action_released("roll_pos"):
		rollMod -= 1
	if event.is_action_released("roll_neg"):
		rollMod += 1
	pass


func start():
	batBar.max_value = maxBatteryPower
#	rtgBar.max_value = rtgLifetimeMsec
	rtgRes.minimum = 0
	rtgRes.maximum = rtgLifetimeMsec
	startTime = OS.get_ticks_msec()
	gameActive = true
	pass


func game_over():
	print("Game should end now")
	gameActive = false
	pass
