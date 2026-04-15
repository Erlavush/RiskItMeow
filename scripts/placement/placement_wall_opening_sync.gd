extends RefCounted
class_name PlacementWallOpeningSync

var placement_manager
var room_shell: RoomShell
var wall_openings_signature := ""

func sync(placed_items_root: Node3D, preview_item: PlaceableItem, active_surface_name: String, placement_active: bool) -> bool:
	if room_shell == null and placement_manager != null:
		room_shell = placement_manager._room_shell
	if room_shell == null or placement_manager == null:
		return false

	var openings_by_surface: Dictionary = {
		RoomConstants.WALL_BACK: [],
		RoomConstants.WALL_LEFT: [],
		RoomConstants.WALL_FRONT: [],
		RoomConstants.WALL_RIGHT: [],
	}
	for placeable in placement_manager.get_wall_opening_placeables_cached():
		if not is_instance_valid(placeable):
			continue
		if not placeable.requires_wall_opening():
			continue

		var surface_name := String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
		if placement_active and is_instance_valid(preview_item) and placeable == preview_item and placement_manager._active_preview_is_wall_placeable():
			surface_name = active_surface_name
		append_wall_opening_for_placeable(openings_by_surface, placeable, surface_name)

	if placement_active and is_instance_valid(preview_item) and preview_item.requires_wall_opening() and preview_item.get_parent() != placed_items_root:
		append_wall_opening_for_placeable(openings_by_surface, preview_item, active_surface_name)

	var next_signature := build_wall_openings_signature(openings_by_surface)
	if next_signature == wall_openings_signature:
		return false

	wall_openings_signature = next_signature
	if room_shell.has_method("set_runtime_wall_openings_batch"):
		room_shell.call("set_runtime_wall_openings_batch", openings_by_surface)
		return true

	for surface_name in RoomConstants.WALL_SURFACES:
		var openings: Array[Dictionary] = []
		var raw_openings: Variant = openings_by_surface.get(surface_name, [])
		if raw_openings is Array:
			for raw_opening in raw_openings:
				if typeof(raw_opening) != TYPE_DICTIONARY:
					continue
				openings.append(raw_opening as Dictionary)
		room_shell.set_runtime_wall_openings(surface_name, openings)
	return true

func append_wall_opening_for_placeable(openings_by_surface: Dictionary, placeable: PlaceableItem, surface_name: String) -> void:
	if placeable == null or not is_instance_valid(placeable) or room_shell == null or not RoomConstants.is_wall_surface(surface_name):
		return

	var half_extents: Vector2 = placeable.get_wall_opening_half_extents()
	var center_u: float
	if surface_name == RoomConstants.WALL_BACK or surface_name == RoomConstants.WALL_FRONT:
		center_u = placeable.global_position.x - room_shell.global_position.x
	else:
		center_u = placeable.global_position.z - room_shell.global_position.z
	var center_v: float = placeable.global_position.y - room_shell.get_wall_bottom_y()

	var openings := openings_by_surface.get(surface_name, []) as Array
	openings.append(
		{
			"center_u": center_u,
			"center_v": center_v,
			"half_u": half_extents.x,
			"half_v": half_extents.y,
		}
	)
	openings_by_surface[surface_name] = openings

func build_wall_openings_signature(openings_by_surface: Dictionary) -> String:
	var parts: Array[String] = []
	for surface_name in RoomConstants.WALL_SURFACES:
		parts.append(String(surface_name))
		var raw_openings: Variant = openings_by_surface.get(surface_name, [])
		if raw_openings is Array:
			for raw_opening in raw_openings:
				if typeof(raw_opening) != TYPE_DICTIONARY:
					continue
				parts.append("%.3f,%.3f,%.3f,%.3f" % [
					float(raw_opening.get("center_u", 0.0)),
					float(raw_opening.get("center_v", 0.0)),
					float(raw_opening.get("half_u", 0.0)),
					float(raw_opening.get("half_v", 0.0)),
				])
	var signature := ""
	for part in parts:
		if not signature.is_empty():
			signature += "|"
		signature += part
	return signature

func clear() -> void:
	wall_openings_signature = ""
