class_name PlacementRoomLayoutStore
extends RefCounted

const SAVE_PATH := "user://room_layout.json"
const VERSION := 3
const ROTATION_PRECISION := 0.0001

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

static func serialize_layout(placed_items_root: Node3D, item_id_resolver: Callable, instance_id_resolver: Callable, floor_style: int, owned_stock: Dictionary = {}) -> Dictionary:
	var items: Array[Dictionary] = []
	_serialize_placeables_recursive(placed_items_root, item_id_resolver, instance_id_resolver, items)
	return {
		"version": VERSION,
		"floor_style": floor_style,
		"owned_stock": serialize_owned_stock(owned_stock),
		"items": items,
	}

static func _serialize_placeables_recursive(node: Node, item_id_resolver: Callable, instance_id_resolver: Callable, output: Array[Dictionary]) -> void:
	for child in node.get_children():
		var placeable := child as PlaceableItem
		if placeable != null:
			var item_id := String(item_id_resolver.call(placeable))
			if not item_id.is_empty():
				output.append(_serialize_placeable(placeable, item_id, instance_id_resolver))
			_serialize_placeables_recursive(placeable, item_id_resolver, instance_id_resolver, output)
			continue
		_serialize_placeables_recursive(child, item_id_resolver, instance_id_resolver, output)

static func _serialize_placeable(placeable: PlaceableItem, item_id: String, instance_id_resolver: Callable) -> Dictionary:
	var instance_id := String(instance_id_resolver.call(placeable))
	var entry := {
		"instance_id": instance_id,
		"item_id": item_id,
		"rotation_y": snappedf(placeable.rotation.y, ROTATION_PRECISION),
	}

	var host_placeable := placeable.get_parent() as PlaceableItem
	if host_placeable != null:
		entry["position"] = serialize_vector3(placeable.position)
		entry["attachment"] = {
			"kind": RoomConstants.ATTACHMENT_SUPPORT_SURFACE,
			"host_instance_id": String(instance_id_resolver.call(host_placeable)),
			"surface_id": String(placeable.get_meta("host_surface_id")) if placeable.has_meta("host_surface_id") else "top",
		}
		entry["placement_surface"] = RoomConstants.MOUNT_SURFACE
		return entry

	var placement_surface := String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
	entry["position"] = serialize_vector3(placeable.global_position)
	entry["placement_surface"] = placement_surface
	entry["attachment"] = {
		"kind": RoomConstants.ATTACHMENT_ROOM,
		"surface": placement_surface,
	}
	return entry

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
