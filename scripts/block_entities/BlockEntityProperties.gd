extends Resource
class_name BlockEntityProperties

const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")
const ComponentHost := preload("res://scripts/components/ComponentHost.gd")

enum BlockEntityKind {
	GENERIC,
	CONTAINER,
	WORKSTATION,
	SPAWNER,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: BlockEntityKind = BlockEntityKind.GENERIC
@export_range(0.0, 256.0, 1.0) var inventory_size: int = 0
@export var accepts_items := false
@export var emits_signal := false
@export var persists_state := true
@export var components: Array[ComponentPropertiesResource] = []


func has_inventory() -> bool:
	return inventory_size > 0


func get_component(id: StringName) -> ComponentPropertiesResource:
	return ComponentHost.get_component(components, id) as ComponentPropertiesResource


func has_component(id: StringName) -> bool:
	return ComponentHost.has_component(components, id)


func get_components_by_type(type: StringName) -> Array[ComponentPropertiesResource]:
	var matching: Array[ComponentPropertiesResource] = []
	for component in ComponentHost.get_components_by_type(components, type):
		matching.append(component)
	return matching
