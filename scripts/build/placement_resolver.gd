class_name PlacementResolver
extends RefCounted

const BuildItemRegistry := preload("res://scripts/build/build_item_registry.gd")
const PlacementTypes := preload("res://scripts/build/placement_types.gd")
const RoomConstants := preload("res://scripts/room/room_constants.gd")

func resolve_from_view_ray(
	ray_origin: Vector3,
	ray_direction: Vector3,
	item_definition: Dictionary,
	room_shell: Node,
	placed_items: Array,
	rotation_y: float
) -> Dictionary:
	var family := str(item_definition.get("family", ""))
	match family:
		PlacementTypes.FAMILY_FLOOR:
			return _resolve_floor_placement(ray_origin, ray_direction, item_definition, room_shell, placed_items, rotation_y)
		PlacementTypes.FAMILY_WALL:
			return _resolve_wall_placement(ray_origin, ray_direction, item_definition, room_shell, placed_items)
		PlacementTypes.FAMILY_CEILING:
			return _resolve_ceiling_placement(ray_origin, ray_direction, item_definition, room_shell, placed_items, rotation_y)
		PlacementTypes.FAMILY_SURFACE:
			return _resolve_surface_placement(ray_origin, ray_direction, item_definition, placed_items, rotation_y)
		_:
			return {}

func get_floor_obstacles(placed_items: Array) -> Array[Dictionary]:
	var obstacles: Array[Dictionary] = []
	for item in placed_items:
		if str(item.get("surface", "")) != PlacementTypes.SURFACE_FLOOR:
			continue

		var definition := BuildItemRegistry.get_definition(str(item.get("item_id", "")))
		var footprint := _get_rotated_footprint(definition, float(item.get("rotation_y", 0.0)))
		obstacles.append({
			"center": item.get("position"),
			"half": footprint * 0.5,
		})
	return obstacles

func _resolve_floor_placement(
	ray_origin: Vector3,
	ray_direction: Vector3,
	item_definition: Dictionary,
	room_shell: Node,
	placed_items: Array,
	rotation_y: float
) -> Dictionary:
	var floor_y: float = float(room_shell.call("get_floor_y"))
	var intersection := _intersect_horizontal_plane(ray_origin, ray_direction, floor_y)
	if intersection.is_empty():
		return {}

	var position := intersection["position"] as Vector3
	var footprint := _get_rotated_footprint(item_definition, rotation_y)
	var half_extents: Vector2 = room_shell.call("get_inner_half_extents")
	var snapped_x := _snap_value(position.x, PlacementTypes.GRID_SIZE)
	var snapped_z := _snap_value(position.z, PlacementTypes.GRID_SIZE)
	var clamped_x := clampf(snapped_x, -half_extents.x + footprint.x * 0.5, half_extents.x - footprint.x * 0.5)
	var clamped_z := clampf(snapped_z, -half_extents.y + footprint.y * 0.5, half_extents.y - footprint.y * 0.5)
	var placement := {
		"position": Vector3(clamped_x, floor_y, clamped_z),
		"rotation_y": rotation_y,
		"surface": PlacementTypes.SURFACE_FLOOR,
	}
	if _has_floor_overlap(placement, item_definition, placed_items):
		return {}
	return placement

func _resolve_ceiling_placement(
	ray_origin: Vector3,
	ray_direction: Vector3,
	item_definition: Dictionary,
	room_shell: Node,
	placed_items: Array,
	rotation_y: float
) -> Dictionary:
	var ceiling_y: float = float(room_shell.call("get_ceiling_y"))
	var intersection := _intersect_horizontal_plane(ray_origin, ray_direction, ceiling_y)
	if intersection.is_empty():
		return {}

	var position := intersection["position"] as Vector3
	var footprint := _get_rotated_footprint(item_definition, rotation_y)
	var half_extents: Vector2 = room_shell.call("get_inner_half_extents")
	var snapped_x := _snap_value(position.x, PlacementTypes.GRID_SIZE)
	var snapped_z := _snap_value(position.z, PlacementTypes.GRID_SIZE)
	var clamped_x := clampf(snapped_x, -half_extents.x + footprint.x * 0.5, half_extents.x - footprint.x * 0.5)
	var clamped_z := clampf(snapped_z, -half_extents.y + footprint.y * 0.5, half_extents.y - footprint.y * 0.5)
	var placement := {
		"position": Vector3(clamped_x, ceiling_y, clamped_z),
		"rotation_y": rotation_y,
		"surface": PlacementTypes.SURFACE_CEILING,
	}
	if _has_floor_overlap(placement, item_definition, placed_items):
		return {}
	return placement

func _resolve_wall_placement(
	ray_origin: Vector3,
	ray_direction: Vector3,
	item_definition: Dictionary,
	room_shell: Node,
	placed_items: Array
) -> Dictionary:
	var best_hit: Dictionary = {}
	var best_distance := INF
	for surface in PlacementTypes.WALL_SURFACES:
		var hit := _intersect_wall_plane(ray_origin, ray_direction, surface, room_shell)
		if hit.is_empty():
			continue

		var hit_distance: float = float(hit.get("distance", INF))
		if hit_distance < best_distance:
			best_distance = hit_distance
			best_hit = hit

	if best_hit.is_empty():
		return {}

	var hit_position := best_hit["position"] as Vector3
	var surface_name := str(best_hit.get("surface", ""))
	var footprint: Vector2 = item_definition.get("footprint", Vector2.ONE)
	var snapped_parallel := _snap_value(float(best_hit.get("parallel", 0.0)), PlacementTypes.GRID_SIZE)
	var snapped_height := _snap_value(hit_position.y, PlacementTypes.GRID_SIZE)
	var floor_y: float = float(room_shell.call("get_floor_y"))
	var ceiling_y: float = float(room_shell.call("get_ceiling_y"))
	var clamped_y := clampf(
		snapped_height,
		floor_y + footprint.y * 0.5,
		ceiling_y - footprint.y * 0.5 - 0.1
	)
	var placement := {
		"rotation_y": RoomConstants.get_wall_rotation(surface_name),
		"surface": surface_name,
	}
	match surface_name:
		PlacementTypes.SURFACE_WALL_BACK, PlacementTypes.SURFACE_WALL_FRONT:
			var half_extents: Vector2 = room_shell.call("get_inner_half_extents")
			var clamped_x := clampf(snapped_parallel, -half_extents.x + footprint.x * 0.5, half_extents.x - footprint.x * 0.5)
			placement["position"] = Vector3(clamped_x, clamped_y, float(room_shell.call("get_wall_surface_coordinate", surface_name)))
		PlacementTypes.SURFACE_WALL_LEFT, PlacementTypes.SURFACE_WALL_RIGHT:
			var wall_depth: Vector2 = room_shell.call("get_inner_half_extents")
			var clamped_z := clampf(snapped_parallel, -wall_depth.y + footprint.x * 0.5, wall_depth.y - footprint.x * 0.5)
			placement["position"] = Vector3(float(room_shell.call("get_wall_surface_coordinate", surface_name)), clamped_y, clamped_z)

	if _has_wall_overlap(placement, item_definition, placed_items):
		return {}
	return placement

func _resolve_surface_placement(
	ray_origin: Vector3,
	ray_direction: Vector3,
	item_definition: Dictionary,
	placed_items: Array,
	rotation_y: float
) -> Dictionary:
	var best_candidate: Dictionary = {}
	var best_distance := INF
	for host in placed_items:
		var host_item_id := str(host.get("item_id", ""))
		if not BuildItemRegistry.supports_surface_host(host_item_id):
			continue

		var host_definition := BuildItemRegistry.get_definition(host_item_id)
		var support_height: float = float(host_definition.get("support_surface_height", 0.0))
		var top_y := float((host.get("position") as Vector3).y) + support_height
		var hit := _intersect_horizontal_plane(ray_origin, ray_direction, top_y)
		if hit.is_empty():
			continue

		var hit_distance: float = float(hit.get("distance", INF))
		if hit_distance >= best_distance:
			continue

		var hit_position := hit["position"] as Vector3
		var local_offset := _world_to_host_local(host, hit_position)
		var support_size: Vector2 = host_definition.get("support_surface_size", Vector2.ONE)
		var footprint := _get_rotated_footprint(item_definition, rotation_y)
		var max_x: float = max(0.0, support_size.x * 0.5 - footprint.x * 0.5)
		var max_z: float = max(0.0, support_size.y * 0.5 - footprint.y * 0.5)
		if abs(local_offset.x) > max_x + PlacementTypes.SURFACE_DECOR_GRID or abs(local_offset.y) > max_z + PlacementTypes.SURFACE_DECOR_GRID:
			continue

		var snapped_local_x := clampf(_snap_value(local_offset.x, PlacementTypes.SURFACE_DECOR_GRID), -max_x, max_x)
		var snapped_local_z := clampf(_snap_value(local_offset.y, PlacementTypes.SURFACE_DECOR_GRID), -max_z, max_z)
		best_distance = hit_distance
		best_candidate = {
			"position": _host_local_to_world(host, Vector2(snapped_local_x, snapped_local_z), support_height),
			"rotation_y": rotation_y,
			"surface": PlacementTypes.SURFACE_SURFACE,
			"anchor_item_id": host.get("instance_id"),
			"local_offset": Vector2(snapped_local_x, snapped_local_z),
		}

	if best_candidate.is_empty():
		return {}
	if _has_surface_overlap(best_candidate, item_definition, placed_items):
		return {}
	return best_candidate

func _intersect_horizontal_plane(ray_origin: Vector3, ray_direction: Vector3, plane_y: float) -> Dictionary:
	if abs(ray_direction.y) <= 0.0001:
		return {}

	var distance := (plane_y - ray_origin.y) / ray_direction.y
	if distance <= 0.0:
		return {}

	return {
		"distance": distance,
		"position": ray_origin + ray_direction * distance,
	}

func _intersect_wall_plane(ray_origin: Vector3, ray_direction: Vector3, surface: String, room_shell: Node) -> Dictionary:
	var wall_coordinate: float = float(room_shell.call("get_wall_surface_coordinate", surface))
	var floor_y: float = float(room_shell.call("get_floor_y"))
	var ceiling_y: float = float(room_shell.call("get_ceiling_y"))
	var half_extents: Vector2 = room_shell.call("get_inner_half_extents")
	var distance := INF
	var hit_position := Vector3.ZERO

	match surface:
		PlacementTypes.SURFACE_WALL_BACK, PlacementTypes.SURFACE_WALL_FRONT:
			if abs(ray_direction.z) <= 0.0001:
				return {}
			distance = (wall_coordinate - ray_origin.z) / ray_direction.z
			if distance <= 0.0:
				return {}
			hit_position = ray_origin + ray_direction * distance
			if abs(hit_position.x) > half_extents.x + 0.001:
				return {}
			if hit_position.y < floor_y + 0.3 or hit_position.y > ceiling_y - 0.2:
				return {}
			return {
				"surface": surface,
				"distance": distance,
				"position": hit_position,
				"parallel": hit_position.x,
			}
		PlacementTypes.SURFACE_WALL_LEFT, PlacementTypes.SURFACE_WALL_RIGHT:
			if abs(ray_direction.x) <= 0.0001:
				return {}
			distance = (wall_coordinate - ray_origin.x) / ray_direction.x
			if distance <= 0.0:
				return {}
			hit_position = ray_origin + ray_direction * distance
			if abs(hit_position.z) > half_extents.y + 0.001:
				return {}
			if hit_position.y < floor_y + 0.3 or hit_position.y > ceiling_y - 0.2:
				return {}
			return {
				"surface": surface,
				"distance": distance,
				"position": hit_position,
				"parallel": hit_position.z,
			}
		_:
			return {}

func _get_rotated_footprint(item_definition: Dictionary, rotation_y: float) -> Vector2:
	var base: Vector2 = item_definition.get("footprint", Vector2.ONE)
	var cos_y: float = abs(cos(rotation_y))
	var sin_y: float = abs(sin(rotation_y))
	return Vector2(
		base.x * cos_y + base.y * sin_y,
		base.x * sin_y + base.y * cos_y
	)

func _has_floor_overlap(placement: Dictionary, item_definition: Dictionary, placed_items: Array) -> bool:
	var footprint := _get_rotated_footprint(item_definition, float(placement.get("rotation_y", 0.0)))
	var position := placement.get("position") as Vector3
	var surface_name := str(placement.get("surface", ""))
	for existing in placed_items:
		if str(existing.get("surface", "")) != surface_name:
			continue
		if str(existing.get("surface", "")) == PlacementTypes.SURFACE_SURFACE:
			continue

		var existing_definition := BuildItemRegistry.get_definition(str(existing.get("item_id", "")))
		var existing_footprint := _get_rotated_footprint(existing_definition, float(existing.get("rotation_y", 0.0)))
		var existing_position := existing.get("position") as Vector3
		if abs(existing_position.x - position.x) < (existing_footprint.x + footprint.x) * 0.5 - 0.02 and abs(existing_position.z - position.z) < (existing_footprint.y + footprint.y) * 0.5 - 0.02:
			return true
	return false

func _has_wall_overlap(placement: Dictionary, item_definition: Dictionary, placed_items: Array) -> bool:
	var surface_name := str(placement.get("surface", ""))
	var position := placement.get("position") as Vector3
	var footprint: Vector2 = item_definition.get("footprint", Vector2.ONE)
	for existing in placed_items:
		if str(existing.get("surface", "")) != surface_name:
			continue

		var existing_definition := BuildItemRegistry.get_definition(str(existing.get("item_id", "")))
		var existing_footprint: Vector2 = existing_definition.get("footprint", Vector2.ONE)
		var existing_position := existing.get("position") as Vector3
		var parallel_delta: float = abs(existing_position.x - position.x) if surface_name in [PlacementTypes.SURFACE_WALL_BACK, PlacementTypes.SURFACE_WALL_FRONT] else abs(existing_position.z - position.z)
		var height_delta: float = abs(existing_position.y - position.y)
		if parallel_delta < (existing_footprint.x + footprint.x) * 0.5 - 0.02 and height_delta < (existing_footprint.y + footprint.y) * 0.5 - 0.02:
			return true
	return false

func _has_surface_overlap(placement: Dictionary, item_definition: Dictionary, placed_items: Array) -> bool:
	var anchor_item_id := str(placement.get("anchor_item_id", ""))
	var local_offset: Vector2 = placement.get("local_offset", Vector2.ZERO)
	var footprint := _get_rotated_footprint(item_definition, float(placement.get("rotation_y", 0.0)))
	for existing in placed_items:
		if str(existing.get("surface", "")) != PlacementTypes.SURFACE_SURFACE:
			continue
		if str(existing.get("anchor_item_id", "")) != anchor_item_id:
			continue

		var existing_definition := BuildItemRegistry.get_definition(str(existing.get("item_id", "")))
		var existing_offset: Vector2 = existing.get("local_offset", Vector2.ZERO)
		var existing_footprint := _get_rotated_footprint(existing_definition, float(existing.get("rotation_y", 0.0)))
		if abs(existing_offset.x - local_offset.x) < (existing_footprint.x + footprint.x) * 0.5 - 0.02 and abs(existing_offset.y - local_offset.y) < (existing_footprint.y + footprint.y) * 0.5 - 0.02:
			return true
	return false

func _world_to_host_local(host: Dictionary, world_position: Vector3) -> Vector2:
	var host_position := host.get("position") as Vector3
	var delta := world_position - host_position
	var rotation_y: float = float(host.get("rotation_y", 0.0))
	var local_x: float = delta.x * cos(rotation_y) - delta.z * sin(rotation_y)
	var local_z: float = delta.x * sin(rotation_y) + delta.z * cos(rotation_y)
	return Vector2(local_x, local_z)

func _host_local_to_world(host: Dictionary, local_offset: Vector2, support_height: float) -> Vector3:
	var host_position := host.get("position") as Vector3
	var rotation_y: float = float(host.get("rotation_y", 0.0))
	var world_x := local_offset.x * cos(rotation_y) + local_offset.y * sin(rotation_y)
	var world_z := -local_offset.x * sin(rotation_y) + local_offset.y * cos(rotation_y)
	return Vector3(host_position.x + world_x, host_position.y + support_height, host_position.z + world_z)

func _snap_value(value: float, step: float) -> float:
	return round(value / step) * step
