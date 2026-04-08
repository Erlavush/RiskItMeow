@tool
class_name PizzeriaFridgeItem
extends "res://scripts/placement/pizzeria_pack_prop.gd"

func get_prop_id() -> String:
	return "pizzeria_fridge"

func get_display_name() -> String:
	return "Fridge"

func _get_source_node_names() -> Array[String]:
	return ["Fridge"]

func can_host_surface_items() -> bool:
	return true

func get_support_surfaces() -> Array[Dictionary]:
	return [build_top_support_surface()]
