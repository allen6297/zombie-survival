extends RefCounted
class_name JsonDefinitionLoader

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")
const ItemRegistryResource := preload("res://scripts/items/ItemRegistry.gd")
const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")
const BlockRegistryResource := preload("res://scripts/blocks/BlockRegistry.gd")
const EntityPropertiesResource := preload("res://scripts/entities/EntityProperties.gd")
const EntityRegistryResource := preload("res://scripts/entities/EntityRegistry.gd")
const BlockEntityPropertiesResource := preload("res://scripts/block_entities/BlockEntityProperties.gd")
const BlockEntityRegistryResource := preload("res://scripts/block_entities/BlockEntityRegistry.gd")
const ComponentPropertiesResource := preload("res://scripts/components/ComponentProperties.gd")


static func load_item_registry(path: String) -> ItemRegistryResource:
	var registry := ItemRegistryResource.new()
	for definition in _load_definitions(path):
		var item := ItemPropertiesResource.new()
		item.id = _string_name(definition, "id")
		item.display_name = _string(definition, "display_name")
		item.description = _string(definition, "description")
		item.texture = _load_resource(_string(definition, "texture")) as Texture2D
		item.model = _load_resource(_string(definition, "model"))
		item.stack_size = _int(definition, "stack_size", 1)
		item.components = _components(definition)
		registry.add_item(item)
	return registry


static func load_block_registry(path: String) -> BlockRegistryResource:
	var registry := BlockRegistryResource.new()
	for definition in _load_definitions(path):
		var block := BlockPropertiesResource.new()
		block.id = _string_name(definition, "id")
		block.display_name = _string(definition, "display_name")
		block.description = _string(definition, "description")
		block.texture = _load_resource(_string(definition, "texture")) as Texture2D
		block.model = _load_resource(_string(definition, "model"))
		block.collision_mode = _collision_mode(_string(definition, "collision_mode", "solid"))
		block.hardness = _float(definition, "hardness", 1.0)
		block.max_health = _float(definition, "max_health", 10.0)
		block.can_place = _bool(definition, "can_place", true)
		block.can_break = _bool(definition, "can_break", true)
		block.emits_light = _bool(definition, "emits_light", false)
		block.light_energy = _int(definition, "light_energy", 0)
		block.drop_quantity = _int(definition, "drop_quantity", 1)
		block.shapeable = _bool(definition, "shapeable", false)
		block.default_shape = _block_shape(_string(definition, "default_shape", "full"))
		block.allowed_shapes = _block_shapes(definition)
		block.directional = _bool(definition, "directional", false)
		block.default_facing = _block_facing(_string(definition, "default_facing", "north"))
		block.components = _components(definition)
		registry.add_block(block)
	return registry


static func load_entity_registry(path: String) -> EntityRegistryResource:
	var registry := EntityRegistryResource.new()
	for definition in _load_definitions(path):
		var entity := EntityPropertiesResource.new()
		entity.id = _string_name(definition, "id")
		entity.display_name = _string(definition, "display_name")
		entity.description = _string(definition, "description")
		entity.kind = _entity_kind(_string(definition, "kind", "neutral"))
		entity.texture = _load_resource(_string(definition, "texture")) as Texture2D
		entity.model = _load_resource(_string(definition, "model"))
		entity.max_health = _float(definition, "max_health", 20.0)
		entity.move_speed = _float(definition, "move_speed", 5.0)
		entity.interaction_range = _float(definition, "interaction_range", 2.0)
		entity.can_take_damage = _bool(definition, "can_take_damage", true)
		entity.components = _components(definition)
		registry.add_entity(entity)
	return registry


static func load_block_entity_registry(path: String) -> BlockEntityRegistryResource:
	var registry := BlockEntityRegistryResource.new()
	for definition in _load_definitions(path):
		var block_entity := BlockEntityPropertiesResource.new()
		block_entity.id = _string_name(definition, "id")
		block_entity.display_name = _string(definition, "display_name")
		block_entity.description = _string(definition, "description")
		block_entity.kind = _block_entity_kind(_string(definition, "kind", "generic"))
		block_entity.inventory_size = _int(definition, "inventory_size", 0)
		block_entity.accepts_items = _bool(definition, "accepts_items", false)
		block_entity.emits_signal = _bool(definition, "emits_signal", false)
		block_entity.persists_state = _bool(definition, "persists_state", true)
		block_entity.components = _components(definition)
		registry.add_block_entity(block_entity)
	return registry


static func _load_definitions(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Definition file does not exist: %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to read definition file: %s" % path)
		return []

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Definition file must contain a JSON object: %s" % path)
		return []

	var definitions = parsed.get("definitions", [])
	if definitions is Array:
		return definitions

	push_error("Definition file must contain a definitions array: %s" % path)
	return []


static func _load_resource(path: String) -> Resource:
	if path.is_empty():
		return null
	return load(path)


static func _string(definition: Dictionary, key: String, default_value: String = "") -> String:
	return str(definition.get(key, default_value))


static func _string_name(definition: Dictionary, key: String) -> StringName:
	return StringName(_string(definition, key))


static func _int(definition: Dictionary, key: String, default_value: int) -> int:
	return int(definition.get(key, default_value))


static func _float(definition: Dictionary, key: String, default_value: float) -> float:
	return float(definition.get(key, default_value))


static func _bool(definition: Dictionary, key: String, default_value: bool) -> bool:
	return bool(definition.get(key, default_value))


static func _components(definition: Dictionary) -> Array[ComponentPropertiesResource]:
	var components: Array[ComponentPropertiesResource] = []
	var raw_components = definition.get("components", [])
	if not raw_components is Array:
		return components

	for raw_component in raw_components:
		if not raw_component is Dictionary:
			continue

		var component := ComponentPropertiesResource.new()
		component.id = _string_name(raw_component, "id")
		component.type = StringName(_string(raw_component, "type"))
		var data = raw_component.get("data", {})
		if data is Dictionary:
			component.data = data
		components.append(component)

	return components


static func _collision_mode(value: String) -> BlockPropertiesResource.CollisionMode:
	match value.to_lower():
		"none":
			return BlockPropertiesResource.CollisionMode.NONE
		"trigger":
			return BlockPropertiesResource.CollisionMode.TRIGGER
		_:
			return BlockPropertiesResource.CollisionMode.SOLID


static func _block_shape(value: String) -> BlockPropertiesResource.BlockShape:
	match value.to_lower():
		"stairs":
			return BlockPropertiesResource.BlockShape.STAIRS
		"slab":
			return BlockPropertiesResource.BlockShape.SLAB
		"vertical_slab":
			return BlockPropertiesResource.BlockShape.VERTICAL_SLAB
		"step":
			return BlockPropertiesResource.BlockShape.STEP
		_:
			return BlockPropertiesResource.BlockShape.FULL


static func _block_shapes(definition: Dictionary) -> Array[int]:
	var shapes: Array[int] = []
	var raw = definition.get("allowed_shapes", [])
	if not raw is Array:
		return shapes
	for value in raw:
		shapes.append(int(_block_shape(str(value))))
	return shapes


static func _block_facing(value: String) -> BlockPropertiesResource.BlockFacing:
	match value.to_lower():
		"east":
			return BlockPropertiesResource.BlockFacing.EAST
		"south":
			return BlockPropertiesResource.BlockFacing.SOUTH
		"west":
			return BlockPropertiesResource.BlockFacing.WEST
		_:
			return BlockPropertiesResource.BlockFacing.NORTH


static func _entity_kind(value: String) -> EntityPropertiesResource.EntityKind:
	match value.to_lower():
		"player":
			return EntityPropertiesResource.EntityKind.PLAYER
		"npc":
			return EntityPropertiesResource.EntityKind.NPC
		"hostile":
			return EntityPropertiesResource.EntityKind.HOSTILE
		"projectile":
			return EntityPropertiesResource.EntityKind.PROJECTILE
		_:
			return EntityPropertiesResource.EntityKind.NEUTRAL


static func _block_entity_kind(value: String) -> BlockEntityPropertiesResource.BlockEntityKind:
	match value.to_lower():
		"container":
			return BlockEntityPropertiesResource.BlockEntityKind.CONTAINER
		"workstation":
			return BlockEntityPropertiesResource.BlockEntityKind.WORKSTATION
		"spawner":
			return BlockEntityPropertiesResource.BlockEntityKind.SPAWNER
		_:
			return BlockEntityPropertiesResource.BlockEntityKind.GENERIC
