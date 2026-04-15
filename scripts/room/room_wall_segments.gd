class_name RoomWallSegments
extends RefCounted

const WALL_SEGMENTS_ROOT_NAME := "RuntimeSegments"

static func configure_wall_surface(
	surface: Node3D,
	surface_name: String,
	center: Vector3,
	size: Vector3,
	color: Color,
	wall_thickness: float,
	openings_by_surface: Dictionary,
	material_cache: Dictionary
) -> void:
	if surface == null:
		return

	surface.position = center
	var visual := surface.get_node_or_null("Visual") as MeshInstance3D
	if visual != null:
		visual.visible = false
	var collider_body := surface.get_node_or_null("Collider") as CollisionObject3D
	if collider_body != null:
		collider_body.process_mode = Node.PROCESS_MODE_DISABLED

	var segments_root := _get_or_create_wall_segments_root(surface)
	_clear_wall_segments(segments_root)

	var segment_defs := _build_wall_segment_defs(
		surface_name,
		size,
		wall_thickness,
		openings_by_surface.get(surface_name, [])
	)
	var wall_material := _get_or_create_wall_segment_material(surface_name, color, material_cache)
	for index in range(segment_defs.size()):
		var segment_def := segment_defs[index]
		_add_wall_segment(
			segments_root,
			index,
			surface_name,
			segment_def.get("position", Vector3.ZERO) as Vector3,
			segment_def.get("size", size) as Vector3,
			wall_material
		)
	_hide_unused_segment_nodes(segments_root, segment_defs.size())

static func set_segments_visible(surface: Node3D, visible_state: bool, is_cutaway: bool, shadows_only: int, shadows_on: int) -> void:
	var segments_root := surface.get_node_or_null(WALL_SEGMENTS_ROOT_NAME) as Node3D
	if segments_root == null:
		return

	for child in segments_root.get_children():
		var segment_root := child as Node3D
		if segment_root == null:
			continue
		if not bool(segment_root.get_meta("wall_segment_active", false)):
			continue
		segment_root.visible = visible_state

		var visual := segment_root.get_node_or_null("Visual") as VisualInstance3D
		if visual != null:
			visual.visible = visible_state
			visual.cast_shadow = shadows_only if visible_state and is_cutaway else shadows_on

		var collider_body := segment_root.get_node_or_null("Collider") as CollisionObject3D
		if collider_body != null:
			collider_body.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
			collider_body.process_mode = Node.PROCESS_MODE_INHERIT if visible_state else Node.PROCESS_MODE_DISABLED

static func _build_wall_segment_defs(surface_name: String, size: Vector3, wall_thickness: float, raw_openings: Variant) -> Array[Dictionary]:
	var horizontal_span: float = size.x if surface_name == RoomConstants.WALL_BACK or surface_name == RoomConstants.WALL_FRONT else size.z
	var total_height: float = size.y
	if not (raw_openings is Array):
		return [{"position": Vector3.ZERO, "size": size}]

	var openings: Array = raw_openings
	if openings.is_empty():
		return [{"position": Vector3.ZERO, "size": size}]

	var x_edges: Array[float] = [-horizontal_span * 0.5, horizontal_span * 0.5]
	var y_edges: Array[float] = [0.0, total_height]
	for raw_opening in openings:
		if typeof(raw_opening) != TYPE_DICTIONARY:
			continue

		var opening: Dictionary = raw_opening
		var center_u: float = float(opening.get("center_u", 0.0))
		var center_v: float = float(opening.get("center_v", total_height * 0.5))
		var half_u: float = float(opening.get("half_u", 0.0))
		var half_v: float = float(opening.get("half_v", 0.0))
		x_edges.append(clampf(center_u - half_u, -horizontal_span * 0.5, horizontal_span * 0.5))
		x_edges.append(clampf(center_u + half_u, -horizontal_span * 0.5, horizontal_span * 0.5))
		y_edges.append(clampf(center_v - half_v, 0.0, total_height))
		y_edges.append(clampf(center_v + half_v, 0.0, total_height))

	x_edges = _sorted_unique_edges(x_edges)
	y_edges = _sorted_unique_edges(y_edges)

	var segments: Array[Dictionary] = []
	for x_index in range(x_edges.size() - 1):
		var min_u: float = x_edges[x_index]
		var max_u: float = x_edges[x_index + 1]
		var segment_width: float = max_u - min_u
		if segment_width <= 0.001:
			continue

		for y_index in range(y_edges.size() - 1):
			var min_v: float = y_edges[y_index]
			var max_v: float = y_edges[y_index + 1]
			var segment_height: float = max_v - min_v
			if segment_height <= 0.001:
				continue

			var center_u: float = (min_u + max_u) * 0.5
			var center_v: float = (min_v + max_v) * 0.5
			if _is_wall_cell_inside_any_opening(center_u, center_v, openings):
				continue

			var local_position := _get_wall_segment_local_position(surface_name, center_u, center_v - total_height * 0.5)
			var segment_size := Vector3(segment_width, segment_height, wall_thickness)
			if surface_name == RoomConstants.WALL_LEFT or surface_name == RoomConstants.WALL_RIGHT:
				segment_size = Vector3(wall_thickness, segment_height, segment_width)

			segments.append({
				"position": local_position,
				"size": segment_size,
			})

	return segments

static func _sorted_unique_edges(edges: Array[float]) -> Array[float]:
	edges.sort()
	var unique_edges: Array[float] = []
	for edge in edges:
		if unique_edges.is_empty() or absf(unique_edges[unique_edges.size() - 1] - edge) > 0.001:
			unique_edges.append(edge)
	return unique_edges

static func _is_wall_cell_inside_any_opening(center_u: float, center_v: float, openings: Array) -> bool:
	for raw_opening in openings:
		if typeof(raw_opening) != TYPE_DICTIONARY:
			continue

		var opening: Dictionary = raw_opening
		var opening_center_u: float = float(opening.get("center_u", 0.0))
		var opening_center_v: float = float(opening.get("center_v", 0.0))
		var half_u: float = float(opening.get("half_u", 0.0))
		var half_v: float = float(opening.get("half_v", 0.0))
		if absf(center_u - opening_center_u) < half_u - 0.001 and absf(center_v - opening_center_v) < half_v - 0.001:
			return true

	return false

static func _get_wall_segment_local_position(surface_name: String, horizontal_offset: float, vertical_offset: float) -> Vector3:
	match surface_name:
		RoomConstants.WALL_BACK, RoomConstants.WALL_FRONT:
			return Vector3(horizontal_offset, vertical_offset, 0.0)
		RoomConstants.WALL_LEFT, RoomConstants.WALL_RIGHT:
			return Vector3(0.0, vertical_offset, horizontal_offset)
		_:
			return Vector3.ZERO

static func _get_or_create_wall_segments_root(surface: Node3D) -> Node3D:
	var segments_root := surface.get_node_or_null(WALL_SEGMENTS_ROOT_NAME) as Node3D
	if segments_root != null:
		return segments_root

	segments_root = Node3D.new()
	segments_root.name = WALL_SEGMENTS_ROOT_NAME
	surface.add_child(segments_root)
	return segments_root

static func _clear_wall_segments(segments_root: Node3D) -> void:
	_hide_unused_segment_nodes(segments_root, 0)

static func _hide_unused_segment_nodes(segments_root: Node3D, used_count: int) -> void:
	if segments_root == null:
		return

	for index in range(segments_root.get_child_count()):
		var segment_root := segments_root.get_child(index) as Node3D
		if segment_root == null:
			continue

		var is_used := index < used_count
		segment_root.set_meta("wall_segment_active", is_used)
		if is_used:
			continue

		segment_root.visible = false
		var visual := segment_root.get_node_or_null("Visual") as VisualInstance3D
		if visual != null:
			visual.visible = false
		var collider_body := segment_root.get_node_or_null("Collider") as CollisionObject3D
		if collider_body != null:
			collider_body.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
			collider_body.process_mode = Node.PROCESS_MODE_DISABLED

static func _ensure_segment_node(segments_root: Node3D, index: int) -> Node3D:
	if segments_root == null:
		return null

	if index < segments_root.get_child_count():
		var existing := segments_root.get_child(index) as Node3D
		if existing != null:
			return existing

	var segment_root := Node3D.new()
	segment_root.name = "Segment_%d" % index
	segments_root.add_child(segment_root)
	return segment_root

static func _apply_segment_node(segment_root: Node3D, surface_name: String, local_position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	if segment_root == null:
		return

	segment_root.position = local_position
	segment_root.visible = true
	segment_root.set_meta("wall_segment_active", true)

	var visual := segment_root.get_node_or_null("Visual") as MeshInstance3D
	if visual == null:
		visual = MeshInstance3D.new()
		visual.name = "Visual"
		segment_root.add_child(visual)
	var mesh := visual.mesh as BoxMesh
	if mesh == null:
		mesh = BoxMesh.new()
		visual.mesh = mesh
	mesh.size = size
	visual.material_override = material
	visual.visible = true

	var collider := segment_root.get_node_or_null("Collider") as StaticBody3D
	if collider == null:
		collider = StaticBody3D.new()
		collider.name = "Collider"
		segment_root.add_child(collider)
	collider.set_meta("surface_name", surface_name)
	collider.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
	collider.process_mode = Node.PROCESS_MODE_INHERIT

	var collision_shape := collider.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collider.add_child(collision_shape)
	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape == null:
		box_shape = BoxShape3D.new()
		collision_shape.shape = box_shape
	box_shape.size = size

static func _get_or_create_wall_segment_material(surface_name: String, color: Color, material_cache: Dictionary) -> StandardMaterial3D:
	if material_cache.has(surface_name):
		var cached := material_cache[surface_name] as StandardMaterial3D
		if cached != null:
			cached.albedo_color = color
			return cached

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.metallic_specular = 0.0
	material_cache[surface_name] = material
	return material

static func _add_wall_segment(segments_root: Node3D, index: int, surface_name: String, local_position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var segment_root := _ensure_segment_node(segments_root, index)
	_apply_segment_node(segment_root, surface_name, local_position, size, material)
