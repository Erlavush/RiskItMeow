class_name PlacementInventoryCatalog
extends RefCounted

const CURATED_INITIAL_OWNED := 3
const IMPORTED_FACTORY_TYPE := "imported_scene"

const PlacementItemProfileOverrideStoreScript := preload("res://scripts/placement/placement_item_profile_override_store.gd")
const IMPORTED_SCENE_PLACEABLE_SCRIPT_PATH := "res://scripts/placement/imported_scene_placeable.gd"
const WOODEN_BLOCK_CLOCK_PLACEABLE_SCRIPT_PATH := "res://scripts/placement/wooden_block_clock_placeable.gd"
const MACAWS_CEILING_FAN_PLACEABLE_SCRIPT_PATH := "res://scripts/placement/macaws_ceiling_fan_placeable.gd"

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
	"Decor",
	"Miscellaneous",
]

const MOUNT_BADGE_LABELS := {
	RoomConstants.MOUNT_FLOOR: "Floor Item",
	RoomConstants.MOUNT_WALL: "Wall Item",
	RoomConstants.MOUNT_CEILING: "Ceiling Item",
	RoomConstants.MOUNT_SURFACE: "Surface Item",
}

static func build_item_defs() -> Array[Dictionary]:
	var persisted_overrides := PlacementItemProfileOverrideStoreScript.load_all_overrides()
	var item_defs := _build_live_item_defs(persisted_overrides)
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

static func supports_studio_edit(item_def: Dictionary) -> bool:
	return uses_imported_scene_factory(item_def) or bool(item_def.get("supports_studio_edit", false))

static func create_imported_scene_instance(item_def: Dictionary):
	var imported_script := load(IMPORTED_SCENE_PLACEABLE_SCRIPT_PATH) as Script
	if imported_script == null:
		push_warning("Could not load imported scene placeable script at %s" % IMPORTED_SCENE_PLACEABLE_SCRIPT_PATH)
		return null
	var placeable: Variant = imported_script.new()
	if placeable != null and placeable.has_method("configure_from_item_def"):
		placeable.configure_from_item_def(item_def)
	return placeable

static func create_item_instance(item_def: Dictionary):
	if uses_imported_scene_factory(item_def):
		return create_imported_scene_instance(item_def)

	var item_script := get_item_script(item_def)
	if item_script == null:
		return null

	var placeable: Variant = item_script.new()
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

static func _build_live_item_defs(persisted_overrides: Dictionary = {}) -> Array[Dictionary]:
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
			CURATED_INITIAL_OWNED,
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
			CURATED_INITIAL_OWNED,
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
				"support_surfaces": [
					{
						"id": "top",
						"center_offset": Vector3(0.0, 1.0625, -0.31),
						"half_extents": Vector2(1.38, 0.24),
					},
				],
			},
			CURATED_INITIAL_OWNED,
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
			CURATED_INITIAL_OWNED,
			persisted_overrides
		),
		_build_scripted_item_def(
			"wooden_block_clock",
			"Wooden Block Clock",
			"Electronics",
			WOODEN_BLOCK_CLOCK_PLACEABLE_SCRIPT_PATH,
			{
				"mount_kind": RoomConstants.MOUNT_WALL,
				"supported_wall_surfaces": RoomConstants.WALL_SURFACES,
				"visual_scale": Vector3.ONE,
				"visual_y_offset": 0.0,
				"visual_yaw": 0.0,
				"preview_yaw": PI,
				"collision_size": Vector3(1.0, 1.45, 0.5),
				"collision_center_offset": Vector3(0.0, 0.725, 0.0),
				"wall_half_extents": Vector2(0.5, 0.725),
				"supports_studio_edit": true,
			},
			1,
			persisted_overrides
		),
		_build_scripted_item_def(
			"ceiling_fan",
			"Ceiling Fan",
			"Lights",
			MACAWS_CEILING_FAN_PLACEABLE_SCRIPT_PATH,
			{
				"source_scene_path": "res://assets/props/macaws_lights/ceiling_fan/ceiling_fan.glb",
				"mount_kind": RoomConstants.MOUNT_CEILING,
				"anchor_mode": "ceiling",
				"preview_yaw": PI * 0.25,
				"fan_speed_degrees_per_second": 240.0,
				"supports_studio_edit": true,
			},
			1,
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
			CURATED_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"books_stack",
			"Books Stack",
			"Decor",
			"res://assets/props/surface_decor/books_stack/books_stack.glb",
			{
				"mount_kind": RoomConstants.MOUNT_SURFACE,
				"visual_fit_height": 0.42,
				"preview_yaw": -PI * 0.18,
			},
			CURATED_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"fern_pot",
			"Fern Pot",
			"Decor",
			"res://assets/props/surface_decor/fern_pot/fern_pot.glb",
			{
				"mount_kind": RoomConstants.MOUNT_SURFACE,
				"visual_fit_height": 0.65,
				"preview_yaw": PI * 0.1,
			},
			CURATED_INITIAL_OWNED,
			persisted_overrides
		),
		_build_curated_imported_item_def(
			"flower_pot",
			"Flower Pot",
			"Decor",
			"res://assets/props/surface_decor/flower_pot/flower_pot.glb",
			{
				"mount_kind": RoomConstants.MOUNT_SURFACE,
				"visual_fit_height": 0.6,
				"preview_yaw": PI * 0.1,
			},
			CURATED_INITIAL_OWNED,
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
			CURATED_INITIAL_OWNED,
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
			CURATED_INITIAL_OWNED,
			persisted_overrides
		),
	]

static func _build_curated_imported_item_def(item_id: String, display_name: String, category: String, source_scene_path: String, extra_values: Dictionary = {}, initial_owned: int = CURATED_INITIAL_OWNED, persisted_overrides: Dictionary = {}) -> Dictionary:
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

static func _build_scripted_item_def(item_id: String, display_name: String, category: String, script_path: String, extra_values: Dictionary = {}, initial_owned: int = CURATED_INITIAL_OWNED, persisted_overrides: Dictionary = {}) -> Dictionary:
	var item_script := load(script_path) as Script
	var primary_mount_kind := String(extra_values.get("mount_kind", RoomConstants.MOUNT_FLOOR))
	if not RoomConstants.is_mount_kind(primary_mount_kind):
		primary_mount_kind = RoomConstants.MOUNT_FLOOR

	var item_def := {
		"id": item_id,
		"display_name": display_name,
		"category": category,
		"script": item_script,
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

static func _build_mount_kinds(item_def: Dictionary, primary_mount_kind: String) -> Array[String]:
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
	if not mount_kinds.has(primary_mount_kind):
		mount_kinds.push_front(primary_mount_kind)
	return mount_kinds

static func _get_runtime_surface_kind_for_mount_kind(mount_kind: String) -> String:
	return RoomConstants.SURFACE_DECOR if mount_kind == RoomConstants.MOUNT_WALL else RoomConstants.FLOOR_SURFACE

static func is_runtime_supported_mount_kind(mount_kind: String) -> bool:
	return mount_kind == RoomConstants.MOUNT_FLOOR or mount_kind == RoomConstants.MOUNT_WALL or mount_kind == RoomConstants.MOUNT_CEILING or mount_kind == RoomConstants.MOUNT_SURFACE

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
