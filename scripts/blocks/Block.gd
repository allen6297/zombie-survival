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
# Runtime-only: the block's current form; see BlockProperties.BlockShape.
var shape: int = BlockPropertiesResource.BlockShape.FULL
# Runtime-only: horizontal facing; see BlockProperties.BlockFacing.
var facing: int = BlockPropertiesResource.BlockFacing.NORTH
# Runtime-only: grid cell this block was placed at; set by WorldBlockPlacer.
var grid_position: Vector3i = Vector3i.ZERO

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_apply_properties()


## Switches this block to [param new_shape] if the definition allows it.
func set_shape(new_shape: int) -> bool:
	if properties == null or not properties.allows_shape(new_shape):
		return false

	shape = new_shape
	_apply_shape()
	return true


## Advances to the next allowed shape and returns it (unchanged if the block
## has only one allowed shape).
func cycle_shape() -> int:
	if properties == null:
		return shape

	var allowed := properties.get_allowed_shapes()
	if allowed.size() <= 1:
		return shape

	var index := allowed.find(shape)
	shape = allowed[(index + 1) % allowed.size()] if index != -1 else allowed[0]
	_apply_shape()
	return shape


## Rotates this block to [param new_facing] if the definition is directional.
func set_facing(new_facing: int) -> bool:
	if properties == null or not properties.directional:
		return false

	facing = new_facing
	_apply_facing()
	return true


## Advances to the next facing (NORTH -> EAST -> SOUTH -> WEST) and returns it.
func rotate_facing() -> int:
	if properties == null or not properties.directional:
		return facing

	facing = (facing + 1) % 4
	_apply_facing()
	return facing


## Fraction of the unit cell the current shape occupies, per axis.
func get_shape_scale() -> Vector3:
	match shape:
		BlockPropertiesResource.BlockShape.SLAB:
			return Vector3(1.0, 0.5, 1.0)
		BlockPropertiesResource.BlockShape.VERTICAL_SLAB:
			return Vector3(0.5, 1.0, 1.0)
		BlockPropertiesResource.BlockShape.STEP:
			return Vector3(1.0, 0.5, 0.5)
		_:
			return Vector3.ONE


## Local offset that keeps a partial shape aligned to a cell edge/floor.
func get_shape_offset() -> Vector3:
	match shape:
		BlockPropertiesResource.BlockShape.SLAB:
			return Vector3(0.0, -0.25, 0.0)
		BlockPropertiesResource.BlockShape.STEP:
			return Vector3(0.0, -0.25, 0.25)
		BlockPropertiesResource.BlockShape.VERTICAL_SLAB:
			return Vector3(-0.25, 0.0, 0.0)
		_:
			return Vector3.ZERO


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
	if properties == null:
		return

	# Shape and facing are data, so resolve them even before the node is ready.
	shape = properties.default_shape if properties.allows_shape(properties.default_shape) else BlockPropertiesResource.BlockShape.FULL
	facing = properties.default_facing

	if not is_node_ready():
		return

	current_health = properties.max_health
	collision_shape.disabled = properties.collision_mode == BlockPropertiesResource.CollisionMode.NONE

	if properties.texture != null:
		var material := StandardMaterial3D.new()
		material.albedo_texture = properties.texture
		mesh_instance.set_surface_override_material(0, material)

	_apply_shape()
	_apply_facing()


## Best-effort geometry for the current shape: scale/offset the box mesh and
## collision. Full per-shape meshes (real stairs, etc.) are future work.
func _apply_shape() -> void:
	if not is_node_ready():
		return

	var scale := get_shape_scale()
	var offset := get_shape_offset()
	mesh_instance.scale = scale
	mesh_instance.position = offset
	collision_shape.scale = scale
	collision_shape.position = offset


## Rotates the whole block so its shape/offset face the current direction.
func _apply_facing() -> void:
	if not is_node_ready():
		return
	rotation.y = BlockPropertiesResource.facing_yaw(facing)
