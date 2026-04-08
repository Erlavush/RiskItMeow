class_name PlacementValidator
extends RefCounted

static func evaluate_preview_transform(
	world_3d: World3D,
	room_shell: RoomShell,
	preview_item: SimpleWoodChair,
	active_surface_name: String,
	placement_query_shape: Shape3D,
	excluded_rids: Array[RID] = []
) -> Dictionary:
	if preview_item == null or room_shell == null or world_3d == null:
		return {"valid": false, "code": "missing", "reason": "Placement unavailable"}

	if PlacementSurfaceQueries.is_wall_placeable(preview_item):
		return _evaluate_wall_preview_transform(world_3d, room_shell, preview_item, active_surface_name, placement_query_shape, excluded_rids)
	if PlacementSurfaceQueries.is_ceiling_placeable(preview_item):
		return _evaluate_ceiling_preview_transform(world_3d, room_shell, preview_item, active_surface_name, placement_query_shape, excluded_rids)

	var room_origin: Vector3 = room_shell.global_position
	var room_half_extents := room_shell.get_inner_half_extents()
	var footprint := preview_item.get_footprint_half_extents()
	var local_x: float = preview_item.global_position.x - room_origin.x
	var local_z: float = preview_item.global_position.z - room_origin.z

	if absf(local_x) + footprint.x > room_half_extents.x:
		return {"valid": false, "code": "bounds", "reason": "Too close to edge"}
	if absf(local_z) + footprint.y > room_half_extents.y:
		return {"valid": false, "code": "bounds", "reason": "Too close to edge"}

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = placement_query_shape
	query.collision_mask = SimpleWoodChair.COLLISION_LAYER
	query.exclude = excluded_rids
	query.transform = Transform3D(
		Basis.IDENTITY.rotated(Vector3.UP, preview_item.rotation.y),
		preview_item.global_position + preview_item.get_collision_center_offset()
	)

	if not world_3d.direct_space_state.intersect_shape(query, 4).is_empty():
		return {"valid": false, "code": "occupied", "reason": "Space occupied"}

	return {"valid": true, "code": "valid", "reason": "Ready to place"}

static func _evaluate_ceiling_preview_transform(
	world_3d: World3D,
	room_shell: RoomShell,
	preview_item: SimpleWoodChair,
	active_surface_name: String,
	placement_query_shape: Shape3D,
	excluded_rids: Array[RID] = []
) -> Dictionary:
	if active_surface_name != RoomConstants.CEILING_SURFACE:
		return {"valid": false, "code": "surface", "reason": "Select the ceiling"}
	if not room_shell.is_surface_visible(RoomConstants.CEILING_SURFACE):
		return {"valid": false, "code": "surface", "reason": "Ceiling hidden"}

	var room_origin: Vector3 = room_shell.global_position
	var room_half_extents := room_shell.get_inner_half_extents()
	var footprint := preview_item.get_footprint_half_extents()
	var local_x: float = preview_item.global_position.x - room_origin.x
	var local_z: float = preview_item.global_position.z - room_origin.z

	if absf(local_x) + footprint.x > room_half_extents.x:
		return {"valid": false, "code": "bounds", "reason": "Too close to ceiling edge"}
	if absf(local_z) + footprint.y > room_half_extents.y:
		return {"valid": false, "code": "bounds", "reason": "Too close to ceiling edge"}
	if absf(preview_item.global_position.y - room_shell.get_ceiling_y()) > 0.02:
		return {"valid": false, "code": "surface", "reason": "Move onto the ceiling"}

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = placement_query_shape
	query.collision_mask = SimpleWoodChair.COLLISION_LAYER
	query.exclude = excluded_rids
	query.transform = Transform3D(
		Basis.IDENTITY.rotated(Vector3.UP, preview_item.rotation.y),
		preview_item.global_position + preview_item.get_collision_center_offset()
	)
	if not world_3d.direct_space_state.intersect_shape(query, 4).is_empty():
		return {"valid": false, "code": "occupied", "reason": "Space occupied"}

	return {"valid": true, "code": "valid", "reason": "Ready to place"}

static func _evaluate_wall_preview_transform(
	world_3d: World3D,
	room_shell: RoomShell,
	preview_item: SimpleWoodChair,
	active_surface_name: String,
	placement_query_shape: Shape3D,
	excluded_rids: Array[RID] = []
) -> Dictionary:
	if not RoomConstants.is_wall_surface(active_surface_name):
		return {"valid": false, "code": "surface", "reason": "Select a wall"}
	if not room_shell.is_surface_visible(active_surface_name):
		return {"valid": false, "code": "surface", "reason": "Wall hidden"}

	var supported_surfaces: Array[String] = preview_item.get_supported_wall_surfaces()
	if not supported_surfaces.is_empty() and not supported_surfaces.has(active_surface_name):
		return {"valid": false, "code": "surface", "reason": "Wrong wall"}

	var wall_half_extents := preview_item.get_wall_half_extents()
	var horizontal_bounds := room_shell.get_wall_surface_horizontal_bounds(active_surface_name)
	var vertical_bounds := room_shell.get_wall_placement_vertical_bounds()
	var horizontal_value := PlacementSurfaceQueries.get_wall_surface_horizontal_value(active_surface_name, preview_item.global_position)
	var vertical_value := preview_item.global_position.y

	if horizontal_value - wall_half_extents.x < horizontal_bounds.x or horizontal_value + wall_half_extents.x > horizontal_bounds.y:
		return {"valid": false, "code": "bounds", "reason": "Too close to wall edge"}
	if vertical_value - wall_half_extents.y < vertical_bounds.x or vertical_value + wall_half_extents.y > vertical_bounds.y:
		return {"valid": false, "code": "bounds", "reason": "Too close to wall top or floor"}

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = placement_query_shape
	query.collision_mask = SimpleWoodChair.COLLISION_LAYER
	query.exclude = excluded_rids
	query.transform = preview_item.global_transform.translated_local(preview_item.get_collision_center_offset())
	if not world_3d.direct_space_state.intersect_shape(query, 4).is_empty():
		return {"valid": false, "code": "occupied", "reason": "Space occupied"}

	return {"valid": true, "code": "valid", "reason": "Ready to place"}
