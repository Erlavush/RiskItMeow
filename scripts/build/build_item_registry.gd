class_name BuildItemRegistry
extends RefCounted

const PlacementTypes := preload("res://scripts/build/placement_types.gd")

static func get_catalog_order() -> Array[String]:
	return [
		"coffee_table",
		"wall_frame",
		"ceiling_lantern",
		"flower_vase",
	]

static func get_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for item_id in get_catalog_order():
		catalog.append(get_definition(item_id))
	return catalog

static func get_definition(item_id: String) -> Dictionary:
	var definitions := {
		"coffee_table": {
			"id": "coffee_table",
			"label": "Coffee Table",
			"family": PlacementTypes.FAMILY_FLOOR,
			"surface": PlacementTypes.SURFACE_FLOOR,
			"size": Vector3(1.5, 0.76, 0.9),
			"footprint": Vector2(1.5, 0.9),
			"color": Color(0.604, 0.424, 0.251, 1.0),
			"accent_color": Color(0.855, 0.741, 0.58, 1.0),
			"support_surface_size": Vector2(1.12, 0.52),
			"support_surface_height": 0.76,
			"description": "Floor host for surface decor."
		},
		"wall_frame": {
			"id": "wall_frame",
			"label": "Wall Frame",
			"family": PlacementTypes.FAMILY_WALL,
			"surface": PlacementTypes.SURFACE_WALL_BACK,
			"size": Vector3(1.25, 0.92, 0.08),
			"footprint": Vector2(1.25, 0.92),
			"color": Color(0.769, 0.612, 0.38, 1.0),
			"accent_color": Color(0.427, 0.686, 0.8, 1.0),
			"mount_height": 1.7,
			"description": "Wall decor for any side of the room."
		},
		"ceiling_lantern": {
			"id": "ceiling_lantern",
			"label": "Ceiling Lantern",
			"family": PlacementTypes.FAMILY_CEILING,
			"surface": PlacementTypes.SURFACE_CEILING,
			"size": Vector3(0.65, 0.9, 0.65),
			"footprint": Vector2(0.65, 0.65),
			"color": Color(0.894, 0.753, 0.353, 1.0),
			"accent_color": Color(0.996, 0.949, 0.776, 1.0),
			"description": "Overhead decor snapped to the ceiling grid."
		},
		"flower_vase": {
			"id": "flower_vase",
			"label": "Flower Vase",
			"family": PlacementTypes.FAMILY_SURFACE,
			"surface": PlacementTypes.SURFACE_SURFACE,
			"size": Vector3(0.34, 0.48, 0.34),
			"footprint": Vector2(0.34, 0.34),
			"color": Color(0.909, 0.686, 0.769, 1.0),
			"accent_color": Color(0.42, 0.761, 0.467, 1.0),
			"description": "Surface decor anchored to a support host."
		},
	}
	return (definitions.get(item_id, {}) as Dictionary).duplicate(true)

static func create_item_node(item_id: String, preview: bool = false) -> Node3D:
	var definition := get_definition(item_id)
	var root := Node3D.new()
	root.name = str(definition.get("label", item_id)).replace(" ", "")
	root.set_meta("item_id", item_id)

	match str(definition.get("family", "")):
		PlacementTypes.FAMILY_FLOOR:
			_build_floor_item(root, definition, preview)
		PlacementTypes.FAMILY_WALL:
			_build_wall_item(root, definition, preview)
		PlacementTypes.FAMILY_CEILING:
			_build_ceiling_item(root, definition, preview)
		PlacementTypes.FAMILY_SURFACE:
			_build_surface_item(root, definition, preview)

	return root

static func set_preview_validity(node: Node, is_valid: bool) -> void:
	var tint := Color(0.365, 0.863, 0.557, 0.58) if is_valid else Color(0.941, 0.349, 0.333, 0.58)
	_apply_preview_tint(node, tint)

static func supports_surface_host(item_id: String) -> bool:
	return get_definition(item_id).has("support_surface_size")

static func _build_floor_item(root: Node3D, definition: Dictionary, preview: bool) -> void:
	var size: Vector3 = definition.get("size", Vector3.ONE)
	var top_thickness := 0.12
	var leg_size := Vector3(0.12, size.y - top_thickness, 0.12)
	var top_center := Vector3(0.0, size.y - top_thickness * 0.5, 0.0)
	_add_box(root, "Top", Vector3(size.x, top_thickness, size.z), top_center, definition.get("color"), preview)

	var leg_y := (size.y - top_thickness) * 0.5
	var leg_offset_x := size.x * 0.5 - 0.12
	var leg_offset_z := size.z * 0.5 - 0.12
	_add_box(root, "LegA", leg_size, Vector3(-leg_offset_x, leg_y, -leg_offset_z), definition.get("accent_color"), preview)
	_add_box(root, "LegB", leg_size, Vector3(leg_offset_x, leg_y, -leg_offset_z), definition.get("accent_color"), preview)
	_add_box(root, "LegC", leg_size, Vector3(-leg_offset_x, leg_y, leg_offset_z), definition.get("accent_color"), preview)
	_add_box(root, "LegD", leg_size, Vector3(leg_offset_x, leg_y, leg_offset_z), definition.get("accent_color"), preview)

static func _build_wall_item(root: Node3D, definition: Dictionary, preview: bool) -> void:
	var size: Vector3 = definition.get("size", Vector3.ONE)
	_add_box(root, "FrameOuter", size, Vector3(0.0, 0.0, size.z * 0.5), definition.get("color"), preview)
	_add_box(root, "FrameInner", Vector3(size.x - 0.18, size.y - 0.18, size.z * 0.6), Vector3(0.0, 0.0, size.z * 0.56), definition.get("accent_color"), preview)

static func _build_ceiling_item(root: Node3D, definition: Dictionary, preview: bool) -> void:
	var size: Vector3 = definition.get("size", Vector3.ONE)
	_add_box(root, "Cap", Vector3(0.12, 0.16, 0.12), Vector3(0.0, -0.08, 0.0), definition.get("color"), preview)
	_add_cylinder(root, "Body", 0.24, 0.52, Vector3(0.0, -0.34, 0.0), definition.get("accent_color"), preview)
	_add_box(root, "Base", Vector3(size.x, 0.14, size.z), Vector3(0.0, -0.68, 0.0), definition.get("color"), preview)

static func _build_surface_item(root: Node3D, definition: Dictionary, preview: bool) -> void:
	_add_cylinder(root, "Vase", 0.12, 0.28, Vector3(0.0, 0.14, 0.0), definition.get("color"), preview)
	_add_sphere(root, "Bloom", 0.16, Vector3(0.0, 0.36, 0.0), definition.get("accent_color"), preview)

static func _add_box(root: Node3D, name: String, size: Vector3, center: Vector3, color: Color, preview: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = _make_material(color, preview)
	root.add_child(mesh_instance)

static func _add_cylinder(root: Node3D, name: String, radius: float, height: float, center: Vector3, color: Color, preview: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = _make_material(color, preview)
	root.add_child(mesh_instance)

static func _add_sphere(root: Node3D, name: String, radius: float, center: Vector3, color: Color, preview: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = _make_material(color, preview)
	root.add_child(mesh_instance)

static func _make_material(color: Color, preview: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.metallic_specular = 0.0
	if preview:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.58
	return material

static func _apply_preview_tint(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = _make_material(tint, true)

	for child in node.get_children():
		_apply_preview_tint(child, tint)
