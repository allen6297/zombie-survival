@tool
class_name ChildSpriteRow extends VBoxContainer

@onready var child_file: LineEdit = $HBoxContainer/ChildFile
@onready var z_index_spin : SpinBox = $HBoxContainer/ZIndex
@onready var delete_button: Button = $HBoxContainer/DeleteButton
@onready var x_offset: SpinBox = $HBoxContainer2/XOffset
@onready var y_offset: SpinBox = $HBoxContainer2/YOffset

var index: int
var parent: ExpendableList
	
func delete():
	parent.remove_sprite(index)
	
func change_z_index(value: float):
	parent.change_sprite_z_index(index, z_index_spin.value)		

func change_x_offset(value: float):
	parent.set_sprite_x_offset(index, value)

func change_y_offset(value: float):
	parent.set_sprite_y_offset(index, value)		
