@tool
class_name OfficeChairItem
extends "res://scripts/placement/pizzeria_pack_prop.gd"

func get_prop_id() -> String:
	return "office_chair"

func get_display_name() -> String:
	return "Office Chair"

func _get_source_node_names() -> Array[String]:
	return ["OfficeChair"]
