extends Resource
class_name MinecraftModelJson

@export var source_path: String
@export var parent: String
@export var textures: Dictionary = {}
@export var elements: Array = []
@export var display: Dictionary = {}
@export var texture_root := "res://assets/textures/minecraft/block"


static func load_from_file(path: String) -> MinecraftModelJson:
	var model := MinecraftModelJson.new()
	model.source_path = path

	if not FileAccess.file_exists(path):
		push_error("Minecraft model JSON does not exist: %s" % path)
		return model

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to read Minecraft model JSON: %s" % path)
		return model

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Minecraft model JSON must contain an object: %s" % path)
		return model

	model.parent = str(parsed.get("parent", ""))
	model.textures = parsed.get("textures", {})
	model.elements = parsed.get("elements", [])
	model.display = parsed.get("display", {})
	return model


func get_texture(slot: StringName) -> String:
	return str(textures.get(String(slot), ""))


func get_texture_path(slot: StringName) -> String:
	return resolve_texture_reference(get_texture(slot))


func load_texture(slot: StringName) -> Texture2D:
	var path := get_texture_path(slot)
	if path.is_empty():
		return null

	var imported_texture := load(path) as Texture2D
	if imported_texture != null:
		return imported_texture

	var image := Image.load_from_file(path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func has_inline_geometry() -> bool:
	return not elements.is_empty()


func is_parent_template() -> bool:
	return not parent.is_empty() and elements.is_empty()


func is_crop_model() -> bool:
	return parent == "minecraft:block/crop"


func resolve_texture_reference(reference: String) -> String:
	if reference.is_empty():
		return ""
	if reference.begins_with("res://") or reference.begins_with("user://"):
		return reference

	var texture_id := reference
	if texture_id.begins_with("#"):
		texture_id = get_texture(StringName(texture_id.trim_prefix("#")))

	# All references (minecraft:block/..., minecraft:item/..., or a bare name)
	# resolve to a PNG under texture_root using just the file name.
	return "%s/%s.png" % [texture_root, texture_id.get_file()]
