extends Node2D

const physicsFps = 60 # UPDATE THIS IF PHYSICS RATE GETS UPDATED - CAN'T READ A CONSTANT FROM PROJECT SETTINGS
const gameMinutes = 1
const rtgLifetimeTicks = gameMinutes * 60 * physicsFps
const maxBatteryPower = 10000 * gameMinutes
const tapeSize = 1000 * gameMinutes

onready var ship = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite
onready var gimbal = $UiControl/VBoxContainer/HBoxContainer/ViewportContainer/Viewport/Spatial/Gimbal
onready var satCluster = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial

onready var noiseShader = $UiControl/VBoxContainer/ViewportContainer/ColorRect

onready var initialTransform = ship.transform
onready var targetBearing = ship.transform.basis.z
onready var tapeRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/TapeRes
onready var batRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/BatRes
onready var rtgRes = $UiControl/VBoxContainer/HBoxContainer/VBoxContainer/RtgRes
onready var gimbalTransform = gimbal.transform
onready var tutRect = $Tut/Text.rect_position

onready var sensors = [
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor0,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor1,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor2,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor3,
	$UiControl/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Sensor4
]

onready var overlays = [
	preload("res://textures/tutorial/tut_0010s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0009s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0008s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0007s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0006s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0005s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0004s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0003s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0002s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0001s_0001_TutBackground.png"),
	preload("res://textures/tutorial/tut_0000s_0001_TutBackground.png")
]

onready var texts = [
	"You are a satellite operator running Bunsen-19\n\nYour satellite's mission is coming to an end\n\nKeep your satellite running as long as possible,\nand make the most of the data you can downlink",
	"This is your generator\n\nYou will generate power until this bar runs out",
	"This is your battery\n\nGenerated power will be stored here\n\nAll flight systems deplete battery power",
	"This is your tape drive\n\nScience not immediately downlinked will be stored here",
	"This is your satellite\n\nAny rotation will be reflected here",
	"This is your gimbal\n\nWhen the red circle is centered, your antenna is pointed at Earth\n\nScience takes less power to downlink if Earth is in focus",
	"These are your sensors\n\nThese are used to collect and transmit science",
	"These are the sensor power buttons\n\nSensors consume extra power when on\n\nWhen a sensor is on, it is always storing to the tape\nor downlinking data",
	"These are the storage buttons\n\nWhen a sensor is powered on and the storage button is active,\nscience will be stored to the tape",
	"These are the broadcast buttons\n\nWhen a sensor is active and broadcasting is enabled,\nscience will be downlinked\n\nIf science for this sensor is on tape, that will be downlinked first\n\nOnly downlinked science earns science points",
	"These meters indicate sensor stats\n\nP: Power required to run the sensor\n\nS: Science the sensor produces\n\nB: Broadcast efficiency"
]

var currentTutorialFrame = 0
var batCharge = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	var colorDict = {}
	for sensor in sensors:
		sensor.reset()
		colorDict["Sensor" + str(sensor.sensorNumber)] = sensor.sensorColor
	tapeRes.colors = colorDict
	sensors[1].SetUsage(Sensor.DataUsage.broadcast)
	sensors[2].SetUsage(Sensor.DataUsage.broadcast)
	rtgRes.maximum = rtgLifetimeTicks
	rtgRes.value = rtgRes.maximum
	tapeRes.try_set_value("Sensor0", 100)
	tapeRes.try_set_value("Sensor1", 200)
	tapeRes.try_set_value("Sensor2", 250)
	tapeRes.try_set_value("Sensor3", 50)
	tapeRes.try_set_value("Sensor4", 100)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var bearing = ship.transform.basis.z
	var angle_to_earth = abs(rad2deg(targetBearing.angle_to(bearing)))
	noiseShader.material.set_shader_param("seed", randf())
	noiseShader.material.set_shader_param("density", max(0.0, range_lerp(angle_to_earth, 30, 180, 0.0, 0.5)))
	noiseShader.material.set_shader_param("noise1", rand_range(35, 45))
	noiseShader.material.set_shader_param("noise2", rand_range(10, 20))
	noiseShader.material.set_shader_param("noise3", rand_range(45000, 65000))
	
	if currentTutorialFrame >= texts.size():
		start_game()
		return
	
	match currentTutorialFrame:
		4:
			$Tut/Text.rect_position = Vector2(0, 150)
		_:
			$Tut/Text.rect_position = tutRect
	
	$Overlay.texture = overlays[currentTutorialFrame]
	$Tut/Text.text = texts[currentTutorialFrame]
	
	pass


func _physics_process(delta):
	match currentTutorialFrame:
		1:
			rtgRes.value -= 1
			if rtgRes.value == 0:
				rtgRes.value = rtgLifetimeTicks
		2:
			batRes.value += batCharge
			if batRes.value >= batRes.maximum:
				batCharge = -1
			elif batRes.value <= batRes.minimum:
				batCharge = 1
		4:
			ship.rotate_y(PI * 0.02)
		5:
			ship.rotate_x(PI * 0.01)
			ship.rotate_y(PI * 0.02)
			ship.rotate_z(PI * -0.01)
		6:
			ship.transform = initialTransform
		_:
			pass
	
	gimbal.transform = ship.transform * gimbalTransform
	pass


func _input(event):
	if event.is_action_pressed("ui_accept"):
		currentTutorialFrame += 1
	if event.is_action_pressed("escape"):
		start_game()
	pass


func start_game():
	get_tree().change_scene("res://MainLevel.tscn")
