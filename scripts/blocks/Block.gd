extends StaticBody3D
class_name Block

const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")
const BlockbenchModelResource := preload("res://scripts/models/BlockbenchModel.gd")
const ConnectedTextureResource := preload("res://scripts/world/ConnectedTexture.gd")
const ComponentProcessorRegistryResource := preload("res://scripts/components/ComponentProcessorRegistry.gd")
const InteractionContextResource := preload("res://scripts/components/InteractionContext.gd")

# The 6 cube faces: outward normal + in-plane axes (u = right, v = up in the
# face). Used for both mesh building and connected-texture neighbour lookup.
const FACES := [
	{ "normal": Vector3i(0, 1, 0), "u": Vector3i(1, 0, 0), "v": Vector3i(0, 0, -1) },   # top
	{ "normal": Vector3i(0, -1, 0), "u": Vector3i(1, 0, 0), "v": Vector3i(0, 0, 1) },    # bottom
	{ "normal": Vector3i(0, 0, 1), "u": Vector3i(1, 0, 0), "v": Vector3i(0, 1, 0) },     # +Z
	{ "normal": Vector3i(0, 0, -1), "u": Vector3i(-1, 0, 0), "v": Vector3i(0, 1, 0) },   # -Z
	{ "normal": Vector3i(1, 0, 0), "u": Vector3i(0, 0, -1), "v": Vector3i(0, 1, 0) },    # +X
	{ "normal": Vector3i(-1, 0, 0), "u": Vector3i(0, 0, 1), "v": Vector3i(0, 1, 0) },    # -X
]

# Per-shape mesh/collision built from a .bbmodel, keyed by BlockShape.
# Only shapes listed here use a real model; the rest fall back to a scaled box.
const SHAPE_MODEL_PATHS := {
	BlockPropertiesResource.BlockShape.STAIRS: "res://assets/models/block/stairs.bbmodel",
}

# Built lazily and shared across all block instances.
static var _shape_meshes: Dictionary = {}
static var _shape_collisions: Dictionary = {}

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
# Runtime-only: the placer, so faces can query same-block neighbours for CTM.
var world: Node = null

var _default_mesh: Mesh
var _default_shape: Shape3D
var _material: StandardMaterial3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	# Remember the scene's plain box so non-modelled shapes can restore it.
	_default_mesh = mesh_instance.mesh
	_default_shape = collision_shape.shape
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
		_material = StandardMaterial3D.new()
		_material.albedo_texture = properties.texture
		if properties.connected_texture:
			# Atlas tiles must not bleed into each other.
			_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mesh_instance.set_surface_override_material(0, _material)

	_apply_shape()
	_apply_facing()


## Applies geometry for the current shape: a connected-texture atlas mesh for a
## FULL shapeable block, a real per-shape model where one exists (stairs), or a
## scaled/offset box otherwise.
func _apply_shape() -> void:
	if not is_node_ready():
		return

	if properties.connected_texture and shape == BlockPropertiesResource.BlockShape.FULL and world != null:
		mesh_instance.mesh = _build_connected_mesh()
		mesh_instance.scale = Vector3.ONE
		mesh_instance.position = Vector3.ZERO
		collision_shape.shape = _default_shape
		collision_shape.scale = Vector3.ONE
		collision_shape.position = Vector3.ZERO
		if _material != null:
			_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Mesh UVs already index the atlas directly.
		_set_atlas_uv(false)
		_apply_facing()
		return

	# Non-FULL connected shapes can't do per-face CTM (their geometry differs),
	# so they sample a single clean interior tile instead of the whole atlas.
	_set_atlas_uv(true)

	var model_mesh := _shape_mesh(shape)
	if model_mesh != null:
		mesh_instance.mesh = model_mesh
		mesh_instance.scale = Vector3.ONE
		mesh_instance.position = Vector3.ZERO
		collision_shape.shape = _shape_collision(shape)
		collision_shape.scale = Vector3.ONE
		collision_shape.position = Vector3.ZERO
		# Concave model faces can be single-sided; render both sides.
		if _material != null:
			_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_apply_facing()
		return

	mesh_instance.mesh = _default_mesh
	collision_shape.shape = _default_shape
	if _material != null:
		_material.cull_mode = BaseMaterial3D.CULL_BACK
	var scale := get_shape_scale()
	var offset := get_shape_offset()
	mesh_instance.scale = scale
	mesh_instance.position = offset
	collision_shape.scale = scale
	collision_shape.position = offset
	# Keep the block's rotation consistent with the (possibly new) shape.
	_apply_facing()


## Maps the material's UVs to one interior atlas tile (single = true) or to the
## whole 0..1 range (single = false, for the CTM mesh whose UVs are already
## atlas coordinates). No-op for non-connected blocks.
func _set_atlas_uv(single: bool) -> void:
	if _material == null or not properties.connected_texture:
		return
	if not single:
		_material.uv1_scale = Vector3.ONE
		_material.uv1_offset = Vector3.ZERO
		return
	var atlas_px := properties.texture.get_size() if properties.texture != null else Vector2(96, 32)
	# Canonical tile 46 is the fully connected (border-free) interior.
	var rect := ConnectedTextureResource.tile_uv(46, atlas_px)
	_material.uv1_scale = Vector3(rect.size.x, rect.size.y, 1.0)
	_material.uv1_offset = Vector3(rect.position.x, rect.position.y, 0.0)


## Rebuilds the connected-texture mesh (call when a neighbour changes).
func refresh_connected() -> void:
	if is_node_ready() and properties != null and properties.connected_texture and shape == BlockPropertiesResource.BlockShape.FULL and world != null:
		mesh_instance.mesh = _build_connected_mesh()


## Whether the cell in [param offset] holds the same block (a CTM connection).
func _connects(offset: Vector3i) -> bool:
	if world == null or not world.has_method("get_block"):
		return false
	var other = world.get_block(grid_position + offset)
	return other != null and other.properties != null and other.properties.id == properties.id


## 8-neighbour connection mask for one face, in the face's (u, v) plane.
func face_connection_mask(face_index: int) -> int:
	var face: Dictionary = FACES[face_index]
	var u: Vector3i = face["u"]
	var v: Vector3i = face["v"]
	var mask := 0
	if _connects(v):      mask |= ConnectedTextureResource.N
	if _connects(u + v):  mask |= ConnectedTextureResource.NE
	if _connects(u):      mask |= ConnectedTextureResource.E
	if _connects(u - v):  mask |= ConnectedTextureResource.SE
	if _connects(-v):     mask |= ConnectedTextureResource.S
	if _connects(-u - v): mask |= ConnectedTextureResource.SW
	if _connects(-u):     mask |= ConnectedTextureResource.W
	if _connects(-u + v): mask |= ConnectedTextureResource.NW
	return mask


func _build_connected_mesh() -> ArrayMesh:
	var atlas_px := Vector2(96, 32)
	if properties.texture != null:
		atlas_px = properties.texture.get_size()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in FACES.size():
		var face: Dictionary = FACES[i]
		var n := Vector3(face["normal"])
		var u := Vector3(face["u"])
		var v := Vector3(face["v"])
		var center := n * 0.5
		var uv := ConnectedTextureResource.tile_uv(ConnectedTextureResource.tile_index(face_connection_mask(i)), atlas_px)

		# Corners and their atlas UVs (v points "up", to smaller texture V).
		var c00 := center - u * 0.5 - v * 0.5
		var c10 := center + u * 0.5 - v * 0.5
		var c11 := center + u * 0.5 + v * 0.5
		var c01 := center - u * 0.5 + v * 0.5
		var uv00 := Vector2(uv.position.x, uv.position.y + uv.size.y)
		var uv10 := Vector2(uv.position.x + uv.size.x, uv.position.y + uv.size.y)
		var uv11 := Vector2(uv.position.x + uv.size.x, uv.position.y)
		var uv01 := Vector2(uv.position.x, uv.position.y)

		_add_quad(st, n, c00, uv00, c10, uv10, c11, uv11, c01, uv01)

	return st.commit()


func _add_quad(st: SurfaceTool, n: Vector3, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2, d: Vector3, ud: Vector2) -> void:
	for item in [[a, ua], [b, ub], [c, uc], [a, ua], [c, uc], [d, ud]]:
		st.set_normal(n)
		st.set_uv(item[1])
		st.add_vertex(item[0])


## Cached mesh for shapes that have a .bbmodel, or null to use the scaled box.
static func _shape_mesh(shape_value: int) -> Mesh:
	if not SHAPE_MODEL_PATHS.has(shape_value):
		return null
	if not _shape_meshes.has(shape_value):
		_build_shape_model(shape_value)
	return _shape_meshes.get(shape_value)


static func _shape_collision(shape_value: int) -> Shape3D:
	if not _shape_collisions.has(shape_value):
		_build_shape_model(shape_value)
	return _shape_collisions.get(shape_value)


static func _build_shape_model(shape_value: int) -> void:
	var model = BlockbenchModelResource.load_from_file(SHAPE_MODEL_PATHS[shape_value])
	if model == null or model.is_empty():
		_shape_meshes[shape_value] = null
		_shape_collisions[shape_value] = null
		return
	var mesh := model.build_mesh()
	_shape_meshes[shape_value] = mesh
	_shape_collisions[shape_value] = mesh.create_trimesh_shape()


## Rotates the whole block so its shape/offset face the current direction.
func _apply_facing() -> void:
	if not is_node_ready():
		return
	# A connected-texture FULL block resolves each face from neighbours, so
	# rotating it would spin the texture out of alignment. Keep it upright.
	if properties != null and properties.connected_texture and shape == BlockPropertiesResource.BlockShape.FULL:
		rotation.y = 0.0
		return
	rotation.y = BlockPropertiesResource.facing_yaw(facing)
