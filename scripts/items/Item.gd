extends Node
class_name Item

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")
const ItemStackResource := preload("res://scripts/items/ItemStack.gd")
const ComponentProcessorRegistryResource := preload("res://scripts/components/ComponentProcessorRegistry.gd")
const InteractionContextResource := preload("res://scripts/components/InteractionContext.gd")

@export var properties: ItemPropertiesResource


func use(context: InteractionContextResource = null, registry: ComponentProcessorRegistryResource = null) -> bool:
	var active_properties = properties
	if context != null and context.item_stack != null:
		active_properties = context.item_stack.item
	if active_properties == null:
		return false

	if context == null:
		context = InteractionContextResource.new()
	if registry == null:
		registry = ComponentProcessorRegistryResource.create_default()

	context.source = self
	context.item = active_properties
	return registry.process_components(active_properties.components, context)


func use_stack(stack: ItemStackResource, context: InteractionContextResource = null, registry: ComponentProcessorRegistryResource = null) -> bool:
	if stack == null or stack.is_empty():
		return false

	if context == null:
		context = InteractionContextResource.new()
	context.item_stack = stack
	return use(context, registry)
