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
	var data := {
		&"id": properties.id if properties != null else &"",
		&"block_position": block_position,
	}
	if inventory != null:
		data[&"inventory"] = inventory.get_save_data()
	return data


## Restores this block entity from [param data]. [param item_resolver] is a
## [code]func(id: StringName) -> ItemProperties[/code] used to rebuild the
## container inventory's items; pass it when the block entity has an inventory.
func set_save_data(data: Dictionary, item_resolver := Callable()) -> void:
	if data.has(&"block_position"):
		block_position = data[&"block_position"]

	if not data.has(&"inventory"):
		return

	if inventory == null:
		var slot_count: int = properties.inventory_size if properties != null and properties.has_inventory() else 1
		inventory = InventoryResource.new(slot_count)
	inventory.set_save_data(data[&"inventory"], item_resolver)


func _apply_properties() -> void:
	if properties == null:
		return

	# The container inventory is pure data, so create it as soon as the
	# properties are assigned (not gated on the node being tree-ready).
	if properties.has_inventory() and inventory == null:
		inventory = InventoryResource.new(properties.inventory_size)

	if not is_node_ready():
		return
