@tool
class_name OfficeDeskItem
extends "res://scripts/placement/pizzeria_pack_prop.gd"

const DESK_COLLISION_SIZE := Vector3(3.0, 1.8, 0.94)
const DESK_FOOTPRINT_HALF_EXTENTS := Vector2(1.5, 0.5)

func get_prop_id() -> String:
	return "office_desk_computer"

func get_display_name() -> String:
	return "Office Desk + Computer"

func _get_source_node_names() -> Array[String]:
	return ["OfficeTable", "Conputer"]

func get_collision_size() -> Vector3:
	return DESK_COLLISION_SIZE

func get_footprint_half_extents() -> Vector2:
	return DESK_FOOTPRINT_HALF_EXTENTS

func can_host_surface_items() -> bool:
	return true

func get_support_surfaces() -> Array[Dictionary]:
	return [build_top_support_surface()]
