@tool
class_name WindowItem
extends SimpleWoodChair

const SOURCE_SCENE_PATH := "res://assets/props/three_window/scene.gltf"
const MIN_DIMENSION := 0.12
const TARGET_HEIGHT := 1.5
const COLLISION_PADDING := 0.03
const WALL_FRAME_OVERLAP := 0.018

static var _bounds_cache: Dictionary = {}

func get_display_name() -> String:
	return "Window"

func get_source_scene_path() -> String:
	return SOURCE_SCENE_PATH

func get_primary_mount_kind() -> String:
	return RoomConstants.MOUNT_WALL

func get_mount_kinds() -> Array[String]:
	return [RoomConstants.MOUNT_WALL]

func get_placement_surface_kind() -> String:
	return RoomConstants.SURFACE_DECOR

func get_default_wall_surface() -> String:
	return RoomConstants.WALL_BACK

func get_supported_wall_surfaces() -> Array[String]:
	var surfaces: Array[String] = []
	for surface_name in RoomConstants.WALL_SURFACES:
		surfaces.append(String(surface_name))
	return surfaces

func requires_wall_opening() -> bool:
	return true

func supports_rotation() -> bool:
	return false

func get_wall_rotation_offset() -> float:
	return PI

func get_collision_size() -> Vector3:
	var raw_size := _get_scaled_size()
	return Vector3(
		maxf(raw_size.x + COLLISION_PADDING, MIN_DIMENSION),
		maxf(raw_size.y + COLLISION_PADDING, MIN_DIMENSION),
		maxf(raw_size.z + COLLISION_PADDING, MIN_DIMENSION)
	)

func get_collision_center_offset() -> Vector3:
	return Vector3.ZERO

func get_runtime_shadow_cast_setting() -> int:
	return GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func get_wall_half_extents() -> Vector2:
	var collision_size := get_collision_size()
	return Vector2(collision_size.x * 0.5, collision_size.y * 0.5)

func get_wall_opening_half_extents() -> Vector2:
	var raw_size := _get_scaled_size()
	return Vector2(
		maxf(raw_size.x * 0.5 - WALL_FRAME_OVERLAP, 0.05),
		maxf(raw_size.y * 0.5 - WALL_FRAME_OVERLAP, 0.05)
	)

func _ensure_visual() -> void:
	_visual_root = get_node_or_null("VisualRoot") as Node3D
	if _visual_root == null:
		_visual_root = Node3D.new()
		_visual_root.name = "VisualRoot"
		add_child(_visual_root)

	if _visual_root.get_child_count() == 0:
		var visual_scene := load(get_source_scene_path()) as PackedScene
		if visual_scene != null:
			var imported_visual := visual_scene.instantiate() as Node3D
			if imported_visual != null:
				imported_visual.name = "ImportedVisual"
				var scale_factor := _get_visual_scale_factor()
				imported_visual.scale = Vector3.ONE * scale_factor
				var center: Vector3 = _get_cached_bounds().get("center", Vector3.ZERO) as Vector3
				imported_visual.position = -center * scale_factor
				_visual_root.add_child(imported_visual)
			else:
				_create_fallback_visual()
		else:
			_create_fallback_visual()

	_mesh_instances.clear()
	_collect_mesh_instances(_visual_root)

func _get_cached_bounds() -> Dictionary:
	var cache_key := get_source_scene_path()
	if _bounds_cache.has(cache_key):
		return _bounds_cache[cache_key] as Dictionary

	var bounds := _compute_source_bounds()
	_bounds_cache[cache_key] = bounds
	return bounds

func _compute_source_bounds() -> Dictionary:
	var source_scene := load(get_source_scene_path()) as PackedScene
	if source_scene == null:
		return {}

	var source_root := source_scene.instantiate() as Node3D
	if source_root == null:
		return {}

	var state: Dictionary = {
		"ready": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_node_bounds(source_root, Transform3D.IDENTITY, state)
	source_root.free()
	if not state.get("ready", false):
		return {}

	var minimum: Vector3 = state.get("min", Vector3.ZERO) as Vector3
	var maximum: Vector3 = state.get("max", Vector3.ZERO) as Vector3
	return {
		"min": minimum,
		"max": maximum,
		"size": maximum - minimum,
		"center": (minimum + maximum) * 0.5,
	}

func _get_visual_scale_factor() -> float:
	var raw_size: Vector3 = _get_cached_bounds().get("size", Vector3(2.13, 2.64, 0.2)) as Vector3
	if raw_size.y <= 0.001:
		return 1.0
	return TARGET_HEIGHT / raw_size.y

func _get_scaled_size() -> Vector3:
	var raw_size: Vector3 = _get_cached_bounds().get("size", Vector3(2.13, 2.64, 0.2)) as Vector3
	return raw_size * _get_visual_scale_factor()

func _accumulate_node_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform: Transform3D = parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
		if node_3d is MeshInstance3D:
			var mesh_instance := node_3d as MeshInstance3D
			if mesh_instance.mesh != null:
				_merge_aabb(mesh_instance.mesh.get_aabb(), current_transform, state)

	for child in node.get_children():
		_accumulate_node_bounds(child, current_transform, state)

func _merge_aabb(aabb: AABB, aabb_transform: Transform3D, state: Dictionary) -> void:
	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]

	for corner in corners:
		var transformed_corner: Vector3 = aabb_transform * corner
		if not state.get("ready", false):
			state["min"] = transformed_corner
			state["max"] = transformed_corner
			state["ready"] = true
			continue

		var minimum: Vector3 = state.get("min", Vector3.ZERO) as Vector3
		var maximum: Vector3 = state.get("max", Vector3.ZERO) as Vector3
		minimum.x = minf(minimum.x, transformed_corner.x)
		minimum.y = minf(minimum.y, transformed_corner.y)
		minimum.z = minf(minimum.z, transformed_corner.z)
		maximum.x = maxf(maximum.x, transformed_corner.x)
		maximum.y = maxf(maximum.y, transformed_corner.y)
		maximum.z = maxf(maximum.z, transformed_corner.z)
		state["min"] = minimum
		state["max"] = maximum
