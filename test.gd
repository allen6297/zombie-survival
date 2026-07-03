extends SceneTree

# To run this script:
# godot --headless --path . -s test.gd

const InventoryResource = preload("res://scripts/inventory/Inventory.gd")
const ItemPropertiesResource = preload("res://scripts/items/ItemProperties.gd")
const KITCHEN_KNIFE = preload("res://assets/definitions/items/knives/kitchen_knife.tres")
const JsonDefinitionLoader = preload("res://scripts/registry/JsonDefinitionLoader.gd")
const MinecraftModelJson = preload("res://scripts/models/MinecraftModelJson.gd")
const ItemNode = preload("res://scripts/items/Item.gd")
const ItemStack = preload("res://scripts/items/ItemStack.gd")
const InteractionContext = preload("res://scripts/components/InteractionContext.gd")
const BlockNode = preload("res://scripts/blocks/Block.gd")
const BlockPropertiesResource = preload("res://scripts/blocks/BlockProperties.gd")
const WorldBlockPlacer = preload("res://scripts/world/WorldBlockPlacer.gd")
const BlockEntityNode = preload("res://scripts/block_entities/BlockEntity.gd")
const SaveSystemResource = preload("res://SaveSystem/save_system.gd")
const GameStateResource = preload("res://scripts/game/GameState.gd")

# YARD Registry .tres files (baked in the editor via the YARD tab).
# Loaded at runtime so a missing/unbaked registry SKIPs its test instead of
# breaking compilation.
const ITEM_YARD_REGISTRY_PATH := "res://assets/definitions/items/item_registry.yard.tres"
const BLOCK_YARD_REGISTRY_PATH := "res://assets/definitions/blocks/block_registry.yard.tres"
const ENTITY_YARD_REGISTRY_PATH := "res://assets/definitions/entities/entity_registry.yard.tres"
const BLOCK_ENTITY_YARD_REGISTRY_PATH := "res://assets/definitions/block_entities/block_entity_registry.yard.tres"

# Test result states.
const PASS := 0
const FAIL := 1
const SKIP := 2

var _passed := 0
var _failed := 0
var _skipped := 0


class DamageTarget:
	extends Node

	var damage_taken := 0.0

	func damage(amount: float) -> bool:
		damage_taken += amount
		return damage_taken >= 4.0


func _init() -> void:
	var tests := [
		_test_inventory,
		_test_item_registry,
		_test_block_registry,
		_test_entity_registry,
		_test_block_entity_registry,
		_test_json_definitions,
		_test_item_use_pipeline,
		_test_item_stack_runtime_state,
		_test_world_block_placement,
		_test_block_interaction_pipeline,
		_test_minecraft_model_json,
		_test_save_roundtrip,
		_test_block_entity_inventory_save,
		_test_inventory_component_state,
		_test_block_entity_world_wiring,
		_test_game_state_save,
		_test_block_shapes,
		_test_block_facing,
	]

	for test in tests:
		match test.call():
			PASS:
				_passed += 1
			SKIP:
				_skipped += 1
			_:
				_failed += 1

	print("Smoke tests finished: %d passed, %d failed, %d skipped." % [_passed, _failed, _skipped])
	quit(1 if _failed > 0 else 0)


## Loads a YARD registry at [param path], or returns null (with a SKIP hint) if
## the file does not exist yet or has not been baked/scanned in the editor.
func _load_yard_registry(path: String, label: String) -> Resource:
	if not ResourceLoader.exists(path):
		print("SKIP: %s YARD registry not found at %s (create + scan it in the YARD tab)." % [label, path])
		return null

	var registry = load(path)
	if registry == null or registry.is_empty():
		print("SKIP: %s YARD registry at %s is empty (scan it in the YARD tab)." % [label, path])
		return null

	return registry


func _test_inventory() -> int:
	var inventory = InventoryResource.new(2)

	var first_remainder: int = inventory.add_item(KITCHEN_KNIFE, 1)
	var overflow_remainder: int = inventory.add_item(KITCHEN_KNIFE, 3)

	if first_remainder != 0:
		push_error("Expected first item to fit in the inventory.")
	elif overflow_remainder != 2:
		push_error("Expected two non-stackable knives to overflow a two-slot inventory.")
	elif not inventory.has_item(KITCHEN_KNIFE, 2):
		push_error("Expected inventory to contain two kitchen knives.")
	elif not KITCHEN_KNIFE.has_component(&"damage"):
		push_error("Expected kitchen_knife TRES to have a damage component.")
	else:
		print("Inventory smoke test passed.")
		return PASS
	return FAIL


func _test_item_registry() -> int:
	var registry = _load_yard_registry(ITEM_YARD_REGISTRY_PATH, "item")
	if registry == null:
		return SKIP

	var kitchen_knife = registry.load_entry(&"kitchen_knife")

	if kitchen_knife == null:
		push_error("Expected kitchen_knife in the item registry.")
	elif not registry.has(&"chef_knife"):
		push_error("Expected chef_knife in the item registry.")
	elif kitchen_knife.stack_size != 1:
		push_error("Expected kitchen_knife to be non-stackable.")
	else:
		print("Item registry smoke test passed.")
		return PASS
	return FAIL


func _test_block_registry() -> int:
	var registry = _load_yard_registry(BLOCK_YARD_REGISTRY_PATH, "block")
	if registry == null:
		return SKIP

	var floor_block = registry.load_entry(&"prototype_floor")
	var wall_block = registry.load_entry(&"prototype_wall")

	if floor_block == null:
		push_error("Expected prototype_floor in the block registry.")
	elif wall_block == null:
		push_error("Expected prototype_wall in the block registry.")
	elif not wall_block.is_solid():
		push_error("Expected prototype_wall to be solid.")
	else:
		print("Block registry smoke test passed.")
		return PASS
	return FAIL


func _test_entity_registry() -> int:
	var registry = _load_yard_registry(ENTITY_YARD_REGISTRY_PATH, "entity")
	if registry == null:
		return SKIP

	var entity = registry.load_entry(&"prototype_entity")

	if entity == null:
		push_error("Expected prototype_entity in the entity registry.")
	elif not entity.is_alive_health(entity.max_health):
		push_error("Expected prototype_entity max health to be alive.")
	else:
		print("Entity registry smoke test passed.")
		return PASS
	return FAIL


func _test_block_entity_registry() -> int:
	var registry = _load_yard_registry(BLOCK_ENTITY_YARD_REGISTRY_PATH, "block entity")
	if registry == null:
		return SKIP

	var block_entity = registry.load_entry(&"container_block_entity")

	if block_entity == null:
		push_error("Expected container_block_entity in the block entity registry.")
	elif not block_entity.has_inventory():
		push_error("Expected container_block_entity to have inventory.")
	else:
		print("Block entity registry smoke test passed.")
		return PASS
	return FAIL


func _test_json_definitions() -> int:
	var item_registry = JsonDefinitionLoader.load_item_registry("res://assets/definitions/items/knives.json")
	var block_registry = JsonDefinitionLoader.load_block_registry("res://assets/definitions/blocks/prototype_blocks.json")
	var entity_registry = JsonDefinitionLoader.load_entity_registry("res://assets/definitions/entities/prototype_entities.json")
	var block_entity_registry = JsonDefinitionLoader.load_block_entity_registry("res://assets/definitions/block_entities/prototype_block_entities.json")
	var kitchen_knife = item_registry.get_item(&"kitchen_knife")
	var prototype_wall = block_registry.get_block(&"prototype_wall")
	var prototype_entity = entity_registry.get_entity(&"prototype_entity")
	var container_block_entity = block_entity_registry.get_block_entity(&"container_block_entity")

	if kitchen_knife == null:
		push_error("Expected kitchen_knife from JSON item definitions.")
	elif not kitchen_knife.has_component(&"damage"):
		push_error("Expected kitchen_knife JSON definition to have a damage component.")
	elif prototype_wall == null:
		push_error("Expected prototype_wall from JSON block definitions.")
	elif not prototype_wall.has_component(&"placeable"):
		push_error("Expected prototype_wall JSON definition to have a placeable component.")
	elif prototype_entity == null:
		push_error("Expected prototype_entity from JSON entity definitions.")
	elif not prototype_entity.has_component(&"health"):
		push_error("Expected prototype_entity JSON definition to have a health component.")
	elif container_block_entity == null:
		push_error("Expected container_block_entity from JSON block entity definitions.")
	elif not container_block_entity.has_component(&"inventory"):
		push_error("Expected container_block_entity JSON definition to have an inventory component.")
	else:
		print("JSON definition smoke test passed.")
		return PASS
	return FAIL


func _test_item_use_pipeline() -> int:
	var item := ItemNode.new()
	var target := DamageTarget.new()
	var context := InteractionContext.new()
	item.properties = KITCHEN_KNIFE
	context.target = target

	var used := item.use(context)

	if not used:
		push_error("Expected kitchen_knife use to be handled by a component processor.")
	elif target.damage_taken != 4.0:
		push_error("Expected kitchen_knife damage processor to damage the target.")
	elif context.get_result(&"damage_type") != "slash":
		push_error("Expected damage processor to record slash damage type.")
	elif not context.get_result(&"target_defeated", false):
		push_error("Expected damage processor to record defeated target.")
	else:
		print("Item use pipeline smoke test passed.")
		return PASS
	return FAIL


func _test_item_stack_runtime_state() -> int:
	var stack := ItemStack.new(KITCHEN_KNIFE, 1)
	stack.set_component_value(&"durability", &"current", 10)

	if stack.is_empty():
		push_error("Expected new kitchen_knife stack to be non-empty.")
	elif stack.get_component_value(&"durability", &"current") != 10:
		push_error("Expected item stack component state to store durability.")
	elif not stack.consume(1):
		push_error("Expected item stack to consume one item.")
	elif not stack.is_empty():
		push_error("Expected consumed one-item stack to be empty.")
	else:
		print("Item stack runtime state smoke test passed.")
		return PASS
	return FAIL


func _test_world_block_placement() -> int:
	var registry = _load_yard_registry(BLOCK_YARD_REGISTRY_PATH, "block")
	if registry == null:
		return SKIP

	var world := WorldBlockPlacer.new()
	var context := InteractionContext.new()
	var wall_block = registry.load_entry(&"prototype_wall")
	context.world = world
	context.block = wall_block
	context.target_grid_position = Vector3i(2, 0, 0)

	var handled = wall_block.get_component(&"placeable") != null and world.place_block(wall_block, context.target_grid_position) != null

	if not handled:
		push_error("Expected world block placer to place prototype_wall.")
	elif world.get_block(Vector3i(2, 0, 0)) == null:
		push_error("Expected world block placer to track placed block.")
	else:
		print("World block placement smoke test passed.")
		return PASS
	return FAIL


func _test_block_interaction_pipeline() -> int:
	var registry = _load_yard_registry(BLOCK_YARD_REGISTRY_PATH, "block")
	if registry == null:
		return SKIP

	var block := BlockNode.new()
	var world := WorldBlockPlacer.new()
	var context := InteractionContext.new()
	block.properties = registry.load_entry(&"prototype_wall")
	context.world = world
	context.target_grid_position = Vector3i(3, 0, 0)

	var interacted := block.interact(context)

	if not interacted:
		push_error("Expected prototype_wall block interaction to be handled.")
	elif context.get_result(&"place_position") != Vector3i(3, 0, 0):
		push_error("Expected block interaction to populate placement position.")
	else:
		print("Block interaction pipeline smoke test passed.")
		return PASS
	return FAIL


func _test_minecraft_model_json() -> int:
	var model = MinecraftModelJson.load_from_file("res://assets/models/minecraft/block/carrots_stage0.json")

	if model.parent != "minecraft:block/crop":
		push_error("Expected carrots_stage0 parent to be minecraft:block/crop.")
	elif model.get_texture(&"crop") != "minecraft:block/carrots_stage0":
		push_error("Expected carrots_stage0 crop texture reference.")
	elif model.get_texture_path(&"crop") != "res://assets/textures/minecraft/block/carrots_stage0.png":
		push_error("Expected carrots_stage0 to resolve to local texture path.")
	elif model.load_texture(&"crop") == null:
		push_error("Expected carrots_stage0 local texture to load.")
	elif not model.is_parent_template():
		push_error("Expected carrots_stage0 to be a parent-template model.")
	else:
		print("Minecraft model JSON smoke test passed.")
		return PASS
	return FAIL


func _test_save_roundtrip() -> int:
	var item_registry = _load_yard_registry(ITEM_YARD_REGISTRY_PATH, "item")
	var block_registry = _load_yard_registry(BLOCK_YARD_REGISTRY_PATH, "block")
	if item_registry == null or block_registry == null:
		return SKIP

	var item_resolver := func(id: StringName): return item_registry.load_entry(id)
	var block_resolver := func(id: StringName): return block_registry.load_entry(id)

	var kitchen_knife = item_registry.load_entry(&"kitchen_knife")
	var chef_knife = item_registry.load_entry(&"chef_knife")
	var wall = block_registry.load_entry(&"prototype_wall")

	# Build some state: a 4-slot inventory with two items and one placed block.
	var inventory := InventoryResource.new(4)
	inventory.add_item(kitchen_knife, 1)
	inventory.add_item(chef_knife, 1)

	var world := WorldBlockPlacer.new()
	world.place_block(wall, Vector3i(5, 0, 0))

	# Persist through the SaveSystem to a file and read it back.
	var save := SaveSystemResource.new()
	save.set_value("inventory", inventory.get_save_data())
	save.set_value("world", world.get_save_data())
	var file_name := "roundtrip_test.txt"
	save.set_save_game(file_name)

	var loaded := SaveSystemResource.new()
	loaded.get_save_game(file_name)

	# Restore into fresh objects using the registry resolvers.
	var restored_inventory := InventoryResource.new()
	restored_inventory.set_save_data(loaded.get_value("inventory"), item_resolver)

	var restored_world := WorldBlockPlacer.new()
	restored_world.set_save_data(loaded.get_value("world"), block_resolver)

	var restored_block := restored_world.get_block(Vector3i(5, 0, 0))
	var result := FAIL
	if restored_inventory.size != 4:
		push_error("Expected restored inventory to keep its size of 4.")
	elif not restored_inventory.has_item(kitchen_knife, 1):
		push_error("Expected restored inventory to contain the kitchen_knife.")
	elif not restored_inventory.has_item(chef_knife, 1):
		push_error("Expected restored inventory to contain the chef_knife.")
	elif restored_block == null:
		push_error("Expected restored world to have a block at (5, 0, 0).")
	elif restored_block.properties.id != &"prototype_wall":
		push_error("Expected restored block to be prototype_wall.")
	else:
		print("Save round-trip smoke test passed.")
		result = PASS

	world.free()
	restored_world.free()
	return result


func _test_block_entity_inventory_save() -> int:
	var item_registry = _load_yard_registry(ITEM_YARD_REGISTRY_PATH, "item")
	var block_entity_registry = _load_yard_registry(BLOCK_ENTITY_YARD_REGISTRY_PATH, "block entity")
	if item_registry == null or block_entity_registry == null:
		return SKIP

	var item_resolver := func(id: StringName): return item_registry.load_entry(id)
	var kitchen_knife = item_registry.load_entry(&"kitchen_knife")
	var properties = block_entity_registry.load_entry(&"container_block_entity")

	# A container block entity holding one item at a known position.
	var chest := BlockEntityNode.new()
	chest.properties = properties
	chest.block_position = Vector3i(1, 2, 3)
	chest.inventory = InventoryResource.new(properties.inventory_size)
	chest.inventory.add_item(kitchen_knife, 1)

	var save := SaveSystemResource.new()
	save.set_value("chest", chest.get_save_data())
	save.set_save_game("block_entity_test.txt")

	var loaded := SaveSystemResource.new()
	loaded.get_save_game("block_entity_test.txt")

	var restored := BlockEntityNode.new()
	restored.properties = properties
	restored.set_save_data(loaded.get_value("chest"), item_resolver)

	var result := FAIL
	if restored.block_position != Vector3i(1, 2, 3):
		push_error("Expected restored block entity position to round-trip.")
	elif restored.inventory == null:
		push_error("Expected restored block entity to have an inventory.")
	elif not restored.inventory.has_item(kitchen_knife, 1):
		push_error("Expected restored block entity inventory to contain kitchen_knife.")
	else:
		print("Block entity inventory save smoke test passed.")
		result = PASS

	chest.free()
	restored.free()
	return result


func _test_inventory_component_state() -> int:
	var item_registry = _load_yard_registry(ITEM_YARD_REGISTRY_PATH, "item")
	if item_registry == null:
		return SKIP

	var item_resolver := func(id: StringName): return item_registry.load_entry(id)

	# Stacking rule, using a synthetic stackable item: same state merges,
	# differing state (and stateless) stays in separate slots.
	var stackable := ItemPropertiesResource.new()
	stackable.id = &"test_stackable"
	stackable.stack_size = 64

	var bench := InventoryResource.new(8)
	bench.add_item(stackable, 5, {"tier": "a"})
	bench.add_item(stackable, 3, {"tier": "a"})
	bench.add_item(stackable, 2, {"tier": "b"})
	bench.add_item(stackable, 4)

	var occupied := 0
	var tier_a_qty := 0
	for slot in bench.slots:
		if not slot.is_empty():
			occupied += 1
			if slot.component_state.get("tier") == "a":
				tier_a_qty = slot.quantity

	# Persistence, using a registry-resolvable item so state survives a
	# get_save_data/set_save_data round-trip.
	var kitchen_knife = item_registry.load_entry(&"kitchen_knife")
	var inv := InventoryResource.new(2)
	inv.add_item(kitchen_knife, 1, {"durability": 7})
	var restored := InventoryResource.new(2)
	restored.set_save_data(inv.get_save_data(), item_resolver)

	var restored_durability = null
	for slot in restored.slots:
		if not slot.is_empty():
			restored_durability = slot.component_state.get("durability")

	if occupied != 3:
		push_error("Expected stateful/stateless items to occupy 3 slots, got %d." % occupied)
	elif tier_a_qty != 8:
		push_error("Expected same-state items to stack to 8, got %d." % tier_a_qty)
	elif restored_durability != 7:
		push_error("Expected restored slot to preserve durability state.")
	else:
		print("Inventory component-state smoke test passed.")
		return PASS
	return FAIL


func _test_block_entity_world_wiring() -> int:
	var item_registry = _load_yard_registry(ITEM_YARD_REGISTRY_PATH, "item")
	var block_entity_registry = _load_yard_registry(BLOCK_ENTITY_YARD_REGISTRY_PATH, "block entity")
	if item_registry == null or block_entity_registry == null:
		return SKIP

	var item_resolver := func(id: StringName): return item_registry.load_entry(id)
	var kitchen_knife = item_registry.load_entry(&"kitchen_knife")
	var container_props = block_entity_registry.load_entry(&"container_block_entity")

	# A synthetic block whose definition carries a block entity.
	var block_props := BlockPropertiesResource.new()
	block_props.id = &"test_chest_block"
	block_props.block_entity = container_props
	var block_resolver := func(id: StringName): return block_props if id == &"test_chest_block" else null

	# Placing it should spawn and track a block entity.
	var world := WorldBlockPlacer.new()
	world.place_block(block_props, Vector3i(0, 1, 0))
	var chest := world.get_block_entity(Vector3i(0, 1, 0))
	if chest != null and chest.inventory != null:
		chest.inventory.add_item(kitchen_knife, 2)

	# The world save should nest the block entity's inventory and restore it.
	var restored_world := WorldBlockPlacer.new()
	restored_world.set_save_data(world.get_save_data(), block_resolver, item_resolver)
	var restored_chest := restored_world.get_block_entity(Vector3i(0, 1, 0))

	var result := FAIL
	if chest == null:
		push_error("Expected placing a block with a block_entity to spawn one.")
	elif restored_chest == null:
		push_error("Expected restored world to respawn the block entity.")
	elif restored_chest.inventory == null or not restored_chest.inventory.has_item(kitchen_knife, 2):
		push_error("Expected restored block entity inventory to contain 2 kitchen_knives.")
	else:
		print("Block entity world wiring smoke test passed.")
		result = PASS

	world.free()
	restored_world.free()
	return result


func _test_game_state_save() -> int:
	var item_registry = _load_yard_registry(ITEM_YARD_REGISTRY_PATH, "item")
	var block_registry = _load_yard_registry(BLOCK_YARD_REGISTRY_PATH, "block")
	if item_registry == null or block_registry == null:
		return SKIP

	var item_resolver := func(id: StringName): return item_registry.load_entry(id)
	var block_resolver := func(id: StringName): return block_registry.load_entry(id)
	var kitchen_knife = item_registry.load_entry(&"kitchen_knife")
	var wall = block_registry.load_entry(&"prototype_wall")

	# Bundle inventory + world behind one GameState and store it through the
	# SaveSystem's single-object API.
	var game := GameStateResource.new()
	game.inventory = InventoryResource.new(4)
	game.world = WorldBlockPlacer.new()
	game.item_resolver = item_resolver
	game.block_resolver = block_resolver
	game.inventory.add_item(kitchen_knife, 1)
	game.world.place_block(wall, Vector3i(7, 0, 0))

	var save := SaveSystemResource.new()
	save.store_game(game)
	save.set_save_game("game_state_test.txt")

	var loaded := SaveSystemResource.new()
	loaded.get_save_game("game_state_test.txt")

	var restored := GameStateResource.new()
	restored.inventory = InventoryResource.new(4)
	restored.world = WorldBlockPlacer.new()
	restored.item_resolver = item_resolver
	restored.block_resolver = block_resolver
	loaded.retrieve_game(restored)

	var result := FAIL
	if not restored.inventory.has_item(kitchen_knife, 1):
		push_error("Expected restored game inventory to contain the kitchen_knife.")
	elif restored.world.get_block(Vector3i(7, 0, 0)) == null:
		push_error("Expected restored game world to contain the placed block.")
	else:
		print("Game state save smoke test passed.")
		result = PASS

	game.world.free()
	restored.world.free()
	return result


func _test_block_shapes() -> int:
	# A synthetic shapeable block (à la Clutter No More): one block, three forms.
	var block_props := BlockPropertiesResource.new()
	block_props.id = &"test_shapeable"
	block_props.shapeable = true
	block_props.default_shape = BlockPropertiesResource.BlockShape.FULL
	block_props.allowed_shapes = [
		BlockPropertiesResource.BlockShape.FULL,
		BlockPropertiesResource.BlockShape.SLAB,
		BlockPropertiesResource.BlockShape.STAIRS,
	]
	var block_resolver := func(id: StringName): return block_props if id == &"test_shapeable" else null

	var world := WorldBlockPlacer.new()
	var placed := world.place_block(block_props, Vector3i(0, 0, 0))

	var starts_full := placed.shape == BlockPropertiesResource.BlockShape.FULL
	var set_slab := world.set_block_shape(Vector3i(0, 0, 0), BlockPropertiesResource.BlockShape.SLAB)
	var slab_scale := placed.get_shape_scale()
	var rejected := placed.set_shape(BlockPropertiesResource.BlockShape.VERTICAL_SLAB)
	var cycled := world.cycle_block_shape(Vector3i(0, 0, 0))

	# Shape survives a world save round-trip.
	var restored_world := WorldBlockPlacer.new()
	restored_world.set_save_data(world.get_save_data(), block_resolver)
	var restored_shape := restored_world.get_block(Vector3i(0, 0, 0)).shape

	var result := FAIL
	if not starts_full:
		push_error("Expected a placed block to start at its default FULL shape.")
	elif not set_slab:
		push_error("Expected setting an allowed shape (SLAB) to succeed.")
	elif slab_scale != Vector3(1.0, 0.5, 1.0):
		push_error("Expected the SLAB shape to occupy the bottom half of the cell.")
	elif rejected:
		push_error("Expected a disallowed shape (VERTICAL_SLAB) to be rejected.")
	elif cycled != BlockPropertiesResource.BlockShape.STAIRS:
		push_error("Expected cycling from SLAB to advance to STAIRS.")
	elif restored_shape != BlockPropertiesResource.BlockShape.STAIRS:
		push_error("Expected the block's shape to survive a world save round-trip.")
	else:
		print("Block shapes smoke test passed.")
		result = PASS

	world.free()
	restored_world.free()
	return result


func _test_block_facing() -> int:
	# A synthetic directional block: placement + rotation + persistence.
	var block_props := BlockPropertiesResource.new()
	block_props.id = &"test_directional"
	block_props.directional = true
	block_props.default_facing = BlockPropertiesResource.BlockFacing.NORTH
	var block_resolver := func(id: StringName): return block_props if id == &"test_directional" else null

	var world := WorldBlockPlacer.new()
	var placed := world.place_block(block_props, Vector3i(0, 0, 0), Vector3.ZERO, -1, BlockPropertiesResource.BlockFacing.EAST)

	var placed_east := placed.facing == BlockPropertiesResource.BlockFacing.EAST
	# Rotation only applies once the block is in the tree, so verify the pure
	# facing->yaw helper directly.
	var east_yaw := BlockPropertiesResource.facing_yaw(BlockPropertiesResource.BlockFacing.EAST)
	# Rotate EAST -> SOUTH.
	var rotated := world.rotate_block_facing(Vector3i(0, 0, 0))

	var restored_world := WorldBlockPlacer.new()
	restored_world.set_save_data(world.get_save_data(), block_resolver)
	var restored_facing := restored_world.get_block(Vector3i(0, 0, 0)).facing

	var result := FAIL
	if not placed_east:
		push_error("Expected the block to be placed facing EAST.")
	elif not is_equal_approx(east_yaw, -PI / 2.0):
		push_error("Expected EAST facing to map to a -90 degree yaw.")
	elif rotated != BlockPropertiesResource.BlockFacing.SOUTH:
		push_error("Expected rotating from EAST to advance to SOUTH.")
	elif restored_facing != BlockPropertiesResource.BlockFacing.SOUTH:
		push_error("Expected the block's facing to survive a world save round-trip.")
	else:
		print("Block facing smoke test passed.")
		result = PASS

	world.free()
	restored_world.free()
	return result
