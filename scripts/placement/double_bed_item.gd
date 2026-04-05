@tool
class_name DoubleBedItem
extends "res://scripts/placement/imported_glb_prop.gd"

const BED_COLLISION_SIZE := Vector3(1.94, 1.0, 2.0)

func get_prop_id() -> String:
	return "double_bed"

func get_display_name() -> String:
	return "Double Bed"

func get_source_scene_path() -> String:
	return "res://assets/props/double_bed/double_bed.glb"

func get_collision_size() -> Vector3:
	return BED_COLLISION_SIZE
