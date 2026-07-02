@tool
class_name CompositeSpriteDock extends Control

@onready var save_button: Button = $ScrollContainer/VBoxContainer/SaveButton
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var main_sprite: LineEdit = $ScrollContainer/VBoxContainer/HBoxContainer2/MainSprite
@onready var load_main_button: Button = $ScrollContainer/VBoxContainer/HBoxContainer2/LoadMainButton
@onready var add_child_sprite_button: Button = $ScrollContainer/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/AddChildSpriteButton
@onready var expendable_list: ExpendableList = $ScrollContainer/VBoxContainer/VBoxContainer/ExpendableList

var display_sprites: DisplaySprites

func connect_ds(display_sprites : DisplaySprites):	
	self.display_sprites = display_sprites		
	save_button.connect("pressed", self.pressed_save)
	save_file_dialog.connect("file_selected", self.save)	
	load_main_button.connect("pressed", self.load_main_sprite)	
	add_child_sprite_button.connect("pressed", self.load_child_sprite)
	expendable_list.display_sprites = display_sprites
	
func load_child_sprite():
	load_file_dialog.popup_file_dialog()
	load_file_dialog.connect("file_selected", self.add_child_sprite)
	pass	
	
func add_child_sprite(file_name: String):	
	expendable_list.add_new_child(file_name)	
	load_file_dialog.disconnect("file_selected", self.add_child_sprite)
	pass
	
func load_main_sprite():
	load_file_dialog.popup_file_dialog()
	load_file_dialog.connect("file_selected", self.set_main_sprite)

func set_main_sprite(file_name: String):
	display_sprites.set_main_sprite(file_name)
	main_sprite.text = file_name
	load_file_dialog.disconnect("file_selected", self.set_main_sprite)
	pass

func pressed_save():
	save_file_dialog.popup_file_dialog()	

func save(file: String):	
	display_sprites.sub_viewport.snapshot(file)
	
