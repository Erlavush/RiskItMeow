@tool
class_name ImportedScenePlaceable
extends PlaceableItem

const MIN_PROP_DIMENSION := 0.08
const ANCHOR_MODE_FLOOR := "floor"
const ANCHOR_MODE_CENTER := "center"
const ANCHOR_MODE_CEILING := "ceiling"
const FLOOR_AUTO_FIT_CANDIDATES_DEFAULT := [
	Vector2(1.0, 1.0),
	Vector2(2.0, 1.0),
	Vector2(2.0, 2.0),
	Vector2(3.0, 1.0),
	Vector2(3.0, 2.0),
]
const FLOOR_AUTO_FIT_CANDIDATES_BEDS := [
	Vector2(3.0, 2.0),
	Vector2(2.0, 2.0),
	Vector2(2.0, 1.0),
]
const FLOOR_AUTO_FIT_CANDIDATES_SOFAS := [
	Vector2(3.0, 1.0),
	Vector2(2.0, 1.0),
	Vector2(2.0, 2.0),
	Vector2(1.0, 1.0),
]
const FLOOR_AUTO_FIT_CANDIDATES_TABLES := [
	Vector2(2.0, 1.0),
	Vector2(2.0, 2.0),
	Vector2(1.0, 1.0),
	Vector2(3.0, 1.0),
]
const FLOOR_AUTO_FIT_CANDIDATES_STORAGE := [
	Vector2(1.0, 1.0),
	Vector2(2.0, 1.0),
	Vector2(3.0, 1.0),
	Vector2(2.0, 2.0),
]
const FLOOR_AUTO_FIT_CANDIDATES_BATHROOM := [
	Vector2(1.0, 1.0),
	Vector2(2.0, 1.0),
]
const CEILING_AUTO_FIT_CANDIDATES := [
	Vector2(1.0, 1.0),
	Vector2(2.0, 1.0),
	Vector2(2.0, 2.0),
	Vector2(3.0, 1.0),
]

static var _bounds_cache: Dictionary = {}
static var _auto_fit_cache: Dictionary = {}

var _item_id := "imported_scene_placeable"
var _display_name := "Imported Item"
var _category_name := "Miscellaneous"
var _source_scene_path := ""
var _source_node_names_override: Array[String] = []
var _mount_kind_override := RoomConstants.MOUNT_FLOOR
var _mount_kinds_override: Array[String] = [RoomConstants.MOUNT_FLOOR]
var _collision_size_override := Vector3.ZERO
var _placement_surface_kind_override := ""
var _visual_scale_override := Vector3.ONE
var _visual_fit_height_override := 0.0
var _visual_y_offset_override := 0.0
var _visual_yaw_override := 0.0
var _anchor_mode_override := ANCHOR_MODE_FLOOR
var _supports_rotation_override := true
var _supported_wall_surfaces_override: Array[String] = []
var _wall_rotation_offset_override := 0.0
var _requires_wall_opening_override := false
var _wall_opening_half_extents_override := Vector2.ZERO
var _has_collision_center_offset_override := false
var _collision_center_offset_override := Vector3.ZERO
var _has_footprint_half_extents_override := false
var _footprint_half_extents_override := Vector2.ZERO
var _has_wall_half_extents_override := false
var _wall_half_extents_override := Vector2.ZERO
var _can_host_surface_items_override := false
var _support_surfaces_override: Array[Dictionary] = []
var _has_runtime_shadow_cast_setting_override := false
var _runtime_shadow_cast_setting_override: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func configure_from_item_def(item_def: Dictionary) -> void:
	_item_id = String(item_def.get("id", _item_id))
	_display_name = String(item_def.get("display_name", _display_name))
	_category_name = String(item_def.get("category", _category_name))
	_source_scene_path = String(item_def.get("source_scene_path", _source_scene_path))
	_source_node_names_override = _normalize_string_array(item_def.get("source_node_names", []))
	_mount_kinds_override = _normalize_mount_kinds(item_def.get("mount_kinds", []))
	_mount_kind_override = _resolve_primary_mount_kind(item_def)
	_collision_size_override = item_def.get("collision_size", Vector3.ZERO) as Vector3
	_placement_surface_kind_override = String(item_def.get("placement_surface_kind", ""))
	_visual_scale_override = item_def.get("visual_scale", Vector3.ONE) as Vector3
	_visual_fit_height_override = maxf(float(item_def.get("visual_fit_height", 0.0)), 0.0)
	_visual_y_offset_override = float(item_def.get("visual_y_offset", 0.0))
	_visual_yaw_override = float(item_def.get("visual_yaw", 0.0))
	_anchor_mode_override = _normalize_anchor_mode(String(item_def.get("anchor_mode", ANCHOR_MODE_FLOOR)))
	_supports_rotation_override = bool(item_def.get("supports_rotation", true))
	_supported_wall_surfaces_override.clear()
	var raw_surfaces: Variant = item_def.get("supported_wall_surfaces", [])
	if raw_surfaces is Array:
		for surface_name in raw_surfaces:
			_supported_wall_surfaces_override.append(String(surface_name))
	_wall_rotation_offset_override = float(item_def.get("wall_rotation_offset", 0.0))
	_requires_wall_opening_override = bool(item_def.get("requires_wall_opening", false))
	_wall_opening_half_extents_override = item_def.get("wall_opening_half_extents", Vector2.ZERO) as Vector2
	_has_collision_center_offset_override = item_def.has("collision_center_offset")
	_collision_center_offset_override = item_def.get("collision_center_offset", Vector3.ZERO) as Vector3
	_has_footprint_half_extents_override = item_def.has("footprint_half_extents")
	_footprint_half_extents_override = item_def.get("footprint_half_extents", Vector2.ZERO) as Vector2
	_has_wall_half_extents_override = item_def.has("wall_half_extents")
	_wall_half_extents_override = item_def.get("wall_half_extents", Vector2.ZERO) as Vector2
	_can_host_surface_items_override = bool(item_def.get("can_host_surface_items", false))
	_support_surfaces_override = _normalize_support_surfaces(item_def.get("support_surfaces", []))
	_has_runtime_shadow_cast_setting_override = item_def.has("runtime_shadow_cast_setting")
	_runtime_shadow_cast_setting_override = item_def.get("runtime_shadow_cast_setting", GeometryInstance3D.SHADOW_CASTING_SETTING_ON) as GeometryInstance3D.ShadowCastingSetting

func get_prop_id() -> String:
	return _item_id

func get_display_name() -> String:
	return _display_name

func get_source_scene_path() -> String:
	return _source_scene_path

func get_visual_scene_path() -> String:
	return ""

func get_visual_scale() -> Vector3:
	return _get_effective_visual_scale()

func get_visual_y_offset() -> float:
	return 0.0

func get_collision_size() -> Vector3:
	if _collision_size_override.length_squared() > 0.0001:
		return _collision_size_override
	var auto_fit_metrics := _get_auto_fit_metrics()
	if auto_fit_metrics.has("collision_size"):
		return auto_fit_metrics.get("collision_size", Vector3.ONE) as Vector3
	var bounds: Dictionary = _get_cached_bounds()
	var raw_size: Vector3 = bounds.get("size", Vector3.ONE) as Vector3
	return Vector3(
		maxf(raw_size.x, MIN_PROP_DIMENSION),
		maxf(raw_size.y, MIN_PROP_DIMENSION),
		maxf(raw_size.z, MIN_PROP_DIMENSION)
	)

func get_primary_mount_kind() -> String:
	return _mount_kind_override

func get_mount_kinds() -> Array[String]:
	return _mount_kinds_override.duplicate()

func get_placement_surface_kind() -> String:
	if not _placement_surface_kind_override.is_empty():
		return _placement_surface_kind_override
	return super.get_placement_surface_kind()

func get_collision_center_offset() -> Vector3:
	if _has_collision_center_offset_override:
		return _collision_center_offset_override
	var auto_fit_metrics := _get_auto_fit_metrics()
	if auto_fit_metrics.has("collision_center_offset"):
		return auto_fit_metrics.get("collision_center_offset", Vector3.ZERO) as Vector3
	if _anchor_mode_override == ANCHOR_MODE_CENTER:
		return Vector3.ZERO
	if _anchor_mode_override == ANCHOR_MODE_CEILING or get_primary_mount_kind() == RoomConstants.MOUNT_CEILING:
		return Vector3(0.0, -get_collision_size().y * 0.5, 0.0)
	return super.get_collision_center_offset()

func get_footprint_half_extents() -> Vector2:
	if _has_footprint_half_extents_override:
		return _footprint_half_extents_override
	var auto_fit_metrics := _get_auto_fit_metrics()
	if auto_fit_metrics.has("footprint_half_extents"):
		return auto_fit_metrics.get("footprint_half_extents", Vector2.ZERO) as Vector2
	return super.get_footprint_half_extents()

func can_host_surface_items() -> bool:
	return _can_host_surface_items_override or not _support_surfaces_override.is_empty()

func get_support_surfaces() -> Array[Dictionary]:
	if not _support_surfaces_override.is_empty():
		return _support_surfaces_override.duplicate(true)
	if _can_host_surface_items_override:
		return [build_top_support_surface()]
	return []

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

func get_wall_half_extents() -> Vector2:
	if _has_wall_half_extents_override:
		return _wall_half_extents_override
	return super.get_wall_half_extents()

func supports_rotation() -> bool:
	return _supports_rotation_override

func get_wall_rotation_offset() -> float:
	return _wall_rotation_offset_override

func get_runtime_shadow_cast_setting() -> GeometryInstance3D.ShadowCastingSetting:
	if _has_runtime_shadow_cast_setting_override:
		return _runtime_shadow_cast_setting_override
	return super.get_runtime_shadow_cast_setting()

func _resolve_primary_mount_kind(item_def: Dictionary) -> String:
	var requested_mount := String(item_def.get("mount_kind", ""))
	if RoomConstants.is_mount_kind(requested_mount):
		if not _mount_kinds_override.has(requested_mount):
			_mount_kinds_override.push_front(requested_mount)
		return requested_mount
	if not _mount_kinds_override.is_empty():
		return _mount_kinds_override[0]
	return RoomConstants.MOUNT_FLOOR

func _normalize_mount_kinds(raw_mounts: Variant) -> Array[String]:
	var mount_kinds: Array[String] = []
	if raw_mounts is Array:
		for raw_mount in raw_mounts:
			var mount_kind := String(raw_mount)
			if not RoomConstants.is_mount_kind(mount_kind):
				continue
			if mount_kinds.has(mount_kind):
				continue
			mount_kinds.append(mount_kind)
	if mount_kinds.is_empty():
		mount_kinds.append(RoomConstants.MOUNT_FLOOR)
	return mount_kinds

func _normalize_string_array(raw_values: Variant) -> Array[String]:
	var values: Array[String] = []
	if raw_values is Array:
		for raw_value in raw_values:
			var normalized_value := String(raw_value)
			if normalized_value.is_empty():
				continue
			values.append(normalized_value)
	return values

func _normalize_anchor_mode(anchor_mode: String) -> String:
	match anchor_mode:
		ANCHOR_MODE_CENTER, ANCHOR_MODE_CEILING:
			return anchor_mode
		_:
			return ANCHOR_MODE_FLOOR

func _normalize_support_surfaces(raw_surfaces: Variant) -> Array[Dictionary]:
	var support_surfaces: Array[Dictionary] = []
	if raw_surfaces is Array:
		for raw_surface in raw_surfaces:
			if typeof(raw_surface) != TYPE_DICTIONARY:
				continue
			var surface_dict := raw_surface as Dictionary
			var center_offset := surface_dict.get("center_offset", Vector3.ZERO) as Vector3
			var half_extents := surface_dict.get("half_extents", Vector2.ZERO) as Vector2
			if half_extents.x <= 0.001 or half_extents.y <= 0.001:
				continue
			support_surfaces.append(
				{
					"id": String(surface_dict.get("id", "top")),
					"center_offset": center_offset,
					"half_extents": half_extents,
				}
			)
	return support_surfaces

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
			imported_visual.scale = _get_effective_visual_scale()
			imported_visual.position.y = _get_default_visual_y_offset(extracted) + _visual_y_offset_override
			imported_visual.rotation.y = _visual_yaw_override
			_visual_root.add_child(imported_visual)
		else:
			_create_fallback_visual()

	_mesh_instances.clear()
	_collect_mesh_instances(_visual_root)

func _get_cached_bounds() -> Dictionary:
	var cache_key := "%s|%s|%s|%s|%s" % [_item_id, _source_scene_path, var_to_str(_source_node_names_override), var_to_str(_visual_scale_override), _visual_fit_height_override]
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
	if _source_node_names_override.is_empty():
		for child in source_root.get_children():
			var child_3d := child as Node3D
			if child_3d == null:
				continue
			var duplicated_node := child_3d.duplicate() as Node3D
			if duplicated_node != null:
				extracted_root.add_child(duplicated_node)
	else:
		for node_name in _source_node_names_override:
			var source_node := _find_named_node(source_root, node_name)
			if source_node == null:
				continue
			var duplicated_node := source_node.duplicate() as Node3D
			if duplicated_node != null:
				extracted_root.add_child(duplicated_node)

	source_root.free()

	if extracted_root.get_child_count() == 0:
		extracted_root.free()
		return {}

	var bounds: Dictionary = _compute_visual_bounds(extracted_root)
	if bounds.is_empty():
		return {"root": extracted_root, "bounds": {}, "visual_y_offset": 0.0}

	var minimum: Vector3 = bounds.get("min", Vector3.ZERO) as Vector3
	var maximum: Vector3 = bounds.get("max", Vector3.ZERO) as Vector3
	var raw_size := maximum - minimum
	var recenter_offset := Vector3(
		(minimum.x + maximum.x) * 0.5,
		_get_anchor_y(minimum, maximum),
		(minimum.z + maximum.z) * 0.5
	)
	for child in extracted_root.get_children():
		var child_node := child as Node3D
		if child_node != null:
			child_node.position -= recenter_offset

	bounds["raw_size"] = raw_size
	bounds["size"] = raw_size * _get_base_visual_scale(raw_size)
	return {
		"root": extracted_root,
		"bounds": bounds,
		"visual_y_offset": 0.0,
	}

func _get_default_visual_y_offset(extracted: Dictionary) -> float:
	var base_offset := float(extracted.get("visual_y_offset", 0.0))
	if get_primary_mount_kind() != RoomConstants.MOUNT_CEILING or _anchor_mode_override == ANCHOR_MODE_CEILING:
		return base_offset
	var bounds: Dictionary = extracted.get("bounds", {}) as Dictionary
	var size: Vector3 = bounds.get("size", get_collision_size()) as Vector3
	var auto_fit_metrics := _get_auto_fit_metrics()
	if auto_fit_metrics.has("collision_size"):
		size = auto_fit_metrics.get("collision_size", size) as Vector3
	return base_offset - size.y

func _get_effective_visual_scale() -> Vector3:
	var auto_fit_metrics := _get_auto_fit_metrics()
	if auto_fit_metrics.has("visual_scale"):
		return auto_fit_metrics.get("visual_scale", _visual_scale_override) as Vector3
	var raw_size := _get_cached_bounds().get("raw_size", Vector3.ZERO) as Vector3
	return _get_base_visual_scale(raw_size)

func _get_base_visual_scale(raw_size: Vector3) -> Vector3:
	var visual_scale := _visual_scale_override
	if _visual_fit_height_override > 0.0 and raw_size.y > 0.001:
		visual_scale *= _visual_fit_height_override / raw_size.y
	return visual_scale

func _get_auto_fit_metrics() -> Dictionary:
	if not _should_use_auto_fit_metrics():
		return {}

	var cache_key := "%s|%s|%s|%s|%s" % [
		_item_id,
		_source_scene_path,
		_category_name,
		_mount_kind_override,
		var_to_str(_visual_scale_override),
	]
	if _auto_fit_cache.has(cache_key):
		return _auto_fit_cache[cache_key] as Dictionary

	var bounds := _get_cached_bounds()
	if bounds.is_empty():
		return {}

	var raw_size := bounds.get("raw_size", Vector3.ONE) as Vector3
	var base_size := bounds.get("size", raw_size * _visual_scale_override) as Vector3
	var auto_fit_metrics := _build_auto_fit_metrics(raw_size, base_size)
	_auto_fit_cache[cache_key] = auto_fit_metrics
	return auto_fit_metrics

func _should_use_auto_fit_metrics() -> bool:
	if _collision_size_override.length_squared() > 0.0001:
		return false
	if _has_footprint_half_extents_override or _has_wall_half_extents_override or _requires_wall_opening_override:
		return false
	return get_primary_mount_kind() == RoomConstants.MOUNT_FLOOR or get_primary_mount_kind() == RoomConstants.MOUNT_CEILING

func _build_auto_fit_metrics(raw_size: Vector3, base_size: Vector3) -> Dictionary:
	if get_primary_mount_kind() == RoomConstants.MOUNT_CEILING:
		return _build_planar_auto_fit_metrics(raw_size, base_size, CEILING_AUTO_FIT_CANDIDATES)
	return _build_planar_auto_fit_metrics(raw_size, base_size, _get_floor_auto_fit_candidates())

func _build_planar_auto_fit_metrics(raw_size: Vector3, base_size: Vector3, candidates: Array) -> Dictionary:
	var source_planar := Vector2(maxf(base_size.x, MIN_PROP_DIMENSION), maxf(base_size.z, MIN_PROP_DIMENSION))
	var target_planar := _choose_best_planar_candidate(source_planar, candidates)
	var source_long := maxf(maxf(source_planar.x, source_planar.y), MIN_PROP_DIMENSION)
	var target_long := maxf(maxf(target_planar.x, target_planar.y), MIN_PROP_DIMENSION)
	var scale_ratio := target_long / source_long
	var effective_scale := _get_base_visual_scale(raw_size).x * scale_ratio
	var collision_size := Vector3(
		maxf(target_planar.x, MIN_PROP_DIMENSION),
		maxf(raw_size.y * effective_scale, MIN_PROP_DIMENSION),
		maxf(target_planar.y, MIN_PROP_DIMENSION)
	)
	return {
		"visual_scale": Vector3.ONE * effective_scale,
		"collision_size": collision_size,
		"footprint_half_extents": Vector2(collision_size.x * 0.5, collision_size.z * 0.5),
	}

func _get_floor_auto_fit_candidates() -> Array:
	match _category_name:
		"Beds":
			return FLOOR_AUTO_FIT_CANDIDATES_BEDS
		"Sofas":
			return FLOOR_AUTO_FIT_CANDIDATES_SOFAS
		"Tables":
			return FLOOR_AUTO_FIT_CANDIDATES_TABLES
		"Drawers", "Shelves", "Kitchen":
			return FLOOR_AUTO_FIT_CANDIDATES_STORAGE
		"Bathroom":
			return FLOOR_AUTO_FIT_CANDIDATES_BATHROOM
		_:
			return FLOOR_AUTO_FIT_CANDIDATES_DEFAULT

func _choose_best_planar_candidate(source_planar: Vector2, candidates: Array) -> Vector2:
	var best_candidate := source_planar
	var best_score := INF
	for candidate in candidates:
		var candidate_options: Array[Vector2] = [candidate]
		if absf(candidate.x - candidate.y) > 0.001:
			candidate_options.append(Vector2(candidate.y, candidate.x))
		for candidate_option in candidate_options:
			var score := _score_planar_candidate(source_planar, candidate_option)
			if score >= best_score:
				continue
			best_score = score
			best_candidate = candidate_option
	return best_candidate

func _score_planar_candidate(source_planar: Vector2, candidate: Vector2) -> float:
	var source_long := maxf(source_planar.x, source_planar.y)
	var source_short := maxf(minf(source_planar.x, source_planar.y), MIN_PROP_DIMENSION)
	var candidate_long := maxf(candidate.x, candidate.y)
	var candidate_short := maxf(minf(candidate.x, candidate.y), MIN_PROP_DIMENSION)
	var source_ratio := source_long / source_short
	var candidate_ratio := candidate_long / candidate_short
	var source_area := source_planar.x * source_planar.y
	var candidate_area := candidate.x * candidate.y
	var length_error := absf(source_planar.x - candidate.x) + absf(source_planar.y - candidate.y)
	var ratio_error := absf(source_ratio - candidate_ratio)
	var area_error := absf(source_area - candidate_area)
	return length_error + ratio_error * 2.8 + area_error * 0.65

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

func _find_named_node(root: Node, node_name: String) -> Node3D:
	if root.name == node_name and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_named_node(child, node_name)
		if found != null:
			return found
	return null

func _get_anchor_y(minimum: Vector3, maximum: Vector3) -> float:
	match _anchor_mode_override:
		ANCHOR_MODE_CENTER:
			return (minimum.y + maximum.y) * 0.5
		ANCHOR_MODE_CEILING:
			return maximum.y
		_:
			return minimum.y

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
