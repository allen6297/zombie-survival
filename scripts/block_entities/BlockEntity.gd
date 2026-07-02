extends Node3D
class_name BlockEntity

const BlockEntityPropertiesResource := preload("res://scripts/block_entities/BlockEntityProperties.gd")
const InventoryResource := preload("res://scripts/inventory/Inventory.gd")

@export var properties: BlockEntityPropertiesResource:
	set(value):
		properties = value
		_apply_properties()

@export var block_position: Vector3i = Vector3i.ZERO
@export var inventory: InventoryResource


func _ready() -> void:
	_apply_properties()


func get_save_data() -> Dictionary:
	return {
		&"id": properties.id if properties != null else &"",
		&"block_position": block_position,
	}


func set_save_data(data: Dictionary) -> void:
	if data.has(&"block_position"):
		block_position = data[&"block_position"]


func _apply_properties() -> void:
	if not is_node_ready() or properties == null:
		return

	if properties.has_inventory() and inventory == null:
		inventory = InventoryResource.new(properties.inventory_size)
