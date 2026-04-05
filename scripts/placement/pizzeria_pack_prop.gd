@tool
class_name PizzeriaPackProp
extends SimpleWoodChair

const SOURCE_SCENE_PATH := "res://assets/props/fnaf-minecraft-pizzeria-pack/source/demopack.gltf"
const MIN_PROP_DIMENSION := 0.12

static var _bounds_cache: Dictionary = {}

func get_prop_id() -> String:
	return "pizzeria_pack_prop"

func get_display_name() -> String:
	return "Pizzeria Pack Prop"

func _get_source_node_names() -> Array[String]:
	return []

func get_collision_size() -> Vector3:
	var bounds: Dictionary = _get_cached_bounds()
	var raw_size: Vector3 = bounds.get("size", Vector3.ONE) as Vector3
	return Vector3(
		maxf(raw_size.x, MIN_PROP_DIMENSION),
		maxf(raw_size.y, MIN_PROP_DIMENSION),
		maxf(raw_size.z, MIN_PROP_DIMENSION)
	)

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
			var bounds: Dictionary = extracted.get("bounds", {}) as Dictionary
			imported_visual.position.y = float(bounds.get("visual_y_offset", 0.0))
			_visual_root.add_child(imported_visual)
		else:
			_create_fallback_visual()

	_mesh_instances.clear()
	_collect_mesh_instances(_visual_root)

func _get_cached_bounds() -> Dictionary:
	var cache_key: String = get_prop_id()
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
	var source_scene: PackedScene = load(SOURCE_SCENE_PATH) as PackedScene
	if source_scene == null:
		return {}

	var source_root: Node = source_scene.instantiate()
	if source_root == null:
		return {}

	var extracted_root: Node3D = Node3D.new()
	var source_node_names: Array[String] = _get_source_node_names()
	for node_name in source_node_names:
		var source_node: Node3D = _find_named_node(source_root, node_name)
		if source_node == null:
			continue

		var duplicate: Node3D = source_node.duplicate() as Node3D
		if duplicate != null:
			extracted_root.add_child(duplicate)

	source_root.free()

	if extracted_root.get_child_count() == 0:
		extracted_root.free()
		return {}

	var bounds: Dictionary = _compute_visual_bounds(extracted_root)
	if bounds.is_empty():
		return {
			"root": extracted_root,
			"bounds": {},
		}

	var minimum: Vector3 = bounds.get("min", Vector3.ZERO) as Vector3
	var maximum: Vector3 = bounds.get("max", Vector3.ZERO) as Vector3
	var recenter_offset: Vector3 = Vector3(
		(minimum.x + maximum.x) * 0.5,
		minimum.y,
		(minimum.z + maximum.z) * 0.5
	)

	for child in extracted_root.get_children():
		var child_node: Node3D = child as Node3D
		if child_node != null:
			child_node.position -= recenter_offset

	bounds["size"] = maximum - minimum
	bounds["visual_y_offset"] = minf(0.0, minimum.y)
	return {
		"root": extracted_root,
		"bounds": bounds,
	}

func _find_named_node(root: Node, node_name: String) -> Node3D:
	if root.name == node_name and root is Node3D:
		return root as Node3D

	for child in root.get_children():
		var found: Node3D = _find_named_node(child, node_name)
		if found != null:
			return found

	return null

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
	var current_transform: Transform3D = parent_transform
	var node_3d: Node3D = node as Node3D
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
