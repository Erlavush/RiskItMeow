@tool
class_name PlacementItemPreview
extends SubViewportContainer

const PREVIEW_SIZE := Vector2i(160, 120)
const PREVIEW_PADDING := 1.32
const PREVIEW_CAMERA_DIRECTION := Vector3(1.0, 1.15, 1.0)

var _viewport: SubViewport
var _preview_root: Node3D
var _preview_camera: Camera3D
var _preview_environment: WorldEnvironment
var _content_root: Node3D
var _pending_item_def: Dictionary = {}
var _pending_item_factory: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	custom_minimum_size = Vector2(PREVIEW_SIZE.x, PREVIEW_SIZE.y)
	_build_viewport()
	if not _pending_item_def.is_empty():
		configure(_pending_item_def, _pending_item_factory)

func configure(item_def: Dictionary, item_factory: Callable) -> void:
	_pending_item_def = item_def.duplicate(true)
	_pending_item_factory = item_factory
	if not is_node_ready():
		return
	_clear_content()
	if item_factory == null or not item_factory.is_valid():
		return
	var placeable := item_factory.call(item_def) as SimpleWoodChair
	if placeable == null:
		return
	placeable.ensure_runtime_visual_setup()
	_prepare_placeable_for_preview(placeable)
	_content_root.add_child(placeable)
	placeable.ensure_runtime_visual_setup()
	_frame_placeable(placeable)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _build_viewport() -> void:
	if _viewport != null:
		return

	_viewport = SubViewport.new()
	_viewport.name = "PreviewViewport"
	_viewport.disable_3d = false
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.size = PREVIEW_SIZE
	add_child(_viewport)

	_preview_root = Node3D.new()
	_preview_root.name = "PreviewRoot"
	_viewport.add_child(_preview_root)

	_preview_environment = WorldEnvironment.new()
	_preview_environment.name = "PreviewEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.06, 0.08, 0.1, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 0.96, 0.92, 1.0)
	environment.ambient_light_energy = 0.85
	_preview_environment.environment = environment
	_preview_root.add_child(_preview_environment)

	_content_root = Node3D.new()
	_content_root.name = "ContentRoot"
	_preview_root.add_child(_content_root)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_energy = 1.35
	key_light.light_color = Color(1.0, 0.93, 0.84, 1.0)
	key_light.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	_preview_root.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_energy = 0.55
	fill_light.light_color = Color(0.84, 0.9, 1.0, 1.0)
	fill_light.rotation_degrees = Vector3(-18.0, -140.0, 0.0)
	_preview_root.add_child(fill_light)

	_preview_camera = Camera3D.new()
	_preview_camera.name = "PreviewCamera"
	_preview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_preview_camera.current = true
	_preview_camera.near = 0.01
	_preview_camera.far = 64.0
	_preview_root.add_child(_preview_camera)

func _clear_content() -> void:
	if _content_root == null:
		return
	for child in _content_root.get_children():
		_content_root.remove_child(child)
		child.queue_free()

func _prepare_placeable_for_preview(placeable: SimpleWoodChair) -> void:
	placeable.collision_layer = 0
	placeable.collision_mask = 0
	placeable.process_mode = Node.PROCESS_MODE_DISABLED
	placeable.set_preview_mode(false)
	placeable.set_camera_cutaway(false)
	var collision_shape := placeable.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape != null:
		collision_shape.disabled = true
	var outline := placeable.get_node_or_null("PreviewOutline") as VisualInstance3D
	if outline != null:
		outline.visible = false
	var footprint := placeable.get_node_or_null("FootprintMarker") as VisualInstance3D
	if footprint != null:
		footprint.visible = false

func _frame_placeable(placeable: SimpleWoodChair) -> void:
	var bounds := _compute_visual_bounds(placeable)
	var min_corner: Vector3 = bounds.get("min", Vector3.ZERO) as Vector3
	var max_corner: Vector3 = bounds.get("max", placeable.get_collision_size()) as Vector3
	var center := (min_corner + max_corner) * 0.5
	var size := max_corner - min_corner
	if size.length_squared() <= 0.0001:
		size = placeable.get_collision_size()

	placeable.position = Vector3(-center.x, -min_corner.y, -center.z)
	var max_dimension := maxf(size.x, maxf(size.y, size.z))
	var look_target := Vector3(0.0, size.y * 0.38, 0.0)
	var camera_direction := PREVIEW_CAMERA_DIRECTION.normalized()
	_preview_camera.size = maxf(0.6, max_dimension * PREVIEW_PADDING)
	_preview_camera.global_position = look_target + camera_direction * maxf(3.2, max_dimension * 3.6)
	_preview_camera.look_at(look_target, Vector3.UP)

func capture_image() -> Image:
	if _viewport == null:
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	return _viewport.get_texture().get_image()

func _compute_visual_bounds(root: Node3D) -> Dictionary:
	var state: Dictionary = {
		"ready": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_bounds_recursive(root, Transform3D.IDENTITY, state)
	if not state.get("ready", false):
		return {
			"min": Vector3.ZERO,
			"max": Vector3.ONE,
		}
	return {
		"min": state.get("min", Vector3.ZERO),
		"max": state.get("max", Vector3.ZERO),
	}

func _accumulate_bounds_recursive(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
		if node_3d is MeshInstance3D:
			var mesh_instance := node_3d as MeshInstance3D
			if mesh_instance.mesh != null and mesh_instance.visible:
				_merge_mesh_aabb(mesh_instance.mesh.get_aabb(), current_transform, state)
	for child in node.get_children():
		_accumulate_bounds_recursive(child, current_transform, state)

func _merge_mesh_aabb(aabb: AABB, transform: Transform3D, state: Dictionary) -> void:
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
		var world_corner: Vector3 = transform * corner
		if not state.get("ready", false):
			state["ready"] = true
			state["min"] = world_corner
			state["max"] = world_corner
			continue
		var minimum: Vector3 = state.get("min", Vector3.ZERO) as Vector3
		var maximum: Vector3 = state.get("max", Vector3.ZERO) as Vector3
		minimum.x = minf(minimum.x, world_corner.x)
		minimum.y = minf(minimum.y, world_corner.y)
		minimum.z = minf(minimum.z, world_corner.z)
		maximum.x = maxf(maximum.x, world_corner.x)
		maximum.y = maxf(maximum.y, world_corner.y)
		maximum.z = maxf(maximum.z, world_corner.z)
		state["min"] = minimum
		state["max"] = maximum
