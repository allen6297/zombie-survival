extends RefCounted
class_name ComponentProcessor

const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")
const InteractionContextResource := preload("res://scripts/components/InteractionContext.gd")

var handled_ids: Array[StringName] = []
var handled_types: Array[StringName] = []


func can_process(component: ComponentPropertiesResource) -> bool:
	if component == null:
		return false
	return handled_ids.has(component.id) or handled_types.has(component.type)


func process(component: ComponentPropertiesResource, context: InteractionContextResource) -> bool:
	return false
