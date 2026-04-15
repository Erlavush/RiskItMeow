extends RefCounted
class_name PlacementPlaceablesRegistry

const WINDOW_ITEM_IDS := ["window", "window_classic"]

var placement_manager
var placed_items_root: Node3D

var structure_version := 0
var wall_openings_version := 0
var support_hosts_version := 0
var window_version := 0
var render_version := 0

var _dirty := true
var _all_placeables: Array[SimpleWoodChair] = []
var _root_placeables: Array[SimpleWoodChair] = []
var _wall_back_placeables: Array[SimpleWoodChair] = []
var _wall_left_placeables: Array[SimpleWoodChair] = []
var _wall_front_placeables: Array[SimpleWoodChair] = []
var _wall_right_placeables: Array[SimpleWoodChair] = []
var _ceiling_placeables: Array[SimpleWoodChair] = []
var _wall_opening_placeables: Array[SimpleWoodChair] = []
var _support_surface_hosts: Array[SimpleWoodChair] = []
var _window_placeables: Array[SimpleWoodChair] = []
var _by_instance_id: Dictionary = {}

func invalidate_structure() -> void:
	_dirty = true

func invalidate_visuals() -> void:
	render_version += 1

func rebuild_if_needed() -> void:
	if not _dirty:
		return
	if placement_manager == null or placed_items_root == null:
		_all_placeables.clear()
		_root_placeables.clear()
		_wall_back_placeables.clear()
		_wall_left_placeables.clear()
		_wall_front_placeables.clear()
		_wall_right_placeables.clear()
		_ceiling_placeables.clear()
		_wall_opening_placeables.clear()
		_support_surface_hosts.clear()
		_window_placeables.clear()
		_by_instance_id.clear()
		return

	_all_placeables.clear()
	_root_placeables.clear()
	_wall_back_placeables.clear()
	_wall_left_placeables.clear()
	_wall_front_placeables.clear()
	_wall_right_placeables.clear()
	_ceiling_placeables.clear()
	_wall_opening_placeables.clear()
	_support_surface_hosts.clear()
	_window_placeables.clear()
	_by_instance_id.clear()
	_collect_placeables_recursive(placed_items_root)
	_dirty = false
	structure_version += 1
	wall_openings_version += 1
	support_hosts_version += 1
	window_version += 1
	render_version += 1

func clear() -> void:
	_dirty = true
	_all_placeables.clear()
	_root_placeables.clear()
	_wall_back_placeables.clear()
	_wall_left_placeables.clear()
	_wall_front_placeables.clear()
	_wall_right_placeables.clear()
	_ceiling_placeables.clear()
	_wall_opening_placeables.clear()
	_support_surface_hosts.clear()
	_window_placeables.clear()
	_by_instance_id.clear()

func get_all_placeables() -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	return _all_placeables

func get_root_placeables() -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	return _root_placeables

func get_wall_placeables_for_surface(surface_name: String) -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	match surface_name:
		RoomConstants.WALL_BACK:
			return _wall_back_placeables
		RoomConstants.WALL_LEFT:
			return _wall_left_placeables
		RoomConstants.WALL_FRONT:
			return _wall_front_placeables
		RoomConstants.WALL_RIGHT:
			return _wall_right_placeables
		_:
			return []

func get_wall_opening_placeables() -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	return _wall_opening_placeables

func get_ceiling_placeables() -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	return _ceiling_placeables

func get_support_surface_hosts(preview_item: SimpleWoodChair = null, render_state: PlacementRenderState = null) -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	var hosts: Array[SimpleWoodChair] = []
	for host in _support_surface_hosts:
		if host == null or not is_instance_valid(host):
			continue
		if preview_item != null and host == preview_item:
			continue
		if render_state != null and render_state.is_placeable_effectively_cutaway(host):
			continue
		hosts.append(host)
	return hosts

func get_window_placeables() -> Array[SimpleWoodChair]:
	rebuild_if_needed()
	return _window_placeables

func get_placeable_by_instance_id(instance_id: String) -> SimpleWoodChair:
	if instance_id.is_empty():
		return null
	rebuild_if_needed()
	return _by_instance_id.get(instance_id, null) as SimpleWoodChair

func collect_placeable_subtree(root_placeable: SimpleWoodChair) -> Array[SimpleWoodChair]:
	var subtree: Array[SimpleWoodChair] = []
	if root_placeable == null or not is_instance_valid(root_placeable):
		return subtree

	subtree.append(root_placeable)
	_collect_placeable_descendants(root_placeable, subtree)
	return subtree

func _collect_placeables_recursive(node: Node) -> void:
	for child in node.get_children():
		var placeable := child as SimpleWoodChair
		if placeable != null:
			_register_placeable(placeable, node == placed_items_root)
			_collect_placeables_recursive(placeable)
			continue
		_collect_placeables_recursive(child)

func _register_placeable(placeable: SimpleWoodChair, is_root_placeable: bool) -> void:
	if placeable == null or not is_instance_valid(placeable):
		return

	_all_placeables.append(placeable)
	if is_root_placeable:
		_root_placeables.append(placeable)
	if placeable.can_host_surface_items():
		_support_surface_hosts.append(placeable)
	if placeable.requires_wall_opening():
		_wall_opening_placeables.append(placeable)

	if placement_manager._is_wall_placeable(placeable):
		var placement_surface := String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
		match placement_surface:
			RoomConstants.WALL_BACK:
				_wall_back_placeables.append(placeable)
			RoomConstants.WALL_LEFT:
				_wall_left_placeables.append(placeable)
			RoomConstants.WALL_FRONT:
				_wall_front_placeables.append(placeable)
			RoomConstants.WALL_RIGHT:
				_wall_right_placeables.append(placeable)

	if placement_manager._is_ceiling_placeable(placeable):
		_ceiling_placeables.append(placeable)

	var item_id := String(placeable.get_meta("item_id")) if placeable.has_meta("item_id") else ""
	if WINDOW_ITEM_IDS.has(item_id):
		_window_placeables.append(placeable)

	if placeable.has_meta("instance_id"):
		var instance_id := String(placeable.get_meta("instance_id"))
		if not instance_id.is_empty():
			_by_instance_id[instance_id] = placeable

func _collect_placeable_descendants(node: Node, output: Array[SimpleWoodChair]) -> void:
	for child in node.get_children():
		var placeable := child as SimpleWoodChair
		if placeable != null:
			output.append(placeable)
			_collect_placeable_descendants(placeable, output)
			continue
		_collect_placeable_descendants(child, output)
