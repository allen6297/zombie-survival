extends StaticBody3D
class_name Block

const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")
const ComponentProcessorRegistryResource := preload("res://scripts/components/ComponentProcessorRegistry.gd")
const InteractionContextResource := preload("res://scripts/components/InteractionContext.gd")

@export var properties: BlockPropertiesResource:
	set(value):
		properties = value
		_apply_properties()

# Runtime-only: reset to properties.max_health in _apply_properties().
var current_health: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_apply_properties()


func interact(context: InteractionContextResource = null, registry: ComponentProcessorRegistryResource = null) -> bool:
	if properties == null:
		return false

	if context == null:
		context = InteractionContextResource.new()
	if registry == null:
		registry = ComponentProcessorRegistryResource.create_default()

	context.source = self
	context.block = properties
	return registry.process_components(properties.components, context)


func damage_from(context: InteractionContextResource, registry: ComponentProcessorRegistryResource = null) -> bool:
	if context == null:
		return false

	context.target = self
	if context.item_stack != null and context.item_stack.item != null:
		return registry.process_components(context.item_stack.item.components, context) if registry != null else ComponentProcessorRegistryResource.create_default().process_components(context.item_stack.item.components, context)
	if context.item != null:
		return registry.process_components(context.item.components, context) if registry != null else ComponentProcessorRegistryResource.create_default().process_components(context.item.components, context)
	return false


func damage(amount: float) -> bool:
	if properties == null or not properties.can_break or amount <= 0.0:
		return false

	current_health -= amount
	if current_health <= 0.0:
		break_block()
		return true

	return false


func repair(amount: float) -> void:
	if properties == null or amount <= 0.0:
		return

	current_health += amount
	if current_health > properties.max_health:
		current_health = properties.max_health


func break_block() -> void:
	queue_free()


func _apply_properties() -> void:
	if not is_node_ready() or properties == null:
		return

	current_health = properties.max_health
	collision_shape.disabled = properties.collision_mode == BlockPropertiesResource.CollisionMode.NONE

	if properties.texture != null:
		var material := StandardMaterial3D.new()
		material.albedo_texture = properties.texture
		mesh_instance.set_surface_override_material(0, material)
