@tool
class_name ExpendableList extends VBoxContainer

var display_sprites: DisplaySprites
var children: Array[ChildSpriteRow] = []


func add_new_child(file_name: String):
	var child_item: ChildSpriteRow = preload("res://addons/compositespritesheetgenerator/dock/child_sprite_row.tscn").instantiate()		
	add_child(child_item)
	child_item.child_file.text = file_name
	child_item.index = children.size()
	child_item.parent = self	
	children.append(child_item)
	display_sprites.add_child_sprite(file_name)	
	pass

func remove_sprite(index: int):
	display_sprites.delete_child_sprite(index)
	remove_child(children[index])
	children[index].queue_free()
	children.remove_at(index)
	for new_index in children.size():
		children[new_index].index = new_index
	pass

func change_sprite_z_index(sprite_index: int, z_index: int):
	display_sprites.set_sprite_index(sprite_index, z_index)
	
func set_sprite_x_offset(sprite_index: int, offset: int):
	display_sprites.set_sprite_x_offset(sprite_index, offset)

func set_sprite_y_offset(sprite_index: int, offset: int):
	display_sprites.set_sprite_y_offset(sprite_index, offset)
