extends Resource
class_name EntityProperties

const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")
const ComponentHost := preload("res://scripts/components/ComponentHost.gd")

enum EntityKind {
	NEUTRAL,
	PLAYER,
	NPC,
	HOSTILE,
	PROJECTILE,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: EntityKind = EntityKind.NEUTRAL
@export var texture: Texture2D
@export var model: Resource
@export_range(0.0, 10000.0, 0.1) var max_health: float = 20.0
@export_range(0.0, 1000.0, 0.1) var move_speed: float = 5.0
@export_range(0.0, 1000.0, 0.1) var interaction_range: float = 2.0
@export var can_take_damage := true
@export var components: Array[ComponentPropertiesResource] = []


func is_alive_health(value: float) -> bool:
	return value > 0.0


func get_component(id: StringName) -> ComponentPropertiesResource:
	return ComponentHost.get_component(components, id) as ComponentPropertiesResource


func has_component(id: StringName) -> bool:
	return ComponentHost.has_component(components, id)


func get_components_by_type(type: StringName) -> Array[ComponentPropertiesResource]:
	var matching: Array[ComponentPropertiesResource] = []
	for component in ComponentHost.get_components_by_type(components, type):
		matching.append(component)
	return matching
