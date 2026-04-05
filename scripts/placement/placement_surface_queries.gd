class_name PlacementSurfaceQueries
extends RefCounted

const RoomConstants := preload("res://scripts/room/room_constants.gd")

static func snap_position_to_grid(room_shell: RoomShell, target_position: Vector3, grid_size: float) -> Vector3:
	if room_shell == null:
		return target_position

	var grid_min := room_shell.global_position - Vector3(room_shell.get_inner_half_extents().x, 0.0, room_shell.get_inner_half_extents().y)
	var room_extents: Vector2 = room_shell.get_inner_half_extents()
	var cell_count_x: int = maxi(1, int(round(room_extents.x * 2.0 / grid_size)))
	var cell_count_z: int = maxi(1, int(round(room_extents.y * 2.0 / grid_size)))
	var snapped_cell_x: int = clampi(int(floor((target_position.x - grid_min.x) / grid_size)), 0, cell_count_x - 1)
	var snapped_cell_z: int = clampi(int(floor((target_position.z - grid_min.z) / grid_size)), 0, cell_count_z - 1)
	return Vector3(
		grid_min.x + (float(snapped_cell_x) + 0.5) * grid_size,
		room_shell.get_floor_y(),
		grid_min.z + (float(snapped_cell_z) + 0.5) * grid_size
	)

static func snap_wall_position(room_shell: RoomShell, active_surface_name: String, target_position: Vector3, wall_snap_size: float) -> Vector3:
	if room_shell == null:
		return target_position

	var horizontal_bounds := room_shell.get_wall_surface_horizontal_bounds(active_surface_name)
	var vertical_bounds := room_shell.get_wall_placement_vertical_bounds()
	var horizontal_span: float = horizontal_bounds.y - horizontal_bounds.x
	var vertical_span: float = vertical_bounds.y - vertical_bounds.x
	var horizontal_cells: int = maxi(1, int(round(horizontal_span / wall_snap_size)))
	var vertical_cells: int = maxi(1, int(round(vertical_span / wall_snap_size)))
	var horizontal_value := get_wall_surface_horizontal_value(active_surface_name, target_position)
	var horizontal_index := clampi(int(floor((horizontal_value - horizontal_bounds.x) / wall_snap_size)), 0, horizontal_cells - 1)
	var vertical_index := clampi(int(floor((target_position.y - vertical_bounds.x) / wall_snap_size)), 0, vertical_cells - 1)
	var snapped_horizontal := horizontal_bounds.x + (float(horizontal_index) + 0.5) * wall_snap_size
	var snapped_vertical := vertical_bounds.x + (float(vertical_index) + 0.5) * wall_snap_size
	return build_wall_surface_position(room_shell, active_surface_name, snapped_horizontal, snapped_vertical)

static func get_wall_snap_size(preview_item: SimpleWoodChair, grid_size: float, wall_snap_size: float) -> float:
	return wall_snap_size if is_wall_placeable(preview_item) else grid_size

static func get_supported_wall_surfaces(preview_item: SimpleWoodChair) -> Array[String]:
	var surfaces: Array[String] = []
	if preview_item == null:
		for surface_name in RoomConstants.WALL_SURFACES:
			surfaces.append(String(surface_name))
		return surfaces

	var supported_surfaces := preview_item.get_supported_wall_surfaces()
	if supported_surfaces.is_empty():
		for surface_name in RoomConstants.WALL_SURFACES:
			surfaces.append(String(surface_name))
		return surfaces

	for surface_name in supported_surfaces:
		surfaces.append(String(surface_name))
	return surfaces

static func try_get_best_supported_wall_hit(camera: Camera3D, room_shell: RoomShell, preview_item: SimpleWoodChair, mouse_position: Vector2) -> Dictionary:
	var best_hit := {"valid": false}
	var best_distance := INF
	for surface_name in get_supported_wall_surfaces(preview_item):
		var wall_hit := try_get_wall_plane_hit(camera, room_shell, mouse_position, surface_name)
		if not wall_hit.get("valid", false):
			continue

		var hit_distance := float(wall_hit.get("distance", INF))
		if hit_distance < best_distance:
			best_distance = hit_distance
			best_hit = wall_hit

	return best_hit

static func try_get_wall_plane_hit(camera: Camera3D, room_shell: RoomShell, mouse_position: Vector2, surface_name: String) -> Dictionary:
	if camera == null or room_shell == null or not RoomConstants.is_wall_surface(surface_name):
		return {"valid": false}
	if not room_shell.is_surface_visible(surface_name):
		return {"valid": false}
	if room_shell.is_surface_cutaway(surface_name):
		return {"valid": false}

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_position)
	var plane_coordinate := room_shell.get_wall_center_coordinate(surface_name)
	var hit_distance := 0.0
	match surface_name:
		RoomConstants.WALL_BACK, RoomConstants.WALL_FRONT:
			if absf(ray_normal.z) <= 0.0001:
				return {"valid": false}
			hit_distance = (plane_coordinate - ray_origin.z) / ray_normal.z
		RoomConstants.WALL_LEFT, RoomConstants.WALL_RIGHT:
			if absf(ray_normal.x) <= 0.0001:
				return {"valid": false}
			hit_distance = (plane_coordinate - ray_origin.x) / ray_normal.x
		_:
			return {"valid": false}
	if hit_distance <= 0.0:
		return {"valid": false}

	var hit_position := ray_origin + ray_normal * hit_distance
	var horizontal_bounds := room_shell.get_wall_surface_horizontal_bounds(surface_name)
	var vertical_bounds := room_shell.get_wall_placement_vertical_bounds()
	var horizontal_value := get_wall_surface_horizontal_value(surface_name, hit_position)
	if horizontal_value < horizontal_bounds.x - 0.001 or horizontal_value > horizontal_bounds.y + 0.001:
		return {"valid": false}
	if hit_position.y < vertical_bounds.x - 0.001 or hit_position.y > vertical_bounds.y + 0.001:
		return {"valid": false}

	return {
		"valid": true,
		"surface_name": surface_name,
		"distance": hit_distance,
		"position": build_wall_surface_position(room_shell, surface_name, horizontal_value, hit_position.y),
	}

static func try_get_floor_hit(camera: Camera3D, room_shell: RoomShell, mouse_position: Vector2) -> Dictionary:
	if camera == null or room_shell == null:
		return {"valid": false}

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_position)
	var floor_y := room_shell.get_floor_y()
	if absf(ray_normal.y) <= 0.0001:
		return {"valid": false}

	var hit_distance: float = (floor_y - ray_origin.y) / ray_normal.y
	if hit_distance <= 0.0:
		return {"valid": false}

	return {
		"valid": true,
		"position": ray_origin + ray_normal * hit_distance,
	}

static func raycast_from_mouse(space_state: PhysicsDirectSpaceState3D, camera: Camera3D, mouse_position: Vector2, collision_mask: int) -> Dictionary:
	if camera == null or space_state == null:
		return {}

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_position)
	var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 128.0, collision_mask)
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	return space_state.intersect_ray(ray_query)

static func get_floor_angle_around_preview(camera: Camera3D, room_shell: RoomShell, preview_item: SimpleWoodChair, mouse_position: Vector2) -> float:
	if preview_item == null:
		return 0.0

	var hit := try_get_floor_hit(camera, room_shell, mouse_position)
	if not hit.get("valid", false):
		return 0.0

	var hit_position := hit["position"] as Vector3
	var flat_offset := Vector2(
		hit_position.x - preview_item.global_position.x,
		hit_position.z - preview_item.global_position.z
	)
	if flat_offset.length_squared() <= 0.0001:
		return 0.0
	return flat_offset.angle()

static func get_wall_surface_horizontal_value(surface_name: String, position: Vector3) -> float:
	return position.x if surface_name == RoomConstants.WALL_BACK or surface_name == RoomConstants.WALL_FRONT else position.z

static func build_wall_surface_position(room_shell: RoomShell, surface_name: String, horizontal_value: float, vertical_value: float) -> Vector3:
	match surface_name:
		RoomConstants.WALL_BACK, RoomConstants.WALL_FRONT:
			return Vector3(horizontal_value, vertical_value, room_shell.get_wall_center_coordinate(surface_name))
		RoomConstants.WALL_LEFT, RoomConstants.WALL_RIGHT:
			return Vector3(room_shell.get_wall_center_coordinate(surface_name), vertical_value, horizontal_value)
		_:
			return Vector3(horizontal_value, vertical_value, room_shell.global_position.z)

static func is_wall_placeable(item: SimpleWoodChair) -> bool:
	return item != null and item.get_placement_surface_kind() == RoomConstants.SURFACE_DECOR
