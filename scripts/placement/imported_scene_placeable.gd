@tool
class_name ImportedScenePlaceable
extends SimpleWoodChair

const MIN_PROP_DIMENSION := 0.08

static var _bounds_cache: Dictionary = {}

var _item_id := "imported_scene_placeable"
var _display_name := "Imported Item"
var _source_scene_path := ""
var _collision_size_override := Vector3.ZERO
var _visual_scale_override := Vector3.ONE
var _visual_y_offset_override := 0.0
var _supports_rotation_override := true
var _placement_surface_kind_override := RoomConstants.FLOOR_SURFACE
var _supported_wall_surfaces_override: Array[String] = []
var _wall_rotation_offset_override := 0.0
var _requires_wall_opening_override := false
var _wall_opening_half_extents_override := Vector2.ZERO

func configure_from_item_def(item_def: Dictionary) -> void:
	_item_id = String(item_def.get("id", _item_id))
	_display_name = String(item_def.get("display_name", _display_name))
	_source_scene_path = String(item_def.get("source_scene_path", _source_scene_path))
	_collision_size_override = item_def.get("collision_size", Vector3.ZERO) as Vector3
	_visual_scale_override = item_def.get("visual_scale", Vector3.ONE) as Vector3
	_visual_y_offset_override = float(item_def.get("visual_y_offset", 0.0))
	_supports_rotation_override = bool(item_def.get("supports_rotation", true))
	_placement_surface_kind_override = String(item_def.get("placement_surface_kind", RoomConstants.FLOOR_SURFACE))
	_supported_wall_surfaces_override.clear()
	var raw_surfaces: Variant = item_def.get("supported_wall_surfaces", [])
	if raw_surfaces is Array:
		for surface_name in raw_surfaces:
			_supported_wall_surfaces_override.append(String(surface_name))
	_wall_rotation_offset_override = float(item_def.get("wall_rotation_offset", 0.0))
	_requires_wall_opening_override = bool(item_def.get("requires_wall_opening", false))
	_wall_opening_half_extents_override = item_def.get("wall_opening_half_extents", Vector2.ZERO) as Vector2

func get_prop_id() -> String:
	return _item_id

func get_display_name() -> String:
	return _display_name

func get_source_scene_path() -> String:
	return _source_scene_path

func get_visual_scene_path() -> String:
	return ""

func get_visual_scale() -> Vector3:
	return Vector3.ONE

func get_visual_y_offset() -> float:
	return 0.0

func get_collision_size() -> Vector3:
	if _collision_size_override.length_squared() > 0.0001:
		return _collision_size_override
	var bounds: Dictionary = _get_cached_bounds()
	var raw_size: Vector3 = bounds.get("size", Vector3.ONE) as Vector3
	return Vector3(
		maxf(raw_size.x, MIN_PROP_DIMENSION),
		maxf(raw_size.y, MIN_PROP_DIMENSION),
		maxf(raw_size.z, MIN_PROP_DIMENSION)
	)

func get_placement_surface_kind() -> String:
	return _placement_surface_kind_override

func get_supported_wall_surfaces() -> Array[String]:
	return _supported_wall_surfaces_override.duplicate()

func requires_wall_opening() -> bool:
	return _requires_wall_opening_override

func get_wall_opening_half_extents() -> Vector2:
	if _wall_opening_half_extents_override.length_squared() > 0.0001:
		return _wall_opening_half_extents_override
	if _requires_wall_opening_override:
		var collision_size := get_collision_size()
		return Vector2(collision_size.x * 0.46, collision_size.y * 0.46)
	return super.get_wall_opening_half_extents()

func supports_rotation() -> bool:
	return _supports_rotation_override

func get_wall_rotation_offset() -> float:
	return _wall_rotation_offset_override

func _ensure_visual() -> void:
	_visual_root = get_node_or_null("VisualRoot") as Node3D
	if _visual_root == null:
		_visual_root = Node3D.new()
		_visual_root.name = "VisualRoot"
		add_child(_visual_root)

	if _visual_root.get_child_count() == 0:
		var extracted: Dictionary = _extract_visual_data()
		var imported_visual: Node3D = extracted.get("root") as Node3D
		if imported_visual != null:
			imported_visual.name = "ImportedVisual"
			imported_visual.scale = _visual_scale_override
			imported_visual.position.y = float(extracted.get("visual_y_offset", 0.0)) + _visual_y_offset_override
			_visual_root.add_child(imported_visual)
		else:
			_create_fallback_visual()

	_mesh_instances.clear()
	_collect_mesh_instances(_visual_root)

func _get_cached_bounds() -> Dictionary:
	var cache_key := "%s|%s|%s" % [_item_id, _source_scene_path, var_to_str(_visual_scale_override)]
	if _bounds_cache.has(cache_key):
		return _bounds_cache[cache_key] as Dictionary

	var extracted: Dictionary = _extract_visual_data()
	var bounds: Dictionary = extracted.get("bounds", {}) as Dictionary
	var extracted_root: Node3D = extracted.get("root") as Node3D
	if extracted_root != null:
		extracted_root.free()

	_bounds_cache[cache_key] = bounds
	return bounds

func _extract_visual_data() -> Dictionary:
	if _source_scene_path.is_empty():
		return {}

	var source_root := _instantiate_source_scene(_source_scene_path)
	if source_root == null:
		return {}

	var extracted_root := Node3D.new()
	for child in source_root.get_children():
		var child_3d := child as Node3D
		if child_3d == null:
			continue
		var duplicate := child_3d.duplicate() as Node3D
		if duplicate != null:
			extracted_root.add_child(duplicate)

	source_root.free()

	if extracted_root.get_child_count() == 0:
		extracted_root.free()
		return {}

	var bounds: Dictionary = _compute_visual_bounds(extracted_root)
	if bounds.is_empty():
		return {"root": extracted_root, "bounds": {}, "visual_y_offset": 0.0}

	var minimum: Vector3 = bounds.get("min", Vector3.ZERO) as Vector3
	var maximum: Vector3 = bounds.get("max", Vector3.ZERO) as Vector3
	var recenter_offset := Vector3(
		(minimum.x + maximum.x) * 0.5,
		minimum.y,
		(minimum.z + maximum.z) * 0.5
	)
	for child in extracted_root.get_children():
		var child_node := child as Node3D
		if child_node != null:
			child_node.position -= recenter_offset

	bounds["size"] = (maximum - minimum) * _visual_scale_override
	return {
		"root": extracted_root,
		"bounds": bounds,
		"visual_y_offset": 0.0,
	}

func _instantiate_source_scene(source_path: String) -> Node:
	var source_scene := load(source_path) as PackedScene
	if source_scene != null:
		return source_scene.instantiate()

	if not (source_path.ends_with(".glb") or source_path.ends_with(".gltf")):
		return null

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error_code := document.append_from_file(source_path, state)
	if error_code != OK:
		return null
	return document.generate_scene(state)

func _compute_visual_bounds(root: Node3D) -> Dictionary:
	var state: Dictionary = {
		"ready": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_node_bounds(root, Transform3D.IDENTITY, state)
	if not state.get("ready", false):
		return {}
	return {
		"min": state.get("min", Vector3.ZERO),
		"max": state.get("max", Vector3.ZERO),
	}

func _accumulate_node_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
		if node_3d is MeshInstance3D:
			var mesh_instance := node_3d as MeshInstance3D
			if mesh_instance.mesh != null:
				_merge_aabb(mesh_instance.mesh.get_aabb(), current_transform, state)
	for child in node.get_children():
		_accumulate_node_bounds(child, current_transform, state)

func _merge_aabb(aabb: AABB, transform: Transform3D, state: Dictionary) -> void:
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
		var transformed_corner: Vector3 = transform * corner
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
