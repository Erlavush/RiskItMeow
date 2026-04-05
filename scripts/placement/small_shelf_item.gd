@tool
class_name SmallShelfItem
extends "res://scripts/placement/imported_glb_prop.gd"

func get_prop_id() -> String:
	return "small_shelf"

func get_display_name() -> String:
	return "Small Shelf"

func get_source_scene_path() -> String:
	return "res://assets/props/small_shelf/small_shelf.glb"
