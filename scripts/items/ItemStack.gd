extends Resource
class_name ItemStack

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")

@export var item: ItemPropertiesResource
@export_range(0.0, 999.0, 1.0) var quantity: int = 1
@export var component_state: Dictionary = {}


func _init(item_properties: ItemPropertiesResource = null, item_quantity: int = 1) -> void:
	item = item_properties
	quantity = item_quantity if item_quantity > 0 else 0


func is_empty() -> bool:
	return item == null or quantity <= 0


func get_component_state(component_id: StringName) -> Dictionary:
	var key := String(component_id)
	if not component_state.has(key):
		component_state[key] = {}
	return component_state[key]


func set_component_value(component_id: StringName, key: StringName, value: Variant) -> void:
	get_component_state(component_id)[String(key)] = value


func get_component_value(component_id: StringName, key: StringName, default_value: Variant = null) -> Variant:
	return get_component_state(component_id).get(String(key), default_value)


func consume(amount: int = 1) -> bool:
	if amount <= 0 or quantity < amount:
		return false

	quantity -= amount
	return true


func get_save_data() -> Dictionary:
	return {
		"id": item.id if item != null else &"",
		"quantity": quantity,
		"component_state": component_state,
	}


func set_save_data(data: Dictionary, resolved_item: ItemPropertiesResource) -> void:
	item = resolved_item
	quantity = int(data.get("quantity", 0))
	var raw_state = data.get("component_state", {})
	component_state = raw_state if raw_state is Dictionary else {}
