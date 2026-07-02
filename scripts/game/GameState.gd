extends RefCounted
class_name GameState

## Aggregates the savable game objects behind a single get_save_data() /
## set_save_data() pair, matching the object API expected by
## [SaveSystem.store_game] / [SaveSystem.retrieve_game].
##
## The resolvers ([code]func(id: StringName) -> Resource[/code]) let this state
## rebuild items and blocks from their string ids on load, so the SaveSystem
## never has to know about registries.

const InventoryResource := preload("res://scripts/inventory/Inventory.gd")
const WorldBlockPlacerResource := preload("res://scripts/world/WorldBlockPlacer.gd")

var inventory: InventoryResource
var world: WorldBlockPlacerResource
var item_resolver := Callable()
var block_resolver := Callable()


func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	if inventory != null:
		data["inventory"] = inventory.get_save_data()
	if world != null:
		data["world"] = world.get_save_data()
	return data


func set_save_data(data: Dictionary) -> void:
	if inventory != null and data.has("inventory"):
		inventory.set_save_data(data["inventory"], item_resolver)
	if world != null and data.has("world"):
		world.set_save_data(data["world"], block_resolver, item_resolver)
