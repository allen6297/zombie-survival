extends Node
class_name PlayerInventory

const InventoryResource := preload("res://scripts/inventory/Inventory.gd")
const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")

@export var inventory: InventoryResource = InventoryResource.new()


func add_item(item: ItemPropertiesResource, quantity: int = 1) -> int:
	return inventory.add_item(item, quantity)


func remove_item(item: ItemPropertiesResource, quantity: int = 1) -> int:
	return inventory.remove_item(item, quantity)
