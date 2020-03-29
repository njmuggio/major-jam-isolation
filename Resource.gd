extends Control
class_name SimpleResource


export(int) var minimum = 0 setget set_minimum
export(int) var maximum = 1000 setget set_maximum
export(int, 0, 360) var minimum_hue = 0
export(int, 0, 360) var maximum_hue = 120
export(int) var value = 500

onready var bar = $ProgBar

# Called when the node enters the scene tree for the first time.
func _ready():
	bar.min_value = minimum
	bar.max_value = maximum
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	bar.value = value
	var hue = range_lerp(value, minimum, maximum, minimum_hue, maximum_hue)
	bar.tint_progress = Color.from_hsv(hue / 360, 1, 1)
	pass


# Add 'amt' to the value. This is executed immediately, instead of being added to the request queue.
# Returns the new value.
func apply(amt):
	var newVal = value + amt
	if newVal >= minimum and newVal <= maximum:
		value = newVal
	return value


# Try to reserve 'amt' of the resource. If available, this much is deducted from the count.
# Returns true if 'amt' could be reserved, false otherwise
func reserve(amt):
	if value >= amt:
		value -= amt
		return true
	return false


# Attempt to reserve 'amt'. If there is not enough of the resource, return the amount available and value to 0.
func request(amt):
	if value > amt:
		value -= amt
		return amt
	else:
		amt = value
		value = 0
		return amt


func set_minimum(val):
	bar.min_value = val
	minimum = val


func set_maximum(val):
	bar.max_value = val
	maximum = val
