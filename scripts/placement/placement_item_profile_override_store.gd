class_name PlacementItemProfileOverrideStore
extends RefCounted

const SAVE_PATH := "user://placement_item_profile_overrides.cfg"
const ALLOWED_KEYS := {
	"visual_scale": TYPE_VECTOR3,
	"visual_y_offset": TYPE_FLOAT,
	"visual_yaw": TYPE_FLOAT,
	"mount_kind": TYPE_STRING,
	"collision_size": TYPE_VECTOR3,
	"collision_center_offset": TYPE_VECTOR3,
	"footprint_half_extents": TYPE_VECTOR2,
	"wall_half_extents": TYPE_VECTOR2,
	"wall_opening_half_extents": TYPE_VECTOR2,
	"can_host_surface_items": TYPE_BOOL,
	"support_surfaces": TYPE_ARRAY,
	"requires_wall_opening": TYPE_BOOL,
}

static func load_all_overrides(path: String = SAVE_PATH) -> Dictionary:
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		return {}

	var overrides: Dictionary = {}
	for section_name in config.get_sections():
		var section_values: Dictionary = {}
		for key_name in config.get_section_keys(section_name):
			if not ALLOWED_KEYS.has(key_name):
				continue
			section_values[key_name] = _normalize_value(key_name, config.get_value(section_name, key_name))
		if not section_values.is_empty():
			overrides[section_name] = section_values
	return overrides

static func load_override(item_id: String, path: String = SAVE_PATH) -> Dictionary:
	var overrides := load_all_overrides(path)
	var raw_override: Variant = overrides.get(item_id, {})
	return (raw_override as Dictionary).duplicate(true) if raw_override is Dictionary else {}

static func has_override(item_id: String, path: String = SAVE_PATH) -> bool:
	return not load_override(item_id, path).is_empty()

static func save_override(item_id: String, values: Dictionary, path: String = SAVE_PATH) -> int:
	if item_id.is_empty():
		return ERR_INVALID_PARAMETER

	var sanitized_values := sanitize_override(values)
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error

	config.erase_section(item_id)
	for key_name in sanitized_values.keys():
		config.set_value(item_id, str(key_name), sanitized_values[key_name])
	return config.save(path)

static func remove_override(item_id: String, path: String = SAVE_PATH) -> int:
	if item_id.is_empty():
		return ERR_INVALID_PARAMETER

	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error == ERR_FILE_NOT_FOUND:
		return OK
	if load_error != OK:
		return load_error

	config.erase_section(item_id)
	return config.save(path)

static func sanitize_override(values: Dictionary) -> Dictionary:
	var sanitized: Dictionary = {}
	for key_name in values.keys():
		var normalized_key := String(key_name)
		if not ALLOWED_KEYS.has(normalized_key):
			continue
		sanitized[normalized_key] = _normalize_value(normalized_key, values[key_name])
	return sanitized

static func get_file_signature(path: String = SAVE_PATH) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()

static func _normalize_value(key_name: String, raw_value: Variant) -> Variant:
	match int(ALLOWED_KEYS.get(key_name, TYPE_NIL)):
		TYPE_VECTOR3:
			return raw_value as Vector3
		TYPE_VECTOR2:
			return raw_value as Vector2
		TYPE_BOOL:
			return bool(raw_value)
		TYPE_ARRAY:
			if key_name == "support_surfaces":
				return _normalize_support_surfaces(raw_value)
			return raw_value
		TYPE_FLOAT:
			return float(raw_value)
		TYPE_STRING:
			return String(raw_value)
		_:
			return raw_value

static func _normalize_support_surfaces(raw_value: Variant) -> Array[Dictionary]:
	var support_surfaces: Array[Dictionary] = []
	if raw_value is Array:
		for raw_surface in raw_value:
			if typeof(raw_surface) != TYPE_DICTIONARY:
				continue
			var surface_dict := raw_surface as Dictionary
			var center_offset := surface_dict.get("center_offset", Vector3.ZERO) as Vector3
			var half_extents := surface_dict.get("half_extents", Vector2.ZERO) as Vector2
			if half_extents.x < 0.0 or half_extents.y < 0.0:
				continue
			support_surfaces.append(
				{
					"id": String(surface_dict.get("id", "top")),
					"center_offset": center_offset,
					"half_extents": half_extents,
				}
			)
	return support_surfaces
