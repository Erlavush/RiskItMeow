class_name PlacementInventoryCatalog
extends RefCounted

const CHAIR_INITIAL_STOCK := 3
const PACK_PROP_INITIAL_STOCK := 3

const SimpleWoodChairScript := preload("res://scripts/placement/simple_wood_chair.gd")
const OfficeChairItemScript := preload("res://scripts/placement/office_chair_item.gd")
const OfficeDeskItemScript := preload("res://scripts/placement/office_desk_item.gd")
const PizzeriaFridgeItemScript := preload("res://scripts/placement/pizzeria_fridge_item.gd")
const SmallShelfItemScript := preload("res://scripts/placement/small_shelf_item.gd")
const DoubleBedItemScript := preload("res://scripts/placement/double_bed_item.gd")
const WindowItemScript := preload("res://scripts/placement/window_item.gd")
const ClassicWindowItemScript := preload("res://scripts/placement/classic_window_item.gd")

static func build_item_defs() -> Array[Dictionary]:
	return [
		{
			"id": "simple_wood_chair",
			"display_name": "Simple Wood Chair",
			"script": SimpleWoodChairScript,
			"initial_stock": CHAIR_INITIAL_STOCK,
		},
		{
			"id": "office_chair",
			"display_name": "Office Chair",
			"script": OfficeChairItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
		{
			"id": "office_desk_computer",
			"display_name": "Office Desk + Computer",
			"script": OfficeDeskItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
		{
			"id": "pizzeria_fridge",
			"display_name": "Fridge",
			"script": PizzeriaFridgeItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
		{
			"id": "small_shelf",
			"display_name": "Small Shelf",
			"script": SmallShelfItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
		{
			"id": "double_bed",
			"display_name": "Double Bed",
			"script": DoubleBedItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
		{
			"id": "window",
			"display_name": "Window",
			"script": WindowItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
		{
			"id": "window_classic",
			"display_name": "Window (Classic)",
			"script": ClassicWindowItemScript,
			"initial_stock": PACK_PROP_INITIAL_STOCK,
		},
	]

static func find_item_definition(item_defs: Array[Dictionary], item_id: String) -> Dictionary:
	for item_def in item_defs:
		if String(item_def.get("id", "")) == item_id:
			return item_def
	return {}

static func get_item_script(item_def: Dictionary) -> Script:
	return item_def.get("script", null) as Script

static func get_item_display_name(item_defs: Array[Dictionary], item_id: String) -> String:
	var item_def := find_item_definition(item_defs, item_id)
	return String(item_def.get("display_name", item_id))

static func has_any_stock(item_defs: Array[Dictionary], item_stock: Dictionary) -> bool:
	for item_def in item_defs:
		var item_id := String(item_def.get("id", ""))
		if int(item_stock.get(item_id, 0)) > 0:
			return true
	return false
