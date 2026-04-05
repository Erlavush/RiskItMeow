class_name PlacementGizmoFactory
extends RefCounted

static func make_arrow_gizmo(
	handle_id: String,
	axis: Vector3,
	color: Color,
	collision_layer: int,
	handle_nodes: Dictionary,
	handle_materials: Dictionary,
	handle_base_colors: Dictionary
) -> Node3D:
	var root := Node3D.new()
	root.name = handle_id

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color * 0.18

	handle_nodes[handle_id] = root
	handle_materials[handle_id] = material
	handle_base_colors[handle_id] = color

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.035
	stem_mesh.bottom_radius = 0.035
	stem_mesh.height = 0.72
	stem.mesh = stem_mesh
	stem.material_override = material
	stem.position = Vector3(0.0, 0.36, 0.0)
	root.add_child(stem)

	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.08
	head_mesh.height = 0.2
	head.mesh = head_mesh
	head.material_override = material
	head.position = Vector3(0.0, 0.82, 0.0)
	root.add_child(head)

	if axis == Vector3.RIGHT:
		root.rotation_degrees = Vector3(0.0, 0.0, -90.0)
	elif axis == Vector3.BACK:
		root.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	root.add_child(_make_gizmo_pick_body(handle_id, Vector3(0.0, 0.44, 0.0), BoxShape3D.new(), Vector3(0.18, 0.9, 0.18), collision_layer))
	return root

static func make_rotation_ring(
	handle_id: String,
	ring_radius: float,
	collision_layer: int,
	handle_nodes: Dictionary,
	handle_materials: Dictionary,
	handle_base_colors: Dictionary
) -> Node3D:
	var ring_root := Node3D.new()
	ring_root.name = handle_id
	ring_root.position = Vector3(0.0, 0.05, 0.0)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.74, 0.24, 0.95)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(1.0, 0.74, 0.24, 1.0) * 0.18

	handle_nodes[handle_id] = ring_root
	handle_materials[handle_id] = material
	handle_base_colors[handle_id] = Color(1.0, 0.74, 0.24, 0.95)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = ring_radius - 0.03
	torus.outer_radius = ring_radius + 0.03
	torus.rings = 28
	torus.ring_segments = 12
	ring.mesh = torus
	ring.material_override = material
	ring_root.add_child(ring)
	_add_rotation_ring_pick_bodies(ring_root, handle_id, ring_radius, collision_layer)

	return ring_root

static func _make_gizmo_pick_body(handle_id: String, local_position: Vector3, shape: Shape3D, shape_size: Vector3, collision_layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = collision_layer
	body.collision_mask = 0
	body.set_meta("handle_id", handle_id)
	body.position = local_position

	var collision_shape := CollisionShape3D.new()
	if shape is BoxShape3D:
		var box_shape := shape as BoxShape3D
		box_shape.size = shape_size
	elif shape is SphereShape3D:
		var sphere_shape := shape as SphereShape3D
		sphere_shape.radius = shape_size.x
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body

static func _add_rotation_ring_pick_bodies(ring_root: Node3D, handle_id: String, ring_radius: float, collision_layer: int) -> void:
	for segment_index in 12:
		var angle := TAU * float(segment_index) / 12.0
		var pick_body := _make_gizmo_pick_body(
			handle_id,
			Vector3(cos(angle) * ring_radius, 0.0, sin(angle) * ring_radius),
			SphereShape3D.new(),
			Vector3(0.11, 0.0, 0.0),
			collision_layer
		)
		ring_root.add_child(pick_body)
