@tool
class_name CompositeSpriteSheetGenerator extends EditorPlugin

var display_sprites_instance: DisplaySprites
var composite_sprite_dock: EditorDock

func _enter_tree():
	display_sprites_instance = preload("res://addons/compositespritesheetgenerator/viewscreen/display_sprites.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(display_sprites_instance)
	_make_visible(false)

	var composite_sprite_dock_scene: CompositeSpriteDock = preload("res://addons/compositespritesheetgenerator/dock/composite_sprite_dock.tscn").instantiate()
	composite_sprite_dock = EditorDock.new()
	composite_sprite_dock.add_child(composite_sprite_dock_scene)
	composite_sprite_dock.title = "Composite Sprite Creator"
	composite_sprite_dock.default_slot = EditorDock.DOCK_SLOT_LEFT_UR
	composite_sprite_dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(composite_sprite_dock)
	composite_sprite_dock_scene.connect_ds(display_sprites_instance)

func _exit_tree():
	if display_sprites_instance:
		display_sprites_instance.queue_free()
	if composite_sprite_dock:
		remove_dock(composite_sprite_dock)
		composite_sprite_dock.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible: bool) -> void:
	if display_sprites_instance:
		display_sprites_instance.visible = visible

func _get_plugin_name():
	return "Composite Sprite Creator"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
