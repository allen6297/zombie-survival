extends Resource
class_name ItemProperties

const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")
const ComponentHost := preload("res://scripts/components/ComponentHost.gd")

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var texture: Texture2D
@export var model: Resource
@export_range(1.0, 999.0, 1.0) var stack_size: int = 1
@export var components: Array[ComponentPropertiesResource] = []


func get_component(id: StringName) -> ComponentPropertiesResource:
	return ComponentHost.get_component(components, id) as ComponentPropertiesResource


func has_component(id: StringName) -> bool:
	return ComponentHost.has_component(components, id)


func get_components_by_type(type: StringName) -> Array[ComponentPropertiesResource]:
	var matching: Array[ComponentPropertiesResource] = []
	for component in ComponentHost.get_components_by_type(components, type):
		matching.append(component)
	return matching
