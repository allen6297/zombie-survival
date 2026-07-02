extends Resource
class_name ComponentProperties

@export var id: StringName
@export var type: StringName
@export var data: Dictionary = {}


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return data.get(String(key), default_value)


func has_value(key: StringName) -> bool:
	return data.has(String(key))
