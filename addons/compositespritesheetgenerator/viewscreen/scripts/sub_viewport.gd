@tool
extends SubViewport

@onready var spritesheet_view = $"../SpriteSheetMainView"

var viewportSprite: Node2D
var file_name: String

func snapshot(file_name: String):
	self.file_name = file_name	
	viewportSprite = spritesheet_view.duplicate()
	add_child(viewportSprite)
	size = viewportSprite.texture.get_size() 
	render_target_update_mode = SubViewport.UPDATE_ONCE
	RenderingServer.frame_post_draw.connect(saveImage)
	pass
	
func saveImage():	
	var image: Image = get_texture().get_image()
	image.save_png(file_name)		
	RenderingServer.frame_post_draw.disconnect(saveImage)
	EditorInterface.get_resource_filesystem().scan()
	remove_child(viewportSprite)
	viewportSprite.free()
	pass	
