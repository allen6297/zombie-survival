extends Node3D
## A minimal first-person place/break prototype.
##
## Controls: WASD move, Space jump, mouse look, left-click break,
## right-click place, R cycles the placed block's shape, Esc frees the mouse.

const WorldBlockPlacerScript := preload("res://scripts/world/WorldBlockPlacer.gd")
const BLOCK_REGISTRY_PATH := "res://assets/definitions/blocks/block_registry.yard.tres"

const MOVE_SPEED := 6.0
const JUMP_SPEED := 5.5
const GRAVITY := 18.0
const MOUSE_SENSITIVITY := 0.0025
const REACH := 6.0

const SHAPE_NAMES := ["FULL", "STAIRS", "SLAB", "VERTICAL_SLAB", "STEP"]

var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var ray: RayCast3D
var pitch := 0.0

var held_block: Resource
var floor_block: Resource
var held_shape := 0

var hud_label: Label


func _ready() -> void:
	_build_environment()
	_build_world()
	_build_player()
	_build_hud()
	_load_blocks()
	_build_level()

	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.shadow_enabled = true
	add_child(light)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.5, 0.7, 0.92)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	environment.ambient_light_energy = 0.7
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)


func _build_world() -> void:
	world = WorldBlockPlacerScript.new()
	add_child(world)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(6.0, 3.0, 10.0)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.7, 0.0)
	player.add_child(camera)

	ray = RayCast3D.new()
	ray.target_position = Vector3(0.0, 0.0, -REACH)
	ray.enabled = true
	camera.add_child(ray)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hud_label = Label.new()
	hud_label.position = Vector2(14.0, 12.0)
	layer.add_child(hud_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	layer.add_child(crosshair)


func _load_blocks() -> void:
	if not ResourceLoader.exists(BLOCK_REGISTRY_PATH):
		push_error("Block registry not found at %s; bake it in the YARD tab." % BLOCK_REGISTRY_PATH)
		return

	var registry = load(BLOCK_REGISTRY_PATH)
	floor_block = registry.load_entry(&"prototype_floor")
	if floor_block != null and ResourceLoader.exists("res://assets/textures/block/texture.png"):
		# Demo the connected-texture atlas on the floor.
		floor_block = floor_block.duplicate()
		floor_block.connected_texture = true
		floor_block.texture = load("res://assets/textures/block/texture.png")

	var wall = registry.load_entry(&"prototype_wall")
	if wall != null:
		# Duplicate so tweaking the held block doesn't mutate the shared
		# registry entry.
		held_block = wall.duplicate()
		held_block.shapeable = true
		held_block.directional = true
		# Placed FULL blocks use the same connected-texture atlas as the floor
		# (a connected FULL block ignores facing so its texture stays aligned).
		if ResourceLoader.exists("res://assets/textures/block/texture.png"):
			held_block.connected_texture = true
			held_block.texture = load("res://assets/textures/block/texture.png")

	_update_hud()


func _build_level() -> void:
	if floor_block != null:
		for x in range(12):
			for z in range(12):
				world.place_block(floor_block, Vector3i(x, 0, z))

	# A little starter structure to break.
	if held_block != null:
		for y in range(3):
			world.place_block(held_block, Vector3i(3, y + 1, 3))

		# Showcase real stair models facing different directions.
		var stairs := BlockProperties.BlockShape.STAIRS
		world.place_block(held_block, Vector3i(6, 1, 5), Vector3.ZERO, stairs, BlockProperties.BlockFacing.NORTH)
		world.place_block(held_block, Vector3i(7, 1, 5), Vector3.ZERO, stairs, BlockProperties.BlockFacing.EAST)
		world.place_block(held_block, Vector3i(8, 1, 5), Vector3.ZERO, stairs, BlockProperties.BlockFacing.SOUTH)


func _physics_process(delta: float) -> void:
	if player == null:
		return

	var velocity := player.velocity
	velocity.y -= GRAVITY * delta

	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction -= player.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += player.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= player.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += player.global_transform.basis.x
	direction.y = 0.0
	direction = direction.normalized()

	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED
	if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor():
		velocity.y = JUMP_SPEED

	player.velocity = velocity
	player.move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch = clampf(pitch - event.relative.y * MOUSE_SENSITIVITY, -1.4, 1.4)
		camera.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_break_targeted()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_place_targeted()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = (
				Input.MOUSE_MODE_VISIBLE
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
				else Input.MOUSE_MODE_CAPTURED
			)
		elif event.keycode == KEY_R:
			_cycle_held_shape()
		elif event.keycode == KEY_F:
			_rotate_targeted()


func _targeted_block() -> Block:
	if ray == null or not ray.is_colliding():
		return null
	var collider = ray.get_collider()
	return collider as Block


func _break_targeted() -> void:
	var block := _targeted_block()
	if block != null:
		world.remove_block(block.grid_position)


func _place_targeted() -> void:
	if held_block == null:
		return
	var block := _targeted_block()
	if block == null:
		return

	var normal: Vector3 = ray.get_collision_normal()
	var target: Vector3i = block.grid_position + Vector3i(normal.round())
	var facing := _facing_toward_player() if held_block.directional else -1
	world.place_block(held_block, target, normal, held_shape, facing)


func _rotate_targeted() -> void:
	var block := _targeted_block()
	if block != null:
		world.rotate_block_facing(block.grid_position)


## The cardinal facing whose front points back toward the player, so placed
## directional blocks face the player (like most Minecraft directional blocks).
func _facing_toward_player() -> int:
	var to_player: Vector3 = player.global_transform.basis.z
	if absf(to_player.x) > absf(to_player.z):
		return BlockProperties.BlockFacing.EAST if to_player.x > 0.0 else BlockProperties.BlockFacing.WEST
	return BlockProperties.BlockFacing.SOUTH if to_player.z > 0.0 else BlockProperties.BlockFacing.NORTH


func _cycle_held_shape() -> void:
	if held_block == null:
		return
	var allowed: Array = held_block.get_allowed_shapes()
	if allowed.is_empty():
		return
	var index := allowed.find(held_shape)
	held_shape = allowed[(index + 1) % allowed.size()] if index != -1 else allowed[0]
	_update_hud()


func _update_hud() -> void:
	if hud_label == null:
		return
	var shape_name: String = SHAPE_NAMES[held_shape] if held_shape < SHAPE_NAMES.size() else str(held_shape)
	hud_label.text = "\n".join([
		"WASD move  ·  Space jump  ·  mouse look",
		"Left-click break  ·  Right-click place (faces you)",
		"R cycle shape (%s)  ·  F rotate block  ·  Esc free mouse" % shape_name,
	])
