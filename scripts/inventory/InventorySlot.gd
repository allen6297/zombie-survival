extends Resource
class_name InventorySlot

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")

@export var item: ItemPropertiesResource
@export var quantity: int = 0


func is_empty() -> bool:
	return item == null or quantity <= 0


func can_stack(other_item: ItemPropertiesResource) -> bool:
	return not is_empty() and item == other_item and quantity < item.stack_size


func remaining_capacity() -> int:
	if is_empty():
		return 0
	var capacity := item.stack_size - quantity
	return capacity if capacity > 0 else 0


func add(amount: int) -> int:
	if is_empty() or amount <= 0:
		return amount

	var capacity := remaining_capacity()
	var accepted := amount if amount < capacity else capacity
	quantity += accepted
	return amount - accepted


func clear() -> void:
	item = null
	quantity = 0


func get_save_data() -> Dictionary:
	if is_empty():
		return {}
	return {
		"id": item.id,
		"quantity": quantity,
	}


## Restores this slot from [param data]. [param resolver] is a
## [code]func(id: StringName) -> ItemProperties[/code] used to look the item up
## by its string id (e.g. a YARD registry's [code]load_entry[/code]).
func set_save_data(data: Dictionary, resolver: Callable) -> void:
	var id := StringName(data.get("id", &""))
	if id == &"" or not resolver.is_valid():
		clear()
		return

	item = resolver.call(id)
	quantity = int(data.get("quantity", 0))
	if item == null or quantity <= 0:
		clear()
