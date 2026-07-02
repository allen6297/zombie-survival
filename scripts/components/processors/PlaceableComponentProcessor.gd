extends "res://scripts/components/ComponentProcessor.gd"
class_name PlaceableComponentProcessor


func _init() -> void:
	handled_ids = [&"placeable"]
	handled_types = [&"placement"]


func process(component: ComponentPropertiesResource, context: InteractionContextResource) -> bool:
	if context == null:
		return false

	var block_definition = context.block
	var active_item = context.get_active_item()
	var fallback_id = active_item.id if active_item != null else &""
	context.set_result(&"place_block", component.get_value(&"block", fallback_id))
	context.set_result(&"place_position", context.target_grid_position)
	context.set_result(&"place_normal", context.target_normal)
	context.set_result(&"grid_size", int(component.get_value(&"grid_size", 1)))

	if context.world != null and context.world.has_method(&"place_block") and block_definition != null:
		var placed_block = context.world.place_block(block_definition, context.target_grid_position, context.target_normal)
		context.set_result(&"placed_block", placed_block)
		return placed_block != null

	return true
