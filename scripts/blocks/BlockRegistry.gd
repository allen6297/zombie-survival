extends "res://scripts/registry/AbstractRegistry.gd"
class_name BlockRegistry

const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")

@export var blocks: Array[BlockPropertiesResource] = []


func get_block(id: StringName) -> BlockPropertiesResource:
	return get_entry(id) as BlockPropertiesResource


func has_block(id: StringName) -> bool:
	return has_entry(id)


func add_block(block: BlockPropertiesResource) -> void:
	add_entry(block)


func _get_entries() -> Array:
	return blocks
