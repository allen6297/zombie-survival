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
