class_name PlacementRoomLayoutStore
extends RefCounted

const RoomConstants := preload("res://scripts/room/room_constants.gd")
const SAVE_PATH := "user://room_layout.json"
const VERSION := 2

static func serialize_vector3(value: Vector3) -> Dictionary:
	return {
		"x": snappedf(value.x, 0.001),
		"y": snappedf(value.y, 0.001),
		"z": snappedf(value.z, 0.001),
	}

static func deserialize_vector3(raw_value: Variant) -> Vector3:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return Vector3.ZERO

	var raw_dict: Dictionary = raw_value
	return Vector3(
		float(raw_dict.get("x", 0.0)),
		float(raw_dict.get("y", 0.0)),
		float(raw_dict.get("z", 0.0))
	)

static func serialize_owned_stock(owned_stock: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for item_id_variant in owned_stock.keys():
		var item_id := String(item_id_variant)
		serialized[item_id] = maxi(0, int(owned_stock.get(item_id_variant, 0)))
	return serialized

static func deserialize_owned_stock(raw_value: Variant) -> Dictionary:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}

	var raw_dict: Dictionary = raw_value
	var owned_stock: Dictionary = {}
	for key_variant in raw_dict.keys():
		owned_stock[String(key_variant)] = maxi(0, int(raw_dict.get(key_variant, 0)))
	return owned_stock

static func serialize_layout(placed_items_root: Node3D, item_id_resolver: Callable, floor_style: int, owned_stock: Dictionary = {}) -> Dictionary:
	var items: Array[Dictionary] = []
	for child in placed_items_root.get_children():
		var placeable := child as SimpleWoodChair
		if placeable == null:
			continue

		var item_id := String(item_id_resolver.call(placeable))
		if item_id.is_empty():
			continue

		items.append(
			{
				"item_id": item_id,
				"position": serialize_vector3(placeable.global_position),
				"rotation_y": snappedf(placeable.rotation.y, 0.001),
				"placement_surface": String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE,
			}
		)

	return {
		"version": VERSION,
		"floor_style": floor_style,
		"owned_stock": serialize_owned_stock(owned_stock),
		"items": items,
	}

static func save_layout(layout: Dictionary, path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to open room layout save at %s" % path)
		return false

	file.store_string(JSON.stringify(layout, "\t"))
	return true

static func load_layout_data(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open room layout save at %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary

	push_warning("Room layout save data at %s is invalid JSON" % path)
	return {}

static func get_file_signature(path: String = SAVE_PATH) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()
