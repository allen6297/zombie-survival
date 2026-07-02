extends Node3D
class_name WorldBlockPlacer

const BlockScene := preload("res://scenes/blocks/block.tscn")
const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")

@export var cell_size := 1.0
var placed_blocks: Dictionary = {}


func place_block(block_properties: BlockPropertiesResource, grid_position: Vector3i, normal: Vector3 = Vector3.ZERO) -> Block:
	if block_properties == null or placed_blocks.has(grid_position):
		return null

	var block := BlockScene.instantiate() as Block
	block.properties = block_properties
	block.position = Vector3(grid_position) * cell_size
	add_child(block)
	placed_blocks[grid_position] = block
	return block


func get_block(grid_position: Vector3i) -> Block:
	return placed_blocks.get(grid_position, null) as Block


func remove_block(grid_position: Vector3i) -> bool:
	var block := get_block(grid_position)
	if block == null:
		return false

	placed_blocks.erase(grid_position)
	block.queue_free()
	return true


func get_save_data() -> Array:
	var out: Array = []
	for grid_position in placed_blocks:
		var block: Block = placed_blocks[grid_position]
		if block != null and block.properties != null:
			out.append({
				"id": block.properties.id,
				"position": grid_position,
			})
	return out


## Restores placed blocks from [param data], clearing any existing ones first.
## [param resolver] is a [code]func(id: StringName) -> BlockProperties[/code]
## used to look block definitions up by their string id.
func set_save_data(data: Array, resolver: Callable) -> void:
	for grid_position in placed_blocks.keys():
		remove_block(grid_position)

	if not resolver.is_valid():
		return

	for entry in data:
		if not entry is Dictionary:
			continue
		var id := StringName(entry.get("id", &""))
		if id == &"":
			continue
		var properties = resolver.call(id)
		if properties != null:
			place_block(properties, entry.get("position", Vector3i.ZERO))
