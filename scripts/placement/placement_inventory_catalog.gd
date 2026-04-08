class_name PlacementInventoryCatalog
extends RefCounted

const LEGACY_INITIAL_OWNED := 3
const IMPORTED_INITIAL_OWNED := 0
const IMPORT_ROOT := "res://assets/props/low_poly_household"
const IMPORTED_FACTORY_TYPE := "imported_scene"
const ENABLED_IMPORTED_ITEM_IDS: Array[String] = []

const SimpleWoodChairScript := preload("res://scripts/placement/simple_wood_chair.gd")
const OfficeChairItemScript := preload("res://scripts/placement/office_chair_item.gd")
const OfficeDeskItemScript := preload("res://scripts/placement/office_desk_item.gd")
const PizzeriaFridgeItemScript := preload("res://scripts/placement/pizzeria_fridge_item.gd")
const SmallShelfItemScript := preload("res://scripts/placement/small_shelf_item.gd")
const WindowItemScript := preload("res://scripts/placement/window_item.gd")
const ClassicWindowItemScript := preload("res://scripts/placement/classic_window_item.gd")
const PlacementItemProfileOverrideStoreScript := preload("res://scripts/placement/placement_item_profile_override_store.gd")
const IMPORTED_SCENE_PLACEABLE_SCRIPT_PATH := "res://scripts/placement/imported_scene_placeable.gd"

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

const MOUNT_BADGE_LABELS := {
	RoomConstants.MOUNT_FLOOR: "Floor Item",
	RoomConstants.MOUNT_WALL: "Wall Item",
	RoomConstants.MOUNT_CEILING: "Ceiling Item",
	RoomConstants.MOUNT_SURFACE: "Surface Item",
}

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

const CEILING_NAME_HINTS := [
	"ceiling light",
	"ceiling fan",
]

const SURFACE_DECOR_NAME_HINTS := [
	"alarm clock",
	"blender",
	"books",
	"bowl",
	"glass",
	"globe",
	"kettle",
	"kitchen roll",
	"knife block",
	"keyboard",
	"laptop",
	"microwave",
	"monitor",
	"mug",
	"pan",
	"phone",
	"plant",
	"plate",
	"pot",
	"speaker",
	"tablet",
	"toaster",
	"vase",
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

const IMPORTED_ITEM_PROFILE_OVERRIDES := {
	"bathroom_bath": {
		"collision_size": Vector3(1.6, 0.9, 0.85),
		"footprint_half_extents": Vector2(0.68, 0.32),
	},
	"bathroom_shower": {
		"collision_size": Vector3(1.1, 1.9, 1.1),
		"footprint_half_extents": Vector2(0.45, 0.45),
	},
	"bathroom_sink": {
		"can_host_surface_items": true,
		"collision_size": Vector3(0.75, 1.0, 0.55),
		"footprint_half_extents": Vector2(0.28, 0.22),
	},
	"beds_bed_double": {
		"visual_scale": Vector3(0.16, 0.16, 0.16),
	},
	"bathroom_toilet": {
		"collision_size": Vector3(0.8, 1.0, 0.9),
		"footprint_half_extents": Vector2(0.28, 0.34),
	},
	"bathroom_toilet_roll_holder": {"mount_kind": RoomConstants.MOUNT_WALL},
	"bathroom_toilet_rolls": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.26, 0.24, 0.18),
		"footprint_half_extents": Vector2(0.09, 0.07),
	},
	"bathroom_towel_holder": {"mount_kind": RoomConstants.MOUNT_WALL},
	"doors_door_a": {"mount_kind": RoomConstants.MOUNT_WALL, "requires_wall_opening": true},
	"doors_door_b": {"mount_kind": RoomConstants.MOUNT_WALL, "requires_wall_opening": true},
	"doors_door_c": {"mount_kind": RoomConstants.MOUNT_WALL, "requires_wall_opening": true},
	"kitchen_blender": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.34, 0.54, 0.24),
		"footprint_half_extents": Vector2(0.13, 0.09),
	},
	"kitchen_kettle": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.28, 0.32, 0.24),
		"footprint_half_extents": Vector2(0.11, 0.09),
	},
	"kitchen_kitchen_roll": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.22, 0.34, 0.22),
		"footprint_half_extents": Vector2(0.08, 0.08),
	},
	"kitchen_knife_block": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.24, 0.38, 0.18),
		"footprint_half_extents": Vector2(0.1, 0.07),
	},
	"kitchen_microwave": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.58, 0.36, 0.4),
		"footprint_half_extents": Vector2(0.23, 0.16),
	},
	"kitchen_toaster": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.38, 0.26, 0.24),
		"footprint_half_extents": Vector2(0.16, 0.1),
	},
	"lights_ceiling_light": {
		"mount_kind": RoomConstants.MOUNT_CEILING,
		"collision_size": Vector3(0.75, 0.35, 0.75),
		"footprint_half_extents": Vector2(0.3, 0.3),
	},
	"lights_wall_light": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_alarm_clock": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.28, 0.22, 0.18),
		"footprint_half_extents": Vector2(0.11, 0.07),
	},
	"miscellaneous_books_a": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.36, 0.18, 0.26),
		"footprint_half_extents": Vector2(0.16, 0.11),
	},
	"miscellaneous_books_b": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.36, 0.18, 0.26),
		"footprint_half_extents": Vector2(0.16, 0.11),
	},
	"miscellaneous_bowl": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.32, 0.18, 0.32),
		"footprint_half_extents": Vector2(0.13, 0.13),
	},
	"miscellaneous_ceiling_fan": {
		"mount_kind": RoomConstants.MOUNT_CEILING,
		"collision_size": Vector3(1.6, 0.4, 1.6),
		"footprint_half_extents": Vector2(0.68, 0.68),
	},
	"miscellaneous_clock": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_curtains": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_glass": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.18, 0.34, 0.18),
		"footprint_half_extents": Vector2(0.07, 0.07),
	},
	"miscellaneous_globe": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.34, 0.46, 0.34),
		"footprint_half_extents": Vector2(0.13, 0.13),
	},
	"miscellaneous_light_switch": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_mirror_a": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_mirror_b": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_mug": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.22, 0.28, 0.22),
		"footprint_half_extents": Vector2(0.09, 0.09),
	},
	"miscellaneous_pan": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.52, 0.12, 0.32),
		"footprint_half_extents": Vector2(0.2, 0.11),
	},
	"miscellaneous_plant_a": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.34, 0.48, 0.34),
		"footprint_half_extents": Vector2(0.13, 0.13),
	},
	"miscellaneous_plant_b": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.34, 0.48, 0.34),
		"footprint_half_extents": Vector2(0.13, 0.13),
	},
	"miscellaneous_plate": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.34, 0.08, 0.34),
		"footprint_half_extents": Vector2(0.15, 0.15),
	},
	"miscellaneous_pot": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.42, 0.28, 0.42),
		"footprint_half_extents": Vector2(0.17, 0.17),
	},
	"miscellaneous_radiator_a": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_radiator_b": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_socket": {"mount_kind": RoomConstants.MOUNT_WALL},
	"miscellaneous_speaker": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.28, 0.38, 0.22),
		"footprint_half_extents": Vector2(0.1, 0.08),
	},
	"miscellaneous_vase": {
		"mount_kind": RoomConstants.MOUNT_SURFACE,
		"collision_size": Vector3(0.26, 0.46, 0.26),
		"footprint_half_extents": Vector2(0.09, 0.09),
	},
	"miscellaneous_vent": {"mount_kind": RoomConstants.MOUNT_WALL},
	"shelves_shelf_d": {
		"visual_scale": Vector3(0.188, 0.188, 0.188),
		"footprint_half_extents": Vector2(1.0, 0.5),
	},
	"shelves_wall_shelf_a": {
		"mount_kind": RoomConstants.MOUNT_WALL,
		"can_host_surface_items": true,
	},
	"shelves_wall_shelf_b": {
		"mount_kind": RoomConstants.MOUNT_WALL,
		"can_host_surface_items": true,
	},
	"windows_window_a": {"mount_kind": RoomConstants.MOUNT_WALL, "requires_wall_opening": true},
	"windows_window_b": {"mount_kind": RoomConstants.MOUNT_WALL, "requires_wall_opening": true},
	"windows_window_c": {"mount_kind": RoomConstants.MOUNT_WALL, "requires_wall_opening": true},
}

static func build_item_defs() -> Array[Dictionary]:
	var item_defs: Array[Dictionary] = []
	var persisted_imported_overrides := PlacementItemProfileOverrideStoreScript.load_all_overrides()
	item_defs.append_array(_build_legacy_item_defs(persisted_imported_overrides))
	item_defs.append_array(_build_curated_imported_item_defs(persisted_imported_overrides))
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
	var imported_script := load(IMPORTED_SCENE_PLACEABLE_SCRIPT_PATH) as Script
	if imported_script == null:
		push_warning("Could not load imported scene placeable script at %s" % IMPORTED_SCENE_PLACEABLE_SCRIPT_PATH)
		return null
	var placeable: Variant = imported_script.new()
	if placeable != null and placeable.has_method("configure_from_item_def"):
		placeable.configure_from_item_def(item_def)
	return placeable

static func get_primary_mount_kind(item_def: Dictionary) -> String:
	var requested_mount_kind := String(item_def.get("mount_kind", ""))
	if RoomConstants.is_mount_kind(requested_mount_kind):
		return requested_mount_kind
	var raw_mount_kinds: Variant = item_def.get("mount_kinds", [])
	if raw_mount_kinds is Array:
		for raw_mount_kind in raw_mount_kinds:
			var mount_kind := String(raw_mount_kind)
			if RoomConstants.is_mount_kind(mount_kind):
				return mount_kind
	var legacy_surface_kind := String(item_def.get("placement_surface_kind", RoomConstants.FLOOR_SURFACE))
	return RoomConstants.MOUNT_WALL if legacy_surface_kind == RoomConstants.SURFACE_DECOR else RoomConstants.MOUNT_FLOOR

static func get_mount_kinds(item_def: Dictionary) -> Array[String]:
	var mount_kinds: Array[String] = []
	var raw_mount_kinds: Variant = item_def.get("mount_kinds", [])
	if raw_mount_kinds is Array:
		for raw_mount_kind in raw_mount_kinds:
			var mount_kind := String(raw_mount_kind)
			if not RoomConstants.is_mount_kind(mount_kind):
				continue
			if mount_kinds.has(mount_kind):
				continue
			mount_kinds.append(mount_kind)
	if mount_kinds.is_empty():
		mount_kinds.append(get_primary_mount_kind(item_def))
	return mount_kinds

static func get_mount_badge_text(item_def: Dictionary) -> String:
	var primary_mount_kind := get_primary_mount_kind(item_def)
	var badge_text := String(MOUNT_BADGE_LABELS.get(primary_mount_kind, "Floor Item"))
	if is_runtime_supported_mount_kind(primary_mount_kind):
		return badge_text
	return "%s (Planned)" % badge_text

static func supports_runtime_placement(item_def: Dictionary) -> bool:
	return is_runtime_supported_mount_kind(get_primary_mount_kind(item_def))

static func _build_legacy_item_defs(persisted_overrides: Dictionary = {}) -> Array[Dictionary]:
	return [
		_build_curated_imported_item_def(
			"simple_wood_chair",
			"Simple Wood Chair",
			"Chairs",
			"res://assets/props/simple_wood_chair/scene.gltf",
			{
				"visual_scale": Vector3.ONE * 0.25,
				"visual_y_offset": 0.275,
				"collision_size": Vector3(0.9, 1.5, 0.9),
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"office_chair",
			"Office Chair",
			"Chairs",
			"res://assets/props/fnaf-minecraft-pizzeria-pack/source/demopack.gltf",
			{
				"source_node_names": ["OfficeChair"],
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"office_desk_computer",
			"Office Desk + Computer",
			"Tables",
			"res://assets/props/fnaf-minecraft-pizzeria-pack/source/demopack.gltf",
			{
				"source_node_names": ["OfficeTable", "Conputer"],
				"collision_size": Vector3(3.0, 1.8, 0.94),
				"footprint_half_extents": Vector2(1.5, 0.5),
				"can_host_surface_items": true,
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"pizzeria_fridge",
			"Fridge",
			"Kitchen",
			"res://assets/props/fnaf-minecraft-pizzeria-pack/source/demopack.gltf",
			{
				"source_node_names": ["Fridge"],
				"can_host_surface_items": true,
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"small_shelf",
			"Small Shelf",
			"Shelves",
			"res://assets/props/small_shelf/small_shelf.glb",
			{
				"can_host_surface_items": true,
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"window",
			"Window",
			"Windows",
			"res://assets/props/three_window/scene.gltf",
			{
				"mount_kind": RoomConstants.MOUNT_WALL,
				"requires_wall_opening": true,
				"supports_rotation": false,
				"wall_rotation_offset": PI,
				"anchor_mode": "center",
				"visual_fit_height": 1.5,
				"runtime_shadow_cast_setting": GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"window_classic",
			"Window (Classic)",
			"Windows",
			"res://assets/props/window/window.glb",
			{
				"mount_kind": RoomConstants.MOUNT_WALL,
				"requires_wall_opening": true,
				"supports_rotation": false,
				"wall_rotation_offset": PI,
				"anchor_mode": "center",
				"visual_fit_height": 1.5,
				"runtime_shadow_cast_setting": GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			},
			LEGACY_INITIAL_OWNED,
			persisted_overrides
		),
	]

static func _build_script_item_def(item_id: String, display_name: String, category: String, script_ref: Script, initial_owned: int, primary_mount_kind: String = RoomConstants.MOUNT_FLOOR) -> Dictionary:
	var item_def := {
		"id": item_id,
		"display_name": display_name,
		"category": category,
		"script": script_ref,
		"mount_kind": primary_mount_kind,
		"mount_kinds": [primary_mount_kind],
		"placement_surface_kind": _get_runtime_surface_kind_for_mount_kind(primary_mount_kind),
		"initial_owned": initial_owned,
	}
	if primary_mount_kind == RoomConstants.MOUNT_WALL:
		item_def["supported_wall_surfaces"] = RoomConstants.WALL_SURFACES
	return item_def

static func _build_curated_imported_item_def(item_id: String, display_name: String, category: String, source_scene_path: String, extra_values: Dictionary = {}, initial_owned: int = LEGACY_INITIAL_OWNED, persisted_overrides: Dictionary = {}) -> Dictionary:
	var primary_mount_kind := String(extra_values.get("mount_kind", RoomConstants.MOUNT_FLOOR))
	if not RoomConstants.is_mount_kind(primary_mount_kind):
		primary_mount_kind = RoomConstants.MOUNT_FLOOR
	var item_def := {
		"id": item_id,
		"display_name": display_name,
		"category": category,
		"factory_type": IMPORTED_FACTORY_TYPE,
		"source_scene_path": source_scene_path,
		"mount_kind": primary_mount_kind,
		"mount_kinds": [primary_mount_kind],
		"placement_surface_kind": _get_runtime_surface_kind_for_mount_kind(primary_mount_kind),
		"initial_owned": initial_owned,
	}
	for key_name in extra_values.keys():
		item_def[key_name] = extra_values[key_name]
	var raw_persisted_override: Variant = persisted_overrides.get(item_id, {})
	if raw_persisted_override is Dictionary and not (raw_persisted_override as Dictionary).is_empty():
		item_def.merge((raw_persisted_override as Dictionary).duplicate(true), true)
	primary_mount_kind = get_primary_mount_kind(item_def)
	item_def["mount_kind"] = primary_mount_kind
	item_def["mount_kinds"] = _build_mount_kinds(item_def, primary_mount_kind)
	item_def["placement_surface_kind"] = _get_runtime_surface_kind_for_mount_kind(primary_mount_kind)
	if primary_mount_kind == RoomConstants.MOUNT_WALL and not item_def.has("supported_wall_surfaces"):
		item_def["supported_wall_surfaces"] = RoomConstants.WALL_SURFACES
	return item_def

static func _build_imported_pack_item_defs(persisted_overrides: Dictionary = {}) -> Array[Dictionary]:
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
			item_defs.append(_build_imported_item_def(category_name, file_name, persisted_overrides))
	return item_defs

static func _build_curated_imported_item_defs(persisted_overrides: Dictionary = {}) -> Array[Dictionary]:
	if ENABLED_IMPORTED_ITEM_IDS.is_empty():
		return []

	var allowed_ids: Dictionary = {}
	for item_id in ENABLED_IMPORTED_ITEM_IDS:
		allowed_ids[String(item_id)] = true

	var curated_defs: Array[Dictionary] = []
	for item_def in _build_imported_pack_item_defs(persisted_overrides):
		var item_id := String(item_def.get("id", ""))
		if allowed_ids.has(item_id):
			curated_defs.append(item_def)
	return curated_defs

static func _build_imported_item_def(category_name: String, file_name: String, persisted_overrides: Dictionary = {}) -> Dictionary:
	var base_name := file_name.trim_suffix(".fbx")
	var display_name := _format_display_name(base_name)
	var item_id := _make_imported_item_id(category_name, base_name)
	var scene_path := "%s/%s/%s" % [IMPORT_ROOT, category_name, file_name]
	var profile_override := _get_imported_profile_override(item_id, persisted_overrides)
	var primary_mount_kind := _infer_mount_kind(item_id, category_name, base_name, profile_override)
	var mount_kinds := _build_mount_kinds(profile_override, primary_mount_kind)
	var placement_surface_kind := _get_runtime_surface_kind_for_mount_kind(primary_mount_kind)
	var is_runtime_wall_item := placement_surface_kind == RoomConstants.SURFACE_DECOR
	var can_host_surface_items := _infer_can_host_surface_items(category_name, base_name, profile_override, primary_mount_kind)
	var item_def := {
		"id": item_id,
		"display_name": display_name,
		"category": category_name,
		"factory_type": IMPORTED_FACTORY_TYPE,
		"source_scene_path": scene_path,
		"visual_scale": Vector3.ONE * _infer_visual_scale(category_name, base_name),
		"mount_kind": primary_mount_kind,
		"mount_kinds": mount_kinds,
		"placement_surface_kind": placement_surface_kind,
		"supported_wall_surfaces": _build_supported_wall_surfaces(profile_override, is_runtime_wall_item),
		"supports_rotation": bool(profile_override.get("supports_rotation", not is_runtime_wall_item)),
		"requires_wall_opening": bool(profile_override.get("requires_wall_opening", category_name == "Windows" or category_name == "Doors")),
		"wall_rotation_offset": 0.0,
		"collision_size": profile_override.get("collision_size", _infer_collision_size_override(category_name, base_name, primary_mount_kind)),
		"can_host_surface_items": can_host_surface_items,
		"initial_owned": IMPORTED_INITIAL_OWNED,
	}
	for override_key in [
		"support_surfaces",
		"collision_center_offset",
		"footprint_half_extents",
		"wall_half_extents",
		"wall_opening_half_extents",
		"visual_y_offset",
		"visual_yaw",
		"wall_rotation_offset",
		"visual_scale",
	]:
		if profile_override.has(override_key):
			item_def[override_key] = profile_override[override_key]
	return item_def

static func _infer_mount_kind(_item_id: String, category_name: String, base_name: String, profile_override: Dictionary) -> String:
	var override_mount_kind := String(profile_override.get("mount_kind", ""))
	if RoomConstants.is_mount_kind(override_mount_kind):
		return override_mount_kind
	if category_name == "Windows" or category_name == "Doors":
		return RoomConstants.MOUNT_WALL

	var lower_name := base_name.to_lower()
	for hint in CEILING_NAME_HINTS:
		if lower_name.contains(hint):
			return RoomConstants.MOUNT_CEILING
	for hint in WALL_DECOR_NAME_HINTS:
		if lower_name.contains(hint):
			return RoomConstants.MOUNT_WALL
	for hint in SURFACE_DECOR_NAME_HINTS:
		if lower_name.contains(hint):
			return RoomConstants.MOUNT_SURFACE

	return RoomConstants.MOUNT_FLOOR

static func _infer_collision_size_override(category_name: String, base_name: String, primary_mount_kind: String) -> Vector3:
	var lower_name := base_name.to_lower()
	if category_name == "Carpets":
		return Vector3(1.6, 0.04, 1.6)
	if primary_mount_kind == RoomConstants.MOUNT_WALL or primary_mount_kind == RoomConstants.MOUNT_CEILING:
		return Vector3.ZERO
	if lower_name.contains("books") or lower_name.contains("clock") or lower_name.contains("mug") or lower_name.contains("bowl") or lower_name.contains("plate") or lower_name.contains("pot") or lower_name.contains("phone") or lower_name.contains("tablet") or lower_name.contains("keyboard"):
		return Vector3(0.6, 0.3, 0.6)
	return Vector3.ZERO

static func _get_imported_profile_override(item_id: String, persisted_overrides: Dictionary = {}) -> Dictionary:
	var merged_override: Dictionary = {}
	var raw_override: Variant = IMPORTED_ITEM_PROFILE_OVERRIDES.get(item_id, {})
	if raw_override is Dictionary:
		merged_override.merge((raw_override as Dictionary).duplicate(true), true)

	var persisted_override: Dictionary = {}
	var raw_persisted: Variant = persisted_overrides.get(item_id, {})
	if raw_persisted is Dictionary:
		persisted_override = (raw_persisted as Dictionary).duplicate(true)
	if not persisted_override.is_empty():
		merged_override.merge(persisted_override, true)
	return merged_override

static func _infer_can_host_surface_items(category_name: String, base_name: String, profile_override: Dictionary, primary_mount_kind: String) -> bool:
	if profile_override.has("can_host_surface_items"):
		return bool(profile_override.get("can_host_surface_items", false))
	if primary_mount_kind == RoomConstants.MOUNT_SURFACE or primary_mount_kind == RoomConstants.MOUNT_CEILING:
		return false

	var lower_name := base_name.to_lower()
	if category_name == "Tables" or category_name == "Drawers" or category_name == "Shelves":
		return true
	if category_name == "Kitchen":
		return lower_name.contains("cupboard") or lower_name.contains("fridge") or lower_name.contains("oven") or lower_name.contains("dishwasher") or lower_name.contains("washing machine")
	if category_name == "Bathroom":
		return lower_name.contains("sink")
	return false

static func _build_mount_kinds(profile_override: Dictionary, primary_mount_kind: String) -> Array[String]:
	var mount_kinds: Array[String] = []
	var raw_mount_kinds: Variant = profile_override.get("mount_kinds", [])
	if raw_mount_kinds is Array:
		for raw_mount_kind in raw_mount_kinds:
			var mount_kind := String(raw_mount_kind)
			if not RoomConstants.is_mount_kind(mount_kind):
				continue
			if mount_kinds.has(mount_kind):
				continue
			mount_kinds.append(mount_kind)
	if not mount_kinds.has(primary_mount_kind):
		mount_kinds.push_front(primary_mount_kind)
	return mount_kinds

static func _build_supported_wall_surfaces(profile_override: Dictionary, is_runtime_wall_item: bool) -> Array:
	var supported_surfaces: Array = []
	var raw_supported_surfaces: Variant = profile_override.get("supported_wall_surfaces", [])
	if raw_supported_surfaces is Array:
		for raw_surface_name in raw_supported_surfaces:
			supported_surfaces.append(String(raw_surface_name))
	if supported_surfaces.is_empty() and is_runtime_wall_item:
		return RoomConstants.WALL_SURFACES
	return supported_surfaces

static func _get_runtime_surface_kind_for_mount_kind(mount_kind: String) -> String:
	return RoomConstants.SURFACE_DECOR if mount_kind == RoomConstants.MOUNT_WALL else RoomConstants.FLOOR_SURFACE

static func is_runtime_supported_mount_kind(mount_kind: String) -> bool:
	return mount_kind == RoomConstants.MOUNT_FLOOR or mount_kind == RoomConstants.MOUNT_WALL or mount_kind == RoomConstants.MOUNT_CEILING or mount_kind == RoomConstants.MOUNT_SURFACE

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
