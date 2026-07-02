@icon ("res://addons/at-icons/node3d/human.svg")
extends CharacterBody3D
class_name Entity

const EntityPropertiesResource := preload("res://scripts/entities/EntityProperties.gd")

@export var properties: EntityPropertiesResource:
	set(value):
		properties = value
		_apply_properties()

# Runtime-only: reset to properties.max_health in _apply_properties().
var current_health: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_apply_properties()


func damage(amount: float) -> bool:
	if properties == null or not properties.can_take_damage or amount <= 0.0:
		return false

	current_health -= amount
	if current_health <= 0.0:
		die()
		return true

	return false


func heal(amount: float) -> void:
	if properties == null or amount <= 0.0:
		return

	current_health += amount
	if current_health > properties.max_health:
		current_health = properties.max_health


func die() -> void:
	queue_free()


func _apply_properties() -> void:
	if not is_node_ready() or properties == null:
		return

	current_health = properties.max_health

	if properties.texture != null:
		var material := StandardMaterial3D.new()
		material.albedo_texture = properties.texture
		mesh_instance.set_surface_override_material(0, material)
