extends RefCounted
class_name PlacementLayoutPersistence

const FLOOR_STYLE_COZY_BROWN := 0
const DEFAULT_SUPPORT_SURFACE_ID := "top"
const EDITOR_PREVIEW_POLL_SECONDS := 0.6

var placement_manager
var room_shell: RoomShell
var placed_items_root: Node3D

func save_layout() -> bool:
	if placement_manager == null:
		return false

	var layout := PlacementRoomLayoutStore.serialize_layout(
		placement_manager._placed_items_root,
		Callable(placement_manager, "_resolve_item_id_for_placeable"),
		Callable(placement_manager, "_get_placeable_instance_id"),
		placement_manager._get_current_floor_style(),
		placement_manager._item_owned_totals
	)
	return PlacementRoomLayoutStore.save_layout(layout)

func load_layout_data() -> Dictionary:
	return PlacementRoomLayoutStore.load_layout_data()

func build_default_owned_stock() -> Dictionary:
	var defaults: Dictionary = {}
	if placement_manager == null:
		return defaults

	for item_def in placement_manager._inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		defaults[item_id] = PlacementInventoryCatalog.get_initial_owned(item_def)
	return defaults

func build_owned_stock_from_layout(layout: Dictionary) -> Dictionary:
	var owned_stock := build_default_owned_stock()
	var loaded_owned_stock := PlacementRoomLayoutStore.deserialize_owned_stock(layout.get("owned_stock", {}))
	for item_id in loaded_owned_stock.keys():
		owned_stock[String(item_id)] = int(loaded_owned_stock[item_id])

	var raw_items: Variant = layout.get("items", [])
	if raw_items is Array:
		var placed_counts: Dictionary = {}
		for raw_item in raw_items:
			if typeof(raw_item) != TYPE_DICTIONARY:
				continue
			var item_entry := raw_item as Dictionary
			var item_id := String(item_entry.get("item_id", ""))
			if item_id.is_empty():
				continue
			placed_counts[item_id] = int(placed_counts.get(item_id, 0)) + 1
		for item_id in placed_counts.keys():
			owned_stock[item_id] = maxi(int(owned_stock.get(item_id, 0)), int(placed_counts[item_id]))

	return owned_stock

func apply_owned_stock_state(owned_stock: Dictionary) -> void:
	if placement_manager == null:
		return

	placement_manager._item_stock.clear()
	placement_manager._item_owned_totals.clear()
	for item_def in placement_manager._inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		var owned_total := maxi(0, int(owned_stock.get(item_id, PlacementInventoryCatalog.get_initial_owned(item_def))))
		placement_manager._item_owned_totals[item_id] = owned_total
		placement_manager._item_stock[item_id] = owned_total
		placement_manager._placed_item_counts[item_id] = 0

func rebuild_room_from_layout(layout: Dictionary) -> void:
	if placement_manager == null:
		return

	clear_room(false)
	apply_owned_stock_state(build_owned_stock_from_layout(layout))

	var resolved_room_shell := _get_room_shell()
	if resolved_room_shell != null and resolved_room_shell.has_method("set_floor_style"):
		resolved_room_shell.call("set_floor_style", int(layout.get("floor_style", FLOOR_STYLE_COZY_BROWN)))

	var raw_items: Variant = layout.get("items", [])
	if raw_items is Array:
		var root_items: Array[Dictionary] = []
		var hosted_items: Array[Dictionary] = []
		for raw_item in raw_items:
			if typeof(raw_item) != TYPE_DICTIONARY:
				continue
			var item_entry: Dictionary = raw_item
			var attachment: Dictionary = placement_manager._build_saved_attachment(item_entry)
			if String(attachment.get("kind", RoomConstants.ATTACHMENT_ROOM)) == RoomConstants.ATTACHMENT_SUPPORT_SURFACE:
				hosted_items.append(item_entry)
			else:
				root_items.append(item_entry)

		var loaded_instances: Dictionary = {}
		for item_entry in root_items:
			var loaded_placeable := instantiate_saved_item(item_entry, loaded_instances)
			if loaded_placeable == null:
				continue
			loaded_instances[placement_manager._get_placeable_instance_id(loaded_placeable)] = loaded_placeable

		var pending_hosted := hosted_items.duplicate()
		var made_progress := true
		while made_progress and not pending_hosted.is_empty():
			made_progress = false
			var next_pending: Array[Dictionary] = []
			for item_entry in pending_hosted:
				var loaded_placeable := instantiate_saved_item(item_entry, loaded_instances)
				if loaded_placeable == null:
					next_pending.append(item_entry)
					continue
				loaded_instances[placement_manager._get_placeable_instance_id(loaded_placeable)] = loaded_placeable
				made_progress = true
			pending_hosted = next_pending

		if not pending_hosted.is_empty():
			push_warning("Skipped %d hosted layout item(s) because their host instance was unavailable." % pending_hosted.size())

	placement_manager._on_placeable_batch_rebuilt()

func load_layout() -> bool:
	var layout := load_layout_data()
	if layout.is_empty():
		return false

	rebuild_room_from_layout(layout)
	return true

func load_layout_on_startup() -> void:
	if Engine.is_editor_hint():
		refresh_editor_preview_from_saved_layout(true)
		return
	load_layout()

func process_editor_preview(delta: float) -> void:
	if placement_manager == null:
		return

	placement_manager._editor_preview_poll_time -= delta
	if placement_manager._editor_preview_poll_time > 0.0:
		return

	placement_manager._editor_preview_poll_time = EDITOR_PREVIEW_POLL_SECONDS
	refresh_editor_preview_from_saved_layout()

func refresh_editor_preview_from_saved_layout(force: bool = false) -> void:
	if placement_manager == null:
		return

	var layout_signature := PlacementRoomLayoutStore.get_file_signature()
	if not force and layout_signature == placement_manager._editor_preview_layout_signature:
		return

	placement_manager._editor_preview_layout_signature = layout_signature
	if layout_signature.is_empty():
		clear_editor_preview_layout()
		return

	var layout := load_layout_data()
	if layout.is_empty():
		clear_editor_preview_layout()
		return

	rebuild_room_from_layout(layout)

func clear_editor_preview_layout() -> void:
	if placement_manager == null or placement_manager._placed_items_root == null:
		return

	for child in placement_manager._placed_items_root.get_children():
		child.free()

	placement_manager._initialize_inventory_state()
	var resolved_room_shell := _get_room_shell()
	if resolved_room_shell != null and resolved_room_shell.has_method("set_floor_style"):
		resolved_room_shell.call("set_floor_style", placement_manager._editor_default_floor_style)
	if placement_manager._wall_opening_sync != null:
		placement_manager._wall_opening_sync.clear()
	placement_manager._wall_openings_signature = ""
	placement_manager._invalidate_placeables_registry_structure()
	placement_manager._request_wall_openings_refresh()
	placement_manager._sync_room_wall_openings()

func instantiate_saved_item(item_entry: Dictionary, loaded_instances: Dictionary = {}) -> PlaceableItem:
	if placement_manager == null:
		return null

	var item_id := String(item_entry.get("item_id", ""))
	if item_id.is_empty():
		return null

	var placeable: PlaceableItem = placement_manager._create_item_instance(item_id)
	if placeable == null:
		return null

	var attachment: Dictionary = placement_manager._build_saved_attachment(item_entry)
	var attachment_kind := String(attachment.get("kind", RoomConstants.ATTACHMENT_ROOM))
	var rotation_y := float(item_entry.get("rotation_y", 0.0))
	var instance_id := String(item_entry.get("instance_id", ""))

	var placed_count: int = int(placement_manager._placed_item_counts.get(item_id, 0)) + 1
	placement_manager._placed_item_counts[item_id] = placed_count
	placement_manager._ensure_placeable_metadata(placeable, item_id, instance_id)
	placeable.name = "%s %d" % [placement_manager._get_item_display_name(item_id), placed_count]

	if attachment_kind == RoomConstants.ATTACHMENT_SUPPORT_SURFACE:
		var host_instance_id := String(attachment.get("host_instance_id", ""))
		var host_placeable := loaded_instances.get(host_instance_id, null) as PlaceableItem
		if host_placeable == null:
			placeable.free()
			return null
		host_placeable.add_child(placeable)
		placeable.position = PlacementRoomLayoutStore.deserialize_vector3(item_entry.get("position", {}))
		placeable.rotation.y = rotation_y
		placement_manager._set_support_attachment_metadata(placeable, host_placeable, String(attachment.get("surface_id", DEFAULT_SUPPORT_SURFACE_ID)))
	else:
		var world_position := PlacementRoomLayoutStore.deserialize_vector3(item_entry.get("position", {}))
		var placement_surface := String(attachment.get("surface", item_entry.get("placement_surface", RoomConstants.FLOOR_SURFACE)))
		if placement_manager._is_wall_placeable(placeable) and RoomConstants.is_wall_surface(placement_surface):
			rotation_y = RoomConstants.get_wall_rotation(placement_surface) + placeable.get_wall_rotation_offset()
			var resolved_room_shell := _get_room_shell()
			if resolved_room_shell != null:
				var horizontal_value := PlacementSurfaceQueries.get_wall_surface_horizontal_value(placement_surface, world_position)
				world_position = PlacementSurfaceQueries.build_wall_mount_position(resolved_room_shell, placement_surface, horizontal_value, world_position.y, placeable)
		var placement_transform := Transform3D(Basis.IDENTITY.rotated(Vector3.UP, rotation_y), world_position)
		placement_manager._placed_items_root.add_child(placeable)
		placeable.global_transform = placement_transform
		placement_manager._set_room_attachment_metadata(placeable, placement_surface)

	placeable.set_preview_mode(false)
	placement_manager._apply_cutaway_to_placeable(placeable)
	placement_manager._item_stock[item_id] = maxi(0, int(placement_manager._item_stock.get(item_id, 0)) - 1)
	return placeable

func autosave_room_layout() -> void:
	save_layout()

func clear_room(save_after_clear: bool = true) -> void:
	if placement_manager == null or placement_manager._placed_items_root == null:
		return

	if placement_manager._placement_active:
		placement_manager._cancel_current_placement()

	for child in placement_manager._placed_items_root.get_children():
		child.free()

	for item_id in placement_manager._item_owned_totals.keys():
		placement_manager._item_stock[item_id] = int(placement_manager._item_owned_totals.get(item_id, 0))
		placement_manager._placed_item_counts[item_id] = 0
	if placement_manager._wall_opening_sync != null:
		placement_manager._wall_opening_sync.clear()
	placement_manager._wall_openings_signature = ""
	placement_manager._invalidate_placeables_registry_structure()
	placement_manager._request_wall_openings_refresh()
	if save_after_clear:
		autosave_room_layout()
		placement_manager._on_placeable_batch_rebuilt()

func _get_room_shell() -> RoomShell:
	if placement_manager != null and placement_manager._room_shell != null:
		return placement_manager._room_shell
	return room_shell
