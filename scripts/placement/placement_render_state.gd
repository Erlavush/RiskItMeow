extends RefCounted
class_name PlacementRenderState

var placement_manager
var room_shell: RoomShell
var placed_items_root: Node3D
var wall_surface_cutaway_states: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
}
var ceiling_surface_cutaway := false

func set_wall_surface_cutaway(surface_name: String, is_cutaway: bool) -> void:
	if not wall_surface_cutaway_states.has(surface_name):
		return

	wall_surface_cutaway_states[surface_name] = bool(is_cutaway)
	apply_cutaway_to_surface(surface_name)

func set_ceiling_surface_cutaway(is_cutaway: bool) -> void:
	ceiling_surface_cutaway = bool(is_cutaway)
	apply_cutaway_to_surface(RoomConstants.CEILING_SURFACE)

func clear_wall_surface_cutaways() -> void:
	for surface_name in wall_surface_cutaway_states.keys():
		wall_surface_cutaway_states[surface_name] = false
		apply_cutaway_to_surface(String(surface_name))
	ceiling_surface_cutaway = false
	apply_cutaway_to_surface(RoomConstants.CEILING_SURFACE)

func apply_cutaway_to_surface(_surface_name: String) -> void:
	if placement_manager == null or _get_placed_items_root() == null:
		return

	for root_placeable in _get_cutaway_root_placeables(_surface_name):
		_apply_cutaway_to_placeable_subtree(root_placeable)

func apply_cutaway_to_placeable(placeable: PlaceableItem) -> void:
	if placeable == null:
		return

	placeable.set_camera_cutaway(is_placeable_effectively_cutaway(placeable))

func is_placeable_effectively_cutaway(placeable: PlaceableItem) -> bool:
	if placement_manager == null:
		return false

	var current: Node = placeable
	var resolved_root := _get_placed_items_root()
	while current != null and current != resolved_root:
		var current_placeable := current as PlaceableItem
		if current_placeable != null:
			if placement_manager._is_ceiling_placeable(current_placeable) and ceiling_surface_cutaway:
				return true
			if placement_manager._is_wall_placeable(current_placeable):
				var placement_surface := String(current_placeable.get_meta("placement_surface")) if current_placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
				if _is_preview_placeable(current_placeable) and placement_manager._active_preview_is_wall_placeable():
					placement_surface = String(placement_manager._active_surface_name)
				if bool(wall_surface_cutaway_states.get(placement_surface, false)):
					return true
		current = current.get_parent()
	return false

func _get_placed_items_root() -> Node3D:
	if placement_manager != null and placement_manager._placed_items_root != null:
		return placement_manager._placed_items_root
	return placed_items_root

func _get_cutaway_root_placeables(surface_name: String) -> Array[PlaceableItem]:
	if placement_manager == null:
		return []
	if surface_name == RoomConstants.CEILING_SURFACE:
		return placement_manager.get_ceiling_placeables()
	if RoomConstants.is_wall_surface(surface_name):
		return placement_manager.get_wall_placeables_for_surface(surface_name)
	return []

func _apply_cutaway_to_placeable_subtree(root_placeable: PlaceableItem) -> void:
	if root_placeable == null or placement_manager == null:
		return

	for placeable in placement_manager.collect_placeable_subtree(root_placeable):
		if placeable == null or not is_instance_valid(placeable):
			continue
		if _is_preview_placeable(placeable):
			placeable.set_camera_cutaway(false)
			continue
		placeable.set_camera_cutaway(is_placeable_effectively_cutaway(placeable))

func _is_preview_placeable(placeable: PlaceableItem) -> bool:
	return placement_manager != null \
		and bool(placement_manager._placement_active) \
		and placeable == placement_manager._preview_item
