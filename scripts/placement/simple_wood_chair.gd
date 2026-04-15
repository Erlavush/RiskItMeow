@tool
class_name SimpleWoodChair
extends PlaceableItem

const DISPLAY_NAME := "Simple Wood Chair"
const VISUAL_SCENE_PATH := "res://assets/props/simple_wood_chair/scene.gltf"
const VISUAL_SCALE := Vector3.ONE * 0.25
const VISUAL_Y_OFFSET := 0.275
const COLLISION_SIZE := Vector3(0.9, 1.5, 0.9)

func get_display_name() -> String:
	return DISPLAY_NAME

func get_visual_scene_path() -> String:
	return VISUAL_SCENE_PATH

func get_visual_scale() -> Vector3:
	return VISUAL_SCALE

func get_visual_y_offset() -> float:
	return VISUAL_Y_OFFSET

func get_collision_size() -> Vector3:
	return COLLISION_SIZE

func _create_fallback_visual() -> void:
	var wood_color := Color(0.57, 0.35, 0.17, 1.0)
	_add_box_piece(Vector3(0.9, 0.12, 0.9), Vector3(0.0, 0.78, 0.0), wood_color)
	_add_box_piece(Vector3(0.9, 0.82, 0.12), Vector3(0.0, 1.18, -0.39), wood_color)
	_add_box_piece(Vector3(0.12, 0.78, 0.12), Vector3(-0.34, 0.39, -0.34), wood_color)
	_add_box_piece(Vector3(0.12, 0.78, 0.12), Vector3(0.34, 0.39, -0.34), wood_color)
	_add_box_piece(Vector3(0.12, 0.78, 0.12), Vector3(-0.34, 0.39, 0.34), wood_color)
	_add_box_piece(Vector3(0.12, 0.78, 0.12), Vector3(0.34, 0.39, 0.34), wood_color)
