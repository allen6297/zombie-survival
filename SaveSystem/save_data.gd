extends RefCounted

const SAVE_DATA: Array[StringName] = [&"player_location", &"abilities"]

var player_location: Vector2 = Vector2.ZERO
# Kept untyped so values round-tripped through str_to_var() (which produces an
# untyped Dictionary) can be assigned back without a type-mismatch error.
var abilities: Dictionary = {}


## Returns the [SaveData].
func get_data() -> Dictionary:
	var data: Dictionary[StringName, Variant] = {}

	for property in SAVE_DATA:
		data[property] = get(property)

	return data


## Add every property to the [SaveData] object.
func set_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	for property in SAVE_DATA:
		if data.has(property):
			set(property, data[property])
