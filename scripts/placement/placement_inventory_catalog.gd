class_name PlacementInventoryCatalog
extends RefCounted

const RoomConstants := preload("res://scripts/room/room_constants.gd")

const LEGACY_INITIAL_OWNED := 3
const IMPORTED_INITIAL_OWNED := 0
const IMPORT_ROOT := "res://assets/props/low_poly_household"
const IMPORTED_FACTORY_TYPE := "imported_scene"

const SimpleWoodChairScript := preload("res://scripts/placement/simple_wood_chair.gd")
const OfficeChairItemScript := preload("res://scripts/placement/office_chair_item.gd")
const OfficeDeskItemScript := preload("res://scripts/placement/office_desk_item.gd")
const PizzeriaFridgeItemScript := preload("res://scripts/placement/pizzeria_fridge_item.gd")
const SmallShelfItemScript := preload("res://scripts/placement/small_shelf_item.gd")
const DoubleBedItemScript := preload("res://scripts/placement/double_bed_item.gd")
const WindowItemScript := preload("res://scripts/placement/window_item.gd")
const ClassicWindowItemScript := preload("res://scripts/placement/classic_window_item.gd")
const ImportedScenePlaceableScript := preload("res://scripts/placement/imported_scene_placeable.gd")

const CATEGORY_ORDER := [
	"Beds",
	"Chairs",
	"Tables",
	"Sofas",
	"Shelves",
	"Drawers",
	"Kitchen",
	"Bathroom",
	"Electronics",
	"Lights",
	"Windows",
	"Doors",
	"Carpets",
	"Miscellaneous",
]

const WALL_DECOR_NAME_HINTS := [
	"wall shelf",
	"wall light",
	"light switch",
	"mirror",
	"clock",
	"socket",
	"vent",
	"radiator",
	"curtains",
	"towel holder",
	"toilet roll holder",
]

const IMPORTED_CATEGORY_SCALE_OVERRIDES := {
	"Bathroom": 0.26,
	"Beds": 0.24,
	"Carpets": 0.22,
	"Chairs": 0.3,
	"Doors": 0.24,
	"Drawers": 0.26,
	"Electronics": 0.28,
	"Kitchen": 0.26,
	"Lights": 0.24,
	"Miscellaneous": 0.28,
	"Shelves": 0.28,
	"Sofas": 0.24,
	"Tables": 0.26,
	"Windows": 0.24,
}

static func build_item_defs() -> Array[Dictionary]:
	var item_defs: Array[Dictionary] = []
	item_defs.append_array(_build_legacy_item_defs())
	item_defs.append_array(_build_imported_pack_item_defs())
	item_defs.sort_custom(_sort_item_defs)
	return item_defs

static func build_category_names(item_defs: Array[Dictionary]) -> Array[String]:
	var seen: Dictionary = {}
	var categories: Array[String] = []
	for item_def in item_defs:
		var category := String(item_def.get("category", "Miscellaneous"))
		if seen.has(category):
			continue
		seen[category] = true
		categories.append(category)
	categories.sort_custom(_sort_categories)
	return categories

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

static func get_item_category(item_defs: Array[Dictionary], item_id: String) -> String:
	var item_def := find_item_definition(item_defs, item_id)
	return String(item_def.get("category", "Miscellaneous"))

static func get_initial_owned(item_def: Dictionary) -> int:
	return int(item_def.get("initial_owned", item_def.get("initial_stock", 0)))

static func has_any_stock(item_defs: Array[Dictionary], item_stock: Dictionary) -> bool:
	for item_def in item_defs:
		var item_id := String(item_def.get("id", ""))
		if int(item_stock.get(item_id, 0)) > 0:
			return true
	return false

static func uses_imported_scene_factory(item_def: Dictionary) -> bool:
	return String(item_def.get("factory_type", "")) == IMPORTED_FACTORY_TYPE

static func create_imported_scene_instance(item_def: Dictionary):
	var placeable := ImportedScenePlaceableScript.new()
	if placeable != null:
		placeable.configure_from_item_def(item_def)
	return placeable

static func _build_legacy_item_defs() -> Array[Dictionary]:
	return [
		_build_script_item_def("simple_wood_chair", "Simple Wood Chair", "Chairs", SimpleWoodChairScript, LEGACY_INITIAL_OWNED),
		_build_script_item_def("office_chair", "Office Chair", "Chairs", OfficeChairItemScript, LEGACY_INITIAL_OWNED),
		_build_script_item_def("office_desk_computer", "Office Desk + Computer", "Tables", OfficeDeskItemScript, LEGACY_INITIAL_OWNED),
		_build_script_item_def("pizzeria_fridge", "Fridge", "Kitchen", PizzeriaFridgeItemScript, LEGACY_INITIAL_OWNED),
		_build_script_item_def("small_shelf", "Small Shelf", "Shelves", SmallShelfItemScript, LEGACY_INITIAL_OWNED),
		_build_script_item_def("double_bed", "Double Bed", "Beds", DoubleBedItemScript, LEGACY_INITIAL_OWNED),
		_build_script_item_def("window", "Window", "Windows", WindowItemScript, LEGACY_INITIAL_OWNED, RoomConstants.SURFACE_DECOR),
		_build_script_item_def("window_classic", "Window (Classic)", "Windows", ClassicWindowItemScript, LEGACY_INITIAL_OWNED, RoomConstants.SURFACE_DECOR),
	]

static func _build_script_item_def(item_id: String, display_name: String, category: String, script_ref: Script, initial_owned: int, placement_surface_kind: String = RoomConstants.FLOOR_SURFACE) -> Dictionary:
	var item_def := {
		"id": item_id,
		"display_name": display_name,
		"category": category,
		"script": script_ref,
		"placement_surface_kind": placement_surface_kind,
		"initial_owned": initial_owned,
	}
	if placement_surface_kind == RoomConstants.SURFACE_DECOR:
		item_def["supported_wall_surfaces"] = RoomConstants.WALL_SURFACES
	return item_def

static func _build_imported_pack_item_defs() -> Array[Dictionary]:
	var item_defs: Array[Dictionary] = []
	var root_dir := DirAccess.open(IMPORT_ROOT)
	if root_dir == null:
		return item_defs

	var categories: Array[String] = []
	for category_name in root_dir.get_directories():
		categories.append(String(category_name))
	categories.sort_custom(func(a: String, b: String) -> bool: return _sort_categories(a, b))
	for category_name in categories:
		var category_path := "%s/%s" % [IMPORT_ROOT, category_name]
		var category_dir := DirAccess.open(category_path)
		if category_dir == null:
			continue

		var files: Array[String] = []
		for file_name in category_dir.get_files():
			files.append(String(file_name))
		files.sort()
		for file_name in files:
			if not file_name.to_lower().ends_with(".fbx"):
				continue
			item_defs.append(_build_imported_item_def(category_name, file_name))
	return item_defs

static func _build_imported_item_def(category_name: String, file_name: String) -> Dictionary:
	var base_name := file_name.trim_suffix(".fbx")
	var display_name := _format_display_name(base_name)
	var item_id := _make_imported_item_id(category_name, base_name)
	var scene_path := "%s/%s/%s" % [IMPORT_ROOT, category_name, file_name]
	var placement_surface_kind := _infer_surface_kind(category_name, base_name)
	var is_wall_decor := placement_surface_kind == RoomConstants.SURFACE_DECOR
	var rotation_supported := not is_wall_decor
	var requires_wall_opening := category_name == "Windows" or category_name == "Doors"
	var collision_size_override := _infer_collision_size_override(category_name, base_name)

	return {
		"id": item_id,
		"display_name": display_name,
		"category": category_name,
		"factory_type": IMPORTED_FACTORY_TYPE,
		"source_scene_path": scene_path,
		"visual_scale": Vector3.ONE * _infer_visual_scale(category_name, base_name),
		"placement_surface_kind": placement_surface_kind,
		"supported_wall_surfaces": RoomConstants.WALL_SURFACES if is_wall_decor else [],
		"supports_rotation": rotation_supported,
		"requires_wall_opening": requires_wall_opening,
		"wall_rotation_offset": 0.0,
		"collision_size": collision_size_override,
		"initial_owned": IMPORTED_INITIAL_OWNED,
	}

static func _infer_surface_kind(category_name: String, base_name: String) -> String:
	if category_name == "Windows" or category_name == "Doors":
		return RoomConstants.SURFACE_DECOR

	var lower_name := base_name.to_lower()
	for hint in WALL_DECOR_NAME_HINTS:
		if lower_name.contains(hint):
			return RoomConstants.SURFACE_DECOR

	return RoomConstants.FLOOR_SURFACE

static func _infer_collision_size_override(category_name: String, base_name: String) -> Vector3:
	var lower_name := base_name.to_lower()
	if category_name == "Carpets":
		return Vector3(1.6, 0.04, 1.6)
	if lower_name.contains("books") or lower_name.contains("clock") or lower_name.contains("mug") or lower_name.contains("bowl") or lower_name.contains("plate") or lower_name.contains("pot") or lower_name.contains("phone") or lower_name.contains("tablet") or lower_name.contains("keyboard"):
		return Vector3(0.6, 0.3, 0.6)
	return Vector3.ZERO

static func _infer_visual_scale(category_name: String, _base_name: String) -> float:
	return float(IMPORTED_CATEGORY_SCALE_OVERRIDES.get(category_name, 0.26))

static func _make_imported_item_id(category_name: String, base_name: String) -> String:
	var raw_id := "%s_%s" % [category_name, base_name]
	var normalized := raw_id.to_lower()
	var sanitized := ""
	for character in normalized:
		if "abcdefghijklmnopqrstuvwxyz0123456789".contains(character):
			sanitized += character
		else:
			sanitized += "_"
	while sanitized.contains("__"):
		sanitized = sanitized.replace("__", "_")
	return sanitized.strip_edges().trim_prefix("_").trim_suffix("_")

static func _format_display_name(base_name: String) -> String:
	return base_name.replace("_", " ").replace("-", " ").capitalize()

static func _sort_item_defs(a: Dictionary, b: Dictionary) -> bool:
	var category_a := String(a.get("category", "Miscellaneous"))
	var category_b := String(b.get("category", "Miscellaneous"))
	if category_a != category_b:
		return _sort_categories(category_a, category_b)
	return String(a.get("display_name", "")).naturalnocasecmp_to(String(b.get("display_name", ""))) < 0

static func _sort_categories(a: String, b: String) -> bool:
	var index_a := CATEGORY_ORDER.find(a)
	var index_b := CATEGORY_ORDER.find(b)
	if index_a == -1:
		index_a = CATEGORY_ORDER.size()
	if index_b == -1:
		index_b = CATEGORY_ORDER.size()
	if index_a != index_b:
		return index_a < index_b
	return a.naturalnocasecmp_to(b) < 0
