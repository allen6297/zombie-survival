@tool
class_name DisplaySprites extends Node2D

@onready var sprite_sheet_main_view: Sprite2D = $SpriteSheetMainView
@onready var sub_viewport: SubViewport = $SubViewport

var child_sprites: Array[Sprite2D] = []

func delete_child_sprite(sprite_index: int):
	child_sprites[sprite_index].queue_free()
	child_sprites.remove_at(sprite_index)

func add_child_sprite(file_name: String):
	var child_sprite: Sprite2D = Sprite2D.new()
	child_sprite.texture = load(file_name)
	sprite_sheet_main_view.add_child(child_sprite)
	child_sprites.append(child_sprite)

func set_main_sprite(file_name: String):
	sprite_sheet_main_view.texture = load(file_name)
	sprite_sheet_main_view.position = sprite_sheet_main_view.texture.get_size() / 2

func set_sprite_index(sprite_index: int, z_index: int):
	child_sprites[sprite_index].z_index = z_index

func set_sprite_x_offset(sprite_index: int, offset: int):
	child_sprites[sprite_index].position.x = offset

func set_sprite_y_offset(sprite_index: int, offset: int):
	child_sprites[sprite_index].position.y = offset
