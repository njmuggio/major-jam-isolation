extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var default_transform = $Spatial.transform


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func ufo_event():
	$UfoCamera.set_current(true)
	$AnimationPlayer.play("Ufo Encounter")

func reset():
	$Camera.set_current(true)
	$Spatial.transform = default_transform
