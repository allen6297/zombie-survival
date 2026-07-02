extends "res://scripts/registry/AbstractRegistry.gd"
class_name EntityRegistry

const EntityPropertiesResource := preload("res://scripts/entities/EntityProperties.gd")

@export var entities: Array[EntityPropertiesResource] = []


func get_entity(id: StringName) -> EntityPropertiesResource:
	return get_entry(id) as EntityPropertiesResource


func has_entity(id: StringName) -> bool:
	return has_entry(id)


func add_entity(entity: EntityPropertiesResource) -> void:
	add_entry(entity)


func _get_entries() -> Array:
	return entities
