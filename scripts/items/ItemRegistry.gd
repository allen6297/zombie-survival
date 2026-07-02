extends "res://scripts/registry/AbstractRegistry.gd"
class_name ItemRegistry

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")

@export var items: Array[ItemPropertiesResource] = []


func get_item(id: StringName) -> ItemPropertiesResource:
	return get_entry(id) as ItemPropertiesResource


func has_item(id: StringName) -> bool:
	return has_entry(id)


func add_item(item: ItemPropertiesResource) -> void:
	add_entry(item)


func _get_entries() -> Array:
	return items
