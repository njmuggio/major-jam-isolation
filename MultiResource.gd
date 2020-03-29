extends Control
class_name MultiResource


export(int) var minimum = 0
export(int) var maximum = 1000
export(Dictionary) var colors = {} setget set_colors

class Info:
	var rect: ColorRect
	var value: int

var fields: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var totalWidth = 0
	for field in fields:
		var val = fields[field].value
		var rect = fields[field].rect
		var width = range_lerp(val, minimum, maximum, 0, $TextureRect.rect_min_size[0])
		rect.rect_size[0] = width
		rect.rect_position[0] = totalWidth
		totalWidth += width
		if val == 99:
			print("")
	pass


func set_colors(dict):
	colors = dict
	fields = {}
	for name in dict:
		var info = Info.new()
#		info.color = dict[name]
		info.rect = ColorRect.new()
		info.rect.color = dict[name]
		info.rect.rect_min_size[0] = 0
		info.rect.rect_min_size[1] = 4
		info.value = 0
		fields[name] = info
		add_child(info.rect)


# Set the value for 'key' to 'val'.
# Do not call this from other classes!
func __set_value(key: String, val: int):
#	if not colors.has(key):
	if not fields.has(key):
		print(str(key) + " has not been registered as a key")
		print_stack()
		return 0
	if val < 0:
		val = 0	
	fields[key].value = val


# Try to update the value associated with 'key' by adding 'amt'.
# Returns true if the total sum is <= maximum and the field's value would not become negative, false otherwise.
func try_change_value(key: String, amt: int):
	var sum = 0
	var val = null
	if fields.has(key) && fields[key].value <= 0 && amt < 0:
		return false
	for field in fields:
		sum += fields[field].value
		if field == key:
			val = fields[field].value
	sum += amt
	if (not val == null) and sum <= maximum:
		__set_value(key, val + amt)
		return true
	return false

# Try to set the value associated with 'key' to 'val'.
# Returns true if the total sum is <= maximum, false otherwise.
func try_set_value(key: String, val: int):
	var sum = 0
	var found = false
	for field in fields:
		if field == key:
			sum += val
			found = true
		else:
			sum += fields[field].value
	if found and sum <= maximum:
		__set_value(key, val)
		return true
	return false
