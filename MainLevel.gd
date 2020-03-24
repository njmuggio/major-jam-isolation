extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$UiControl.set_size(get_viewport_rect().size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
