@tool
class_name PizzeriaFridgeItem
extends "res://scripts/placement/pizzeria_pack_prop.gd"

func get_prop_id() -> String:
	return "pizzeria_fridge"

func get_display_name() -> String:
	return "Fridge"

func _get_source_node_names() -> Array[String]:
	return ["Fridge"]
