extends Node2D

var debug: bool = true

onready var ship = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite
onready var satCross = $satCrosshair
onready var ray = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Satellite/RayCast
onready var collShape = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial/Area/CollisionShape
onready var box = collShape.get_shape()
onready var satCluster = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Spatial
onready var targetRot = ship.rotation
var rollRate = PI * -0.01
var pitchRate = PI * 0.01
var rotAccel = 0.01
var pitchMod = 0
var rollMod = 0
var count = 0
const targetRoll = -90
const targetPitch = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if debug:
		rollRate = 0
		pitchRate = 0
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	var sliderVal = $UiControl/VBoxContainer/HBoxContainer/GridContainer/HSlider.value
#	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = sliderVal
#	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(abs(rad2deg(Vector3(0, -1, 0).angle_to(ray.cast_to.rotated(Vector3(-1, 0, 0), deg2rad(90))))), 0, 180, 1, 10))
	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = round(range_lerp(abs(rad2deg(targetRot.angle_to(ship.rotation))), 0, 180, 1, 10))
#	var roll = ship.rotation_degrees[0]
#	var pitch = ship.rotation_degrees[2]
#	var offX = range_lerp(targetPitch - pitch, -180, 180, 9, 93)
#	var offY = range_lerp(targetRoll - roll, -180, 180, 207, 291)
#	satCross.global_position[0] = offX
#	satCross.global_position[1] = offY
	satCross.global_position[0] = range_lerp(ray.get_collision_point()[0], satCluster.translation[0] - box.extents[0], satCluster.translation[0] + box.extents[0], 9, 93)
	satCross.global_position[1] = range_lerp(ray.get_collision_point()[2], satCluster.translation[2] - box.extents[2], satCluster.translation[2] + box.extents[2], 207, 291)
	count += 1
	if count % 10 == 0:
		print(str(ship.rotation) + ' ' + str(targetRot))
		print(abs(rad2deg(targetRot.angle_to(ship.rotation))))
#		print(ray.cast_to.rotated(Vector3(-1, 0, 0), deg2rad(90)))
#	print(int(pitch) % 180)
#	trans[2][0] = offX
#	satCross.transform = trans
	pass


func _physics_process(delta):
	pitchRate += pitchMod * rotAccel
	rollRate += rollMod * rotAccel
	ship.rotate_x(rollRate * delta)
	ship.rotate_z(-pitchRate * delta)
#	var curRot = ship.rotation
#	ship.rotation = Vector3(curRot[0] + rollRate * delta, deg2rad(135), curRot[2] - pitchRate * delta)
#	ship.rotation = Vector3(curRot[0] + rollRate * delta, curRot[1] - pitchRate * delta, 0)
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
