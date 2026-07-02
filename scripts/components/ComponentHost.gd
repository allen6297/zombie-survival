extends RefCounted
class_name ComponentHost


static func get_component(components: Array, id: StringName) -> ComponentProperties:
	for component in components:
		if component != null and component.id == id:
			return component

	return null


static func has_component(components: Array, id: StringName) -> bool:
	return get_component(components, id) != null


static func get_components_by_type(components: Array, type: StringName) -> Array[ComponentProperties]:
	var matching: Array[ComponentProperties] = []

	for component in components:
		if component != null and component.type == type:
			matching.append(component)

	return matching
