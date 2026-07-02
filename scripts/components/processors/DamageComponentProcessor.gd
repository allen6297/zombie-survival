extends "res://scripts/components/ComponentProcessor.gd"
class_name DamageComponentProcessor


func _init() -> void:
	handled_ids = [&"damage"]
	handled_types = [&"combat"]


func process(component: ComponentPropertiesResource, context: InteractionContextResource) -> bool:
	if context == null or context.target == null or not context.target.has_method(&"damage"):
		return false

	var amount := float(component.get_value(&"amount", 0.0))
	if amount <= 0.0:
		return false

	var defeated = context.target.damage(amount)
	context.set_result(&"damage_amount", amount)
	context.set_result(&"damage_type", component.get_value(&"damage_type", "generic"))
	context.set_result(&"target_defeated", defeated)
	return true
