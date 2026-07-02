extends Resource
class_name InteractionContext

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")
const ItemStackResource := preload("res://scripts/items/ItemStack.gd")
const BlockPropertiesResource := preload("res://scripts/blocks/BlockProperties.gd")

var actor: Node
var source: Node
var target: Node
var world: Node
var inventory: Resource
@export var item: ItemPropertiesResource
@export var item_stack: ItemStackResource
@export var block: BlockPropertiesResource
@export var target_position: Vector3 = Vector3.ZERO
@export var target_grid_position: Vector3i = Vector3i.ZERO
@export var target_normal: Vector3 = Vector3.ZERO
@export var data: Dictionary = {}
@export var results: Dictionary = {}


func set_value(key: StringName, value: Variant) -> void:
	data[String(key)] = value


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return data.get(String(key), default_value)


func set_result(key: StringName, value: Variant) -> void:
	results[String(key)] = value


func get_result(key: StringName, default_value: Variant = null) -> Variant:
	return results.get(String(key), default_value)


func get_active_item() -> ItemPropertiesResource:
	if item_stack != null:
		return item_stack.item
	return item
