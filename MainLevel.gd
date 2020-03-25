extends Node2D

onready var ship = $UiControl/VBoxContainer/ViewportContainer/Viewport/Spatial/Satellite

# Called when the node enters the scene tree for the first time.
func _ready():
#	$UiControl.set_size(get_viewport_rect().size)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var sliderVal = $UiControl/VBoxContainer/HBoxContainer/GridContainer/HSlider.value
	$UiControl/VBoxContainer/ViewportContainer.stretch_shrink = sliderVal
	pass


func _physics_process(delta):
	pass
