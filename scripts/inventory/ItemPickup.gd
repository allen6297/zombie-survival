extends Area3D
class_name ItemPickup

const ItemPropertiesResource := preload("res://scripts/items/ItemProperties.gd")
const PlayerInventoryNode := preload("res://scripts/inventory/PlayerInventory.gd")

@export var item: ItemPropertiesResource
@export_range(1.0, 999.0, 1.0) var quantity: int = 1
@export var auto_pickup := true


func _ready() -> void:
	if auto_pickup:
		body_entered.connect(_on_body_entered)


func collect(inventory_owner: Node) -> bool:
	if item == null:
		return false

	var inventory: PlayerInventoryNode = _find_inventory(inventory_owner)
	if inventory == null:
		return false

	var remainder: int = inventory.add_item(item, quantity)
	if remainder == 0:
		queue_free()
		return true

	quantity = remainder
	return false


func _on_body_entered(body: Node) -> void:
	collect(body)


func _find_inventory(node: Node) -> PlayerInventoryNode:
	if node is PlayerInventoryNode:
		return node

	if node.has_node("PlayerInventory"):
		var child := node.get_node("PlayerInventory")
		if child is PlayerInventoryNode:
			return child

	for child in node.get_children():
		if child is PlayerInventoryNode:
			return child

	return null
