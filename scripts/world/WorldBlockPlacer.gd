extends Node3D
class_name WorldBlockPlacer

const BlockScene := preload("res://scenes/blocks/block.tscn")
const BlockEntityScene := preload("res://scenes/block_entities/block_entity.tscn")
const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")

@export var cell_size := 1.0
var placed_blocks: Dictionary = {}
var block_entities: Dictionary = {}


func place_block(block_properties: BlockPropertiesResource, grid_position: Vector3i, normal: Vector3 = Vector3.ZERO) -> Block:
	if block_properties == null or placed_blocks.has(grid_position):
		return null

	var block := BlockScene.instantiate() as Block
	block.properties = block_properties
	block.position = Vector3(grid_position) * cell_size
	add_child(block)
	placed_blocks[grid_position] = block

	if block_properties.has_block_entity():
		var block_entity := BlockEntityScene.instantiate() as BlockEntity
		block_entity.properties = block_properties.block_entity
		block_entity.block_position = grid_position
		block.add_child(block_entity)
		block_entities[grid_position] = block_entity

	return block


func get_block(grid_position: Vector3i) -> Block:
	return placed_blocks.get(grid_position, null) as Block


func get_block_entity(grid_position: Vector3i) -> BlockEntity:
	return block_entities.get(grid_position, null) as BlockEntity


func remove_block(grid_position: Vector3i) -> bool:
	var block := get_block(grid_position)
	if block == null:
		return false

	placed_blocks.erase(grid_position)
	block_entities.erase(grid_position)
	block.queue_free()
	return true


func get_save_data() -> Array:
	var out: Array = []
	for grid_position in placed_blocks:
		var block: Block = placed_blocks[grid_position]
		if block == null or block.properties == null:
			continue
		var entry := {
			"id": block.properties.id,
			"position": grid_position,
		}
		var block_entity := get_block_entity(grid_position)
		if block_entity != null:
			entry["block_entity"] = block_entity.get_save_data()
		out.append(entry)
	return out


## Restores placed blocks from [param data], clearing any existing ones first.
## [param block_resolver] is a [code]func(id: StringName) -> BlockProperties[/code].
## [param item_resolver] (optional) is passed to any spawned block entity to
## rebuild its container inventory.
func set_save_data(data: Array, block_resolver: Callable, item_resolver := Callable()) -> void:
	for grid_position in placed_blocks.keys():
		remove_block(grid_position)

	if not block_resolver.is_valid():
		return

	for entry in data:
		if not entry is Dictionary:
			continue
		var id := StringName(entry.get("id", &""))
		if id == &"":
			continue
		var properties = block_resolver.call(id)
		if properties == null:
			continue

		var grid_position: Vector3i = entry.get("position", Vector3i.ZERO)
		place_block(properties, grid_position)

		if entry.has("block_entity"):
			var block_entity := get_block_entity(grid_position)
			if block_entity != null:
				block_entity.set_save_data(entry["block_entity"], item_resolver)
