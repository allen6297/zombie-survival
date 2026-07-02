extends RefCounted
class_name ComponentProcessorRegistry

const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")
const ComponentProcessorResource := preload("res://scripts/components/ComponentProcessor.gd")
const InteractionContextResource := preload("res://scripts/components/InteractionContext.gd")
const DamageComponentProcessor := preload("res://scripts/components/processors/DamageComponentProcessor.gd")
const PlaceableComponentProcessor := preload("res://scripts/components/processors/PlaceableComponentProcessor.gd")

var processors: Array[ComponentProcessorResource] = []


static func create_default():
	var registry := ComponentProcessorRegistry.new()
	registry.register_processor(DamageComponentProcessor.new())
	registry.register_processor(PlaceableComponentProcessor.new())
	return registry


func register_processor(processor: ComponentProcessorResource) -> void:
	if processor == null or processors.has(processor):
		return
	processors.append(processor)


func get_processor(component: ComponentPropertiesResource) -> ComponentProcessorResource:
	for processor in processors:
		if processor.can_process(component):
			return processor
	return null


func process_component(component: ComponentPropertiesResource, context: InteractionContextResource) -> bool:
	var processor := get_processor(component)
	if processor == null:
		return false
	return processor.process(component, context)


func process_components(components: Array, context: InteractionContextResource) -> bool:
	var handled := false
	for component in components:
		if process_component(component, context):
			handled = true
	return handled
