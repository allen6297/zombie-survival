extends "res://scripts/registry/AbstractRegistry.gd"
class_name BlockEntityRegistry

const BlockEntityPropertiesResource := preload("res://scripts/block_entities/BlockEntityProperties.gd")

@export var block_entities: Array[BlockEntityPropertiesResource] = []


func get_block_entity(id: StringName) -> BlockEntityPropertiesResource:
	return get_entry(id) as BlockEntityPropertiesResource


func has_block_entity(id: StringName) -> bool:
	return has_entry(id)


func add_block_entity(block_entity: BlockEntityPropertiesResource) -> void:
	add_entry(block_entity)


func _get_entries() -> Array:
	return block_entities
