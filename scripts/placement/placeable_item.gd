@tool
class_name PlaceableItem
extends StaticBody3D

const COLLISION_LAYER := 1 << 1
const PREVIEW_PICK_LAYER := 1 << 2
const PREVIEW_VALID_COLOR := Color(0.36, 0.96, 0.48, 0.82)
const PREVIEW_INVALID_COLOR := Color(0.96, 0.28, 0.28, 0.86)
const FOOTPRINT_THICKNESS := 0.025
const FOOTPRINT_PADDING := 0.14
const OUTLINE_PADDING := 0.08
const WALL_MOUNT_CLEARANCE := 0.01

var _is_preview := false
var _preview_is_valid := true
var _is_hovered := false
var _camera_cutaway := false
var _visual_root: Node3D
var _preview_material: StandardMaterial3D
var _outline_mesh_instance: MeshInstance3D
var _outline_material: StandardMaterial3D
var _footprint_marker: MeshInstance3D
var _footprint_material: StandardMaterial3D
var _mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	if name.is_empty() or name.begins_with("@"):
		name = get_display_name()

	ensure_runtime_visual_setup()

func ensure_runtime_visual_setup() -> void:
	_ensure_collision_shape()
	_ensure_visual()
	_ensure_feedback_visuals()
	_apply_mode()

func get_display_name() -> String:
	return "Placeable Item"

func get_primary_mount_kind() -> String:
	return RoomConstants.MOUNT_FLOOR

func get_mount_kinds() -> Array[String]:
	return [get_primary_mount_kind()]

func get_placement_surface_kind() -> String:
	return RoomConstants.SURFACE_DECOR if get_primary_mount_kind() == RoomConstants.MOUNT_WALL else RoomConstants.FLOOR_SURFACE

func get_default_wall_surface() -> String:
	return RoomConstants.WALL_BACK

func get_supported_wall_surfaces() -> Array[String]:
	return []

func requires_wall_opening() -> bool:
	return false

func hides_with_cutaway_wall() -> bool:
	return requires_wall_opening()

func get_wall_half_extents() -> Vector2:
	var collision_size := get_collision_size()
	return Vector2(collision_size.x * 0.5, collision_size.y * 0.5)

func get_wall_opening_half_extents() -> Vector2:
	return Vector2.ZERO

func get_wall_mount_depth_offset() -> float:
	if requires_wall_opening():
		return 0.0
	return get_collision_size().z * 0.5 + WALL_MOUNT_CLEARANCE

func supports_rotation() -> bool:
	return true

func get_wall_rotation_offset() -> float:
	return 0.0

func get_collision_size() -> Vector3:
	return Vector3.ONE

func get_collision_center_offset() -> Vector3:
	return Vector3(0.0, get_collision_size().y * 0.5, 0.0)

func get_footprint_half_extents() -> Vector2:
	var collision_size := get_collision_size()
	return Vector2(collision_size.x * 0.5, collision_size.z * 0.5)

func can_host_surface_items() -> bool:
	return false

func get_support_surfaces() -> Array[Dictionary]:
	return []

func build_top_support_surface(surface_id: String = "top") -> Dictionary:
	var top_center_y := get_collision_center_offset().y + get_collision_size().y * 0.5
	var padded_half_extents := get_footprint_half_extents() - Vector2.ONE * 0.06
	return {
		"id": surface_id,
		"center_offset": Vector3(0.0, top_center_y, 0.0),
		"half_extents": Vector2(maxf(padded_half_extents.x, 0.08), maxf(padded_half_extents.y, 0.08)),
	}

func get_visual_scene_path() -> String:
	return ""

func get_visual_scale() -> Vector3:
	return Vector3.ONE

func get_visual_y_offset() -> float:
	return 0.0

func get_runtime_shadow_cast_setting() -> GeometryInstance3D.ShadowCastingSetting:
	return GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func set_preview_mode(value: bool) -> void:
	_is_preview = value
	if is_node_ready():
		_apply_mode()

func set_preview_valid(value: bool) -> void:
	_preview_is_valid = value
	if is_node_ready():
		_apply_preview_color()

func set_hovered(value: bool) -> void:
	_is_hovered = value
	if is_node_ready():
		_apply_preview_color()

func set_camera_cutaway(value: bool) -> void:
	_camera_cutaway = value
	if is_node_ready():
		_apply_mode()

func _ensure_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)

	if collision_shape.shape == null:
		collision_shape.shape = BoxShape3D.new()

	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape != null:
		box_shape.size = get_collision_size()

	collision_shape.position = get_collision_center_offset()

func _ensure_visual() -> void:
	_visual_root = get_node_or_null("VisualRoot") as Node3D
	if _visual_root == null:
		_visual_root = Node3D.new()
		_visual_root.name = "VisualRoot"
		add_child(_visual_root)

	if _visual_root.get_child_count() == 0:
		var scene_path = get_visual_scene_path()
		var visual_scene: PackedScene = null
		if not scene_path.is_empty():
			visual_scene = load(scene_path) as PackedScene
			
		if visual_scene != null:
			var imported_visual := visual_scene.instantiate()
			imported_visual.name = "ImportedVisual"
			imported_visual.scale = get_visual_scale()
			imported_visual.position = Vector3(0.0, get_visual_y_offset(), 0.0)
			_visual_root.add_child(imported_visual)
		else:
			_create_fallback_visual()

	_mesh_instances.clear()
	_collect_mesh_instances(_visual_root)

func _ensure_feedback_visuals() -> void:
	_outline_mesh_instance = get_node_or_null("PreviewOutline") as MeshInstance3D
	var collision_size := get_collision_size()
	if _outline_mesh_instance == null:
		_outline_mesh_instance = MeshInstance3D.new()
		_outline_mesh_instance.name = "PreviewOutline"
		_outline_mesh_instance.mesh = _build_outline_mesh(collision_size + Vector3.ONE * OUTLINE_PADDING)
		_outline_mesh_instance.position = get_collision_center_offset()
		_outline_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_outline_mesh_instance)

	_footprint_marker = get_node_or_null("FootprintMarker") as MeshInstance3D
	if _footprint_marker == null:
		_footprint_marker = MeshInstance3D.new()
		_footprint_marker.name = "FootprintMarker"
		var footprint_mesh := BoxMesh.new()
		footprint_mesh.size = Vector3(
			collision_size.x + FOOTPRINT_PADDING,
			FOOTPRINT_THICKNESS,
			collision_size.z + FOOTPRINT_PADDING
		)
		_footprint_marker.mesh = footprint_mesh
		_footprint_marker.position = Vector3(0.0, FOOTPRINT_THICKNESS * 0.5, 0.0)
		_footprint_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_footprint_marker)

func _collect_mesh_instances(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			mesh_instance.extra_cull_margin = 8.0
			_mesh_instances.append(mesh_instance)
		_collect_mesh_instances(child)

func _apply_mode() -> void:
	if _is_preview:
		collision_layer = PREVIEW_PICK_LAYER
	elif _camera_cutaway:
		collision_layer = 0
	else:
		collision_layer = (1 << 0) | COLLISION_LAYER
	collision_mask = 0
	_apply_preview_color()

func _apply_preview_color() -> void:
	if _visual_root != null:
		_visual_root.visible = _is_preview or not _camera_cutaway

	if not _is_preview:
		var runtime_shadow_cast: GeometryInstance3D.ShadowCastingSetting = get_runtime_shadow_cast_setting()
		for mesh_instance in _mesh_instances:
			mesh_instance.visible = not _camera_cutaway
			mesh_instance.cast_shadow = runtime_shadow_cast
			if _camera_cutaway and runtime_shadow_cast != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			mesh_instance.material_override = null
			mesh_instance.material_overlay = null
		if _outline_mesh_instance != null:
			_outline_mesh_instance.visible = false
		if _footprint_marker != null:
			_footprint_marker.visible = false
		return

	if _mesh_instances.is_empty():
		return

	if _preview_material == null:
		_preview_material = StandardMaterial3D.new()
		_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_preview_material.albedo_color = _with_alpha(PREVIEW_VALID_COLOR, 0.34)
		_preview_material.roughness = 0.22
		_preview_material.metallic = 0.0
		_preview_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_preview_material.emission_enabled = true

	if _outline_material == null:
		_outline_material = StandardMaterial3D.new()
		_outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_outline_material.emission_enabled = true
		if _outline_mesh_instance != null:
			_outline_mesh_instance.material_override = _outline_material

	if _footprint_material == null:
		_footprint_material = StandardMaterial3D.new()
		_footprint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_footprint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_footprint_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_footprint_material.emission_enabled = true
		if _footprint_marker != null:
			_footprint_marker.material_override = _footprint_material

	var base_color: Color = PREVIEW_VALID_COLOR if _preview_is_valid else PREVIEW_INVALID_COLOR
	var emphasis_color: Color = base_color.lerp(Color.WHITE, 0.28 if _is_hovered else 0.1)
	_preview_material.albedo_color = _with_alpha(base_color, 0.34 if _preview_is_valid else 0.42)
	_preview_material.emission = base_color * (0.36 if _preview_is_valid else 0.52)

	if _outline_material != null:
		_outline_material.albedo_color = _with_alpha(emphasis_color, 0.95)
		_outline_material.emission = emphasis_color * (0.72 if _is_hovered else 0.46)
	if _outline_mesh_instance != null:
		_outline_mesh_instance.visible = true
		_outline_mesh_instance.scale = Vector3.ONE * (1.03 if _is_hovered else 1.0)

	if _footprint_material != null:
		_footprint_material.albedo_color = _with_alpha(base_color, 0.18 if _preview_is_valid else 0.26)
		_footprint_material.emission = base_color * (0.3 if _preview_is_valid else 0.58)
	if _footprint_marker != null:
		_footprint_marker.visible = true
		_footprint_marker.scale = Vector3.ONE * (1.06 if _is_hovered else 1.0)

	for mesh_instance in _mesh_instances:
		mesh_instance.visible = true
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.material_override = null
		mesh_instance.material_overlay = _preview_material

func _build_outline_mesh(size: Vector3) -> ImmediateMesh:
	var half_size: Vector3 = size * 0.5
	var bottom_y: float = -half_size.y
	var top_y: float = half_size.y
	var corners: Array[Vector3] = [
		Vector3(-half_size.x, bottom_y, -half_size.z),
		Vector3(half_size.x, bottom_y, -half_size.z),
		Vector3(half_size.x, bottom_y, half_size.z),
		Vector3(-half_size.x, bottom_y, half_size.z),
		Vector3(-half_size.x, top_y, -half_size.z),
		Vector3(half_size.x, top_y, -half_size.z),
		Vector3(half_size.x, top_y, half_size.z),
		Vector3(-half_size.x, top_y, half_size.z),
	]
	var edge_pairs: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]

	var mesh := ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for edge in edge_pairs:
		mesh.surface_add_vertex(corners[edge[0]])
		mesh.surface_add_vertex(corners[edge[1]])
	mesh.surface_end()
	return mesh

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

func _create_fallback_visual() -> void:
	var pink_color := Color(0.9, 0.4, 0.6, 1.0)
	_add_box_piece(get_collision_size(), get_collision_center_offset(), pink_color)

func _add_box_piece(size: Vector3, offset: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	var material := StandardMaterial3D.new()

	box_mesh.size = size
	material.albedo_color = color
	material.roughness = 0.9
	material.metallic_specular = 0.0

	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	mesh_instance.position = offset
	_visual_root.add_child(mesh_instance)
