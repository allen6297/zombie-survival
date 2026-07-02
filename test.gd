extends SceneTree

# To run this script:
# godot --headless --path . -s test.gd

const InventoryResource = preload("res://scripts/inventory/Inventory.gd")
const KITCHEN_KNIFE = preload("res://assets/definitions/items/knives/kitchen_knife.tres")
const ITEM_REGISTRY = preload("res://assets/definitions/items/item_registry.tres")
const BLOCK_REGISTRY = preload("res://assets/definitions/blocks/block_registry.tres")
const ENTITY_REGISTRY = preload("res://assets/definitions/entities/entity_registry.tres")
const BLOCK_ENTITY_REGISTRY = preload("res://assets/definitions/block_entities/block_entity_registry.tres")
const JsonDefinitionLoader = preload("res://scripts/registry/JsonDefinitionLoader.gd")
const MinecraftModelJson = preload("res://scripts/models/MinecraftModelJson.gd")
const ItemNode = preload("res://scripts/items/Item.gd")
const ItemStack = preload("res://scripts/items/ItemStack.gd")
const InteractionContext = preload("res://scripts/components/InteractionContext.gd")
const BlockNode = preload("res://scripts/blocks/Block.gd")
const WorldBlockPlacer = preload("res://scripts/world/WorldBlockPlacer.gd")

var _passed := 0
var _failed := 0


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
	]

	for test in tests:
		if test.call():
			_passed += 1
		else:
			_failed += 1

	print("Smoke tests finished: %d passed, %d failed." % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_inventory() -> bool:
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
		return true
	return false


func _test_item_registry() -> bool:
	var kitchen_knife = ITEM_REGISTRY.get_item(&"kitchen_knife")
	var chef_knife = ITEM_REGISTRY.get_item(&"chef_knife")

	if kitchen_knife == null:
		push_error("Expected kitchen_knife in the item registry.")
	elif chef_knife == null:
		push_error("Expected chef_knife in the item registry.")
	elif kitchen_knife.stack_size != 1:
		push_error("Expected kitchen_knife to be non-stackable.")
	else:
		print("Item registry smoke test passed.")
		return true
	return false


func _test_block_registry() -> bool:
	var floor_block = BLOCK_REGISTRY.get_block(&"prototype_floor")
	var wall_block = BLOCK_REGISTRY.get_block(&"prototype_wall")

	if floor_block == null:
		push_error("Expected prototype_floor in the block registry.")
	elif wall_block == null:
		push_error("Expected prototype_wall in the block registry.")
	elif not wall_block.is_solid():
		push_error("Expected prototype_wall to be solid.")
	else:
		print("Block registry smoke test passed.")
		return true
	return false


func _test_entity_registry() -> bool:
	var entity = ENTITY_REGISTRY.get_entity(&"prototype_entity")

	if entity == null:
		push_error("Expected prototype_entity in the entity registry.")
	elif not entity.is_alive_health(entity.max_health):
		push_error("Expected prototype_entity max health to be alive.")
	else:
		print("Entity registry smoke test passed.")
		return true
	return false


func _test_block_entity_registry() -> bool:
	var block_entity = BLOCK_ENTITY_REGISTRY.get_block_entity(&"container_block_entity")

	if block_entity == null:
		push_error("Expected container_block_entity in the block entity registry.")
	elif not block_entity.has_inventory():
		push_error("Expected container_block_entity to have inventory.")
	else:
		print("Block entity registry smoke test passed.")
		return true
	return false


func _test_json_definitions() -> bool:
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
		return true
	return false


func _test_item_use_pipeline() -> bool:
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
		return true
	return false


func _test_item_stack_runtime_state() -> bool:
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
		return true
	return false


func _test_world_block_placement() -> bool:
	var world := WorldBlockPlacer.new()
	var context := InteractionContext.new()
	var wall_block = BLOCK_REGISTRY.get_block(&"prototype_wall")
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
		return true
	return false


func _test_block_interaction_pipeline() -> bool:
	var block := BlockNode.new()
	var world := WorldBlockPlacer.new()
	var context := InteractionContext.new()
	block.properties = BLOCK_REGISTRY.get_block(&"prototype_wall")
	context.world = world
	context.target_grid_position = Vector3i(3, 0, 0)

	var interacted := block.interact(context)

	if not interacted:
		push_error("Expected prototype_wall block interaction to be handled.")
	elif context.get_result(&"place_position") != Vector3i(3, 0, 0):
		push_error("Expected block interaction to populate placement position.")
	else:
		print("Block interaction pipeline smoke test passed.")
		return true
	return false


func _test_minecraft_model_json() -> bool:
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
		return true
	return false
