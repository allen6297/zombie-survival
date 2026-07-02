extends Resource
class_name Inventory

const InventorySlotResource := preload("res://scripts/inventory/InventorySlot.gd")
const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")

@export_range(1.0, 128.0, 1.0) var size: int = 16:
	set(value):
		size = value if value > 0 else 1
		_resize_slots()

@export var slots: Array[InventorySlotResource] = []


func _init(slot_count: int = 16) -> void:
	size = slot_count
	_resize_slots()


func add_item(item: ItemPropertiesResource, quantity: int = 1) -> int:
	if item == null or quantity <= 0:
		return quantity

	var remaining := quantity

	for slot in slots:
		if slot.can_stack(item):
			remaining = slot.add(remaining)
			if remaining == 0:
				return 0

	for slot in slots:
		if slot.is_empty():
			slot.item = item
			slot.quantity = remaining if remaining < item.stack_size else item.stack_size
			remaining -= slot.quantity
			if remaining == 0:
				return 0

	return remaining


func remove_item(item: ItemPropertiesResource, quantity: int = 1) -> int:
	if item == null or quantity <= 0:
		return 0

	var removed := 0

	for slot in slots:
		if slot.item != item:
			continue

		var needed := quantity - removed
		var amount := needed if needed < slot.quantity else slot.quantity
		slot.quantity -= amount
		removed += amount

		if slot.quantity <= 0:
			slot.clear()
		if removed == quantity:
			return removed

	return removed


func has_item(item: ItemPropertiesResource, quantity: int = 1) -> bool:
	if item == null:
		return false

	var found := 0
	for slot in slots:
		if slot.item == item:
			found += slot.quantity
			if found >= quantity:
				return true

	return false


func get_save_data() -> Dictionary:
	var slot_data: Array = []
	for slot in slots:
		slot_data.append(slot.get_save_data())
	return {
		"size": size,
		"slots": slot_data,
	}


## Restores the inventory from [param data]. [param resolver] is a
## [code]func(id: StringName) -> ItemProperties[/code] passed through to each
## slot to resolve item ids back into resources.
func set_save_data(data: Dictionary, resolver: Callable) -> void:
	size = int(data.get("size", size))

	var slot_data = data.get("slots", [])
	if not slot_data is Array:
		return

	for i in range(min(slots.size(), slot_data.size())):
		var entry = slot_data[i]
		if entry is Dictionary:
			slots[i].set_save_data(entry, resolver)
		else:
			slots[i].clear()


func _resize_slots() -> void:
	while slots.size() < size:
		slots.append(InventorySlotResource.new())

	while slots.size() > size:
		slots.pop_back()
