extends Resource
class_name BlockProperties

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")
const BlockEntityPropertiesResource := preload("res://scripts/block_entities/BlockEntityProperties.gd")
const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")
const ComponentHost := preload("res://scripts/components/ComponentHost.gd")

enum CollisionMode {
	NONE,
	SOLID,
	TRIGGER,
}

## The forms a single block can take (à la "Clutter No More"). Shape is block
## state, not a separate item, so every shape of a material shares one item.
enum BlockShape {
	FULL,
	STAIRS,
	SLAB,
	VERTICAL_SLAB,
	STEP,
}

const ALL_SHAPES: Array[int] = [
	BlockShape.FULL,
	BlockShape.STAIRS,
	BlockShape.SLAB,
	BlockShape.VERTICAL_SLAB,
	BlockShape.STEP,
]

## Horizontal facing for directional blocks. Order matters: rotating advances
## NORTH -> EAST -> SOUTH -> WEST (clockwise seen from above).
enum BlockFacing {
	NORTH,
	EAST,
	SOUTH,
	WEST,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var texture: Texture2D
@export var model: Resource
@export var collision_mode: CollisionMode = CollisionMode.SOLID
@export_range(0.0, 1000.0, 0.1) var hardness: float = 1.0
@export_range(0.0, 1000.0, 0.1) var max_health: float = 10.0
@export var can_place := true
@export var can_break := true
@export var emits_light := false
@export_range(0.0, 16.0, 1.0) var light_energy: int = 0
@export var drop_item: ItemPropertiesResource = null
@export_range(0.0, 999.0, 1.0) var drop_quantity: int = 1
@export var block_entity: BlockEntityPropertiesResource = null
## When true, placed blocks can switch between [member allowed_shapes] on demand.
@export var shapeable := false
@export var default_shape: BlockShape = BlockShape.FULL
## Shapes this block may take. Empty + shapeable means all of [constant ALL_SHAPES].
@export var allowed_shapes: Array[int] = []
## When true, placed blocks can be rotated to face NORTH/EAST/SOUTH/WEST.
@export var directional := false
@export var default_facing: BlockFacing = BlockFacing.NORTH
@export var components: Array[ComponentPropertiesResource] = []


func is_solid() -> bool:
	return collision_mode == CollisionMode.SOLID


func get_allowed_shapes() -> Array[int]:
	if not shapeable:
		return [int(default_shape)]
	if not allowed_shapes.is_empty():
		return allowed_shapes
	return ALL_SHAPES.duplicate()


func allows_shape(shape: int) -> bool:
	return shape in get_allowed_shapes()


func can_change_shape() -> bool:
	return shapeable and get_allowed_shapes().size() > 1


func can_change_facing() -> bool:
	return directional


## Yaw (radians about +Y) that orients a block so its front points [param facing].
## NORTH is the unrotated front (local -Z).
static func facing_yaw(facing: int) -> float:
	match facing:
		BlockFacing.EAST:
			return -PI / 2.0
		BlockFacing.SOUTH:
			return PI
		BlockFacing.WEST:
			return PI / 2.0
		_:
			return 0.0


func should_drop_item() -> bool:
	return drop_item != null and drop_quantity > 0


func has_block_entity() -> bool:
	return block_entity != null


func get_component(id: StringName) -> ComponentPropertiesResource:
	return ComponentHost.get_component(components, id) as ComponentPropertiesResource


func has_component(id: StringName) -> bool:
	return ComponentHost.has_component(components, id)


func get_components_by_type(type: StringName) -> Array[ComponentPropertiesResource]:
	var matching: Array[ComponentPropertiesResource] = []
	for component in ComponentHost.get_components_by_type(components, type):
		matching.append(component)
	return matching
