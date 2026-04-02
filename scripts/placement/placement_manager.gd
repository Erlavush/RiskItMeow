class_name PlacementManager
extends Node3D

const GRID_SIZE := 1.0
const CHAIR_INITIAL_STOCK := 3
const UI_MARGIN := Vector2(16.0, 140.0)
const POPUP_MARGIN := 10.0
const GIZMO_RING_RADIUS := 0.6
const ROTATION_SNAP_STEP := PI * 0.5
const GIZMO_COLLISION_LAYER := 1 << 4
const GIZMO_DISTANCE_SCALE := 0.08
const GIZMO_MIN_SCALE := 0.92
const GIZMO_MAX_SCALE := 1.34

const GridOverlayShader := preload("res://shaders/grid_overlay.gdshader")
const SimpleWoodChairScript := preload("res://scripts/placement/simple_wood_chair.gd")

@export var room_shell_path: NodePath
@export var room_camera_controller_path: NodePath
@export var player_path: NodePath

var _chair_stock: int = CHAIR_INITIAL_STOCK
var _placed_chair_count: int = 0
var _manual_grid_visible := false
var _placement_active := false
var _placement_valid := false
var _placement_issue_code := ""
var _placement_issue_text := ""
var _hover_target := ""
var _drag_mode := ""
var _drag_start_position := Vector3.ZERO
var _drag_start_rotation_y := 0.0
var _drag_rotation_start_angle := 0.0

var _room_shell: RoomShell
var _room_camera_controller: Node
var _player: Node
var _placed_items_root: Node3D
var _grid_overlay: MeshInstance3D
var _gizmo_root: Node3D
var _preview_chair: SimpleWoodChair
var _placement_query_shape := BoxShape3D.new()
var _gizmo_handle_nodes := {}
var _gizmo_handle_materials := {}
var _gizmo_handle_base_colors := {}

var _ui_layer: CanvasLayer
var _ui_root: Control
var _inventory_panel: PanelContainer
var _chair_button: Button
var _stock_label: Label
var _status_label: Label
var _grid_toggle_button: Button
var _popup_panel: PanelContainer
var _popup_status_label: Label
var _popup_hint_label: Label
var _confirm_button: Button
var _cancel_button: Button

func _ready() -> void:
	_room_shell = get_node_or_null(room_shell_path) as RoomShell
	_room_camera_controller = get_node_or_null(room_camera_controller_path)
	_player = get_node_or_null(player_path)

	_placed_items_root = Node3D.new()
	_placed_items_root.name = "PlacedItems"
	add_child(_placed_items_root)

	_build_grid_overlay()
	_build_gizmo()
	_build_ui()
	_sync_player_with_room()
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()

func _process(_delta: float) -> void:
	if not _placement_active or _preview_chair == null:
		_popup_panel.visible = false
		_gizmo_root.visible = false
		return

	if _drag_mode == "":
		_hover_target = _pick_interaction_target(get_viewport().get_mouse_position())
	else:
		_hover_target = _drag_mode

	if _preview_chair != null:
		_preview_chair.set_hovered(_hover_target == "move" or _drag_mode == "move")

	_update_gizmo_hover_state()
	_update_popup_position()
	_update_gizmo_transform()

func _input(event: InputEvent) -> void:
	if not _placement_active or _preview_chair == null or event == null:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_button.pressed:
			if _is_pointer_over_placement_ui():
				return

			var target := _pick_interaction_target(mouse_button.position)
			match target:
				"move", "axis_x", "axis_z", "rotate":
					_begin_drag(target, mouse_button.position)
					get_viewport().set_input_as_handled()
				"floor":
					_update_preview_from_mouse(true)
					get_viewport().set_input_as_handled()
			return

		if _drag_mode != "":
			_end_drag()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _drag_mode != "":
		var mouse_motion := event as InputEventMouseMotion
		_update_drag(mouse_motion.position)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not _placement_active or event == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_on_confirm_button_pressed()
				get_viewport().set_input_as_handled()
			KEY_Q:
				_rotate_preview(-1)
				get_viewport().set_input_as_handled()
			KEY_E, KEY_R:
				_rotate_preview(1)
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_cancel_current_placement()
				get_viewport().set_input_as_handled()

func _build_grid_overlay() -> void:
	_grid_overlay = MeshInstance3D.new()
	_grid_overlay.name = "GridOverlay"
	_grid_overlay.visible = false

	var plane_mesh := PlaneMesh.new()
	var floor_size := _get_overlay_size()
	plane_mesh.size = floor_size
	plane_mesh.subdivide_depth = 12
	plane_mesh.subdivide_width = 12
	_grid_overlay.mesh = plane_mesh

	var material := ShaderMaterial.new()
	material.shader = GridOverlayShader
	material.set_shader_parameter("grid_size", GRID_SIZE)
	material.set_shader_parameter("line_width", 0.05)
	material.set_shader_parameter("dot_length", 0.24)
	material.set_shader_parameter("dot_gap", 0.18)
	_grid_overlay.material_override = material
	add_child(_grid_overlay)

	_refresh_grid_overlay_transform()

func _build_gizmo() -> void:
	_gizmo_root = Node3D.new()
	_gizmo_root.name = "PlacementGizmo"
	_gizmo_root.visible = false
	add_child(_gizmo_root)

	_gizmo_root.add_child(_make_arrow_gizmo("axis_x", Vector3.RIGHT, Color(0.96, 0.29, 0.24, 1.0)))
	_gizmo_root.add_child(_make_arrow_gizmo("axis_z", Vector3.BACK, Color(0.28, 0.62, 1.0, 1.0)))
	_gizmo_root.add_child(_make_rotation_ring("rotate"))

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "PlacementUi"
	add_child(_ui_layer)

	_ui_root = Control.new()
	_ui_root.name = "Root"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_ui_root)

	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.position = UI_MARGIN
	_inventory_panel.custom_minimum_size = Vector2(240.0, 0.0)
	_ui_root.add_child(_inventory_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_inventory_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Build Inventory"
	layout.add_child(title)

	_chair_button = Button.new()
	_chair_button.text = SimpleWoodChair.DISPLAY_NAME
	_chair_button.custom_minimum_size = Vector2(220.0, 44.0)
	_chair_button.pressed.connect(_on_chair_button_pressed)
	layout.add_child(_chair_button)

	_stock_label = Label.new()
	layout.add_child(_stock_label)

	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(220.0, 72.0)
	layout.add_child(_status_label)

	_grid_toggle_button = Button.new()
	_grid_toggle_button.custom_minimum_size = Vector2(220.0, 36.0)
	_grid_toggle_button.pressed.connect(_on_grid_toggle_button_pressed)
	layout.add_child(_grid_toggle_button)

	_popup_panel = PanelContainer.new()
	_popup_panel.name = "PlacementPopup"
	_popup_panel.visible = false
	_popup_panel.custom_minimum_size = Vector2(156.0, 82.0)
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_popup_panel)

	var popup_margin := MarginContainer.new()
	popup_margin.add_theme_constant_override("margin_left", 8)
	popup_margin.add_theme_constant_override("margin_top", 8)
	popup_margin.add_theme_constant_override("margin_right", 8)
	popup_margin.add_theme_constant_override("margin_bottom", 8)
	_popup_panel.add_child(popup_margin)

	var popup_layout := VBoxContainer.new()
	popup_layout.add_theme_constant_override("separation", 6)
	popup_margin.add_child(popup_layout)

	_popup_status_label = Label.new()
	_popup_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_status_label.add_theme_font_size_override("font_size", 13)
	popup_layout.add_child(_popup_status_label)

	var popup_row := HBoxContainer.new()
	popup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_row.add_theme_constant_override("separation", 6)
	popup_margin.add_child(popup_row)

	_confirm_button = Button.new()
	_confirm_button.text = "✓"
	_confirm_button.tooltip_text = "Place chair"
	_confirm_button.text = "Place"
	_confirm_button.custom_minimum_size = Vector2(46.0, 30.0)
	_confirm_button.custom_minimum_size = Vector2(68.0, 32.0)
	_confirm_button.add_theme_font_size_override("font_size", 14)
	_confirm_button.pressed.connect(_on_confirm_button_pressed)
	popup_row.add_child(_confirm_button)

	_cancel_button = Button.new()
	_cancel_button.text = "X"
	_cancel_button.tooltip_text = "Cancel placement"
	_cancel_button.custom_minimum_size = Vector2(46.0, 30.0)
	_cancel_button.custom_minimum_size = Vector2(62.0, 32.0)
	_cancel_button.add_theme_font_size_override("font_size", 14)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	popup_row.add_child(_cancel_button)

	popup_row.reparent(popup_layout)

	_popup_hint_label = Label.new()
	_popup_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_hint_label.add_theme_font_size_override("font_size", 11)
	popup_layout.add_child(_popup_hint_label)

	_update_popup_visuals()

func _sync_player_with_room() -> void:
	if _room_shell == null or _player == null:
		return

	if _player.has_method("set_room_bounds_half_extents"):
		_player.call("set_room_bounds_half_extents", _room_shell.get_walkable_half_extents())

	if _player.has_method("set_floor_y"):
		_player.call("set_floor_y", _room_shell.get_floor_y())

func _on_chair_button_pressed() -> void:
	if _placement_active or _chair_stock <= 0:
		return

	_chair_stock -= 1
	_preview_chair = SimpleWoodChairScript.new() as SimpleWoodChair
	_preview_chair.name = "%s Preview" % SimpleWoodChair.DISPLAY_NAME
	add_child(_preview_chair)
	_preview_chair.set_preview_mode(true)
	_placement_query_shape.size = _preview_chair.get_collision_size()

	_placement_active = true
	_placement_valid = false
	_update_preview_from_mouse(true)
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()

func _on_grid_toggle_button_pressed() -> void:
	_manual_grid_visible = not _manual_grid_visible
	_update_grid_visibility()
	_update_inventory_ui()

func _on_confirm_button_pressed() -> void:
	if not _placement_active or not _placement_valid or _preview_chair == null:
		return

	var placed_chair := SimpleWoodChairScript.new() as SimpleWoodChair
	placed_chair.name = "%s %d" % [SimpleWoodChair.DISPLAY_NAME, _placed_chair_count + 1]
	_placed_items_root.add_child(placed_chair)
	placed_chair.global_transform = _preview_chair.global_transform
	placed_chair.set_preview_mode(false)

	_placed_chair_count += 1
	_finish_current_placement(false)

func _on_cancel_button_pressed() -> void:
	_cancel_current_placement()

func _cancel_current_placement() -> void:
	if not _placement_active:
		return

	_finish_current_placement(true)

func _finish_current_placement(refund_stock: bool) -> void:
	if refund_stock:
		_chair_stock += 1

	if _preview_chair != null:
		_preview_chair.queue_free()
		_preview_chair = null

	_placement_active = false
	_placement_valid = false
	_placement_issue_code = ""
	_placement_issue_text = ""
	_hover_target = ""
	_drag_mode = ""
	_popup_panel.visible = false
	_gizmo_root.visible = false
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()

func _update_preview_from_mouse(use_current_mouse: bool) -> void:
	if _preview_chair == null or _room_shell == null:
		return

	var target_position: Vector3 = _preview_chair.global_position
	if use_current_mouse:
		var hit := _try_get_floor_hit(get_viewport().get_mouse_position())
		if hit.get("valid", false):
			target_position = hit["position"] as Vector3

	_set_preview_position(target_position)

func _rotate_preview(direction: int) -> void:
	if _preview_chair == null:
		return

	_preview_chair.rotate_y(deg_to_rad(90.0 * float(direction)))
	_refresh_preview_validity()

func _evaluate_preview_transform() -> Dictionary:
	if _preview_chair == null or _room_shell == null:
		return {"valid": false, "code": "missing", "reason": "Placement unavailable"}

	var room_origin: Vector3 = _room_shell.global_position
	var room_half_extents := _room_shell.get_inner_half_extents()
	var footprint := _preview_chair.get_footprint_half_extents()
	var local_x: float = _preview_chair.global_position.x - room_origin.x
	var local_z: float = _preview_chair.global_position.z - room_origin.z

	if absf(local_x) + footprint.x > room_half_extents.x:
		return {"valid": false, "code": "bounds", "reason": "Too close to edge"}
	if absf(local_z) + footprint.y > room_half_extents.y:
		return {"valid": false, "code": "bounds", "reason": "Too close to edge"}

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _placement_query_shape
	query.collision_mask = SimpleWoodChair.COLLISION_LAYER
	query.transform = Transform3D(
		Basis.IDENTITY.rotated(Vector3.UP, _preview_chair.rotation.y),
		_preview_chair.global_position + _preview_chair.get_collision_center_offset()
	)

	if not space_state.intersect_shape(query, 4).is_empty():
		return {"valid": false, "code": "occupied", "reason": "Space occupied"}

	return {"valid": true, "code": "valid", "reason": "Ready to place"}

func _refresh_preview_validity() -> void:
	if _preview_chair == null:
		return

	var evaluation := _evaluate_preview_transform()
	_placement_valid = evaluation.get("valid", false)
	_placement_issue_code = String(evaluation.get("code", ""))
	_placement_issue_text = String(evaluation.get("reason", ""))
	_preview_chair.set_preview_valid(_placement_valid)
	_preview_chair.set_hovered(_hover_target == "move" or _drag_mode == "move")
	_confirm_button.disabled = not _placement_valid
	_popup_panel.visible = true
	_gizmo_root.visible = true
	_update_popup_visuals()
	_update_status_text()

func _update_inventory_ui() -> void:
	var grid_visible := _manual_grid_visible or _placement_active
	_chair_button.disabled = _chair_stock <= 0 or _placement_active
	_stock_label.text = "Stock: %d / %d" % [_chair_stock, CHAIR_INITIAL_STOCK]
	_grid_toggle_button.text = "Grid Overlay: %s" % ("On" if grid_visible else "Off")

func _update_status_text() -> void:
	if _placement_active:
		if _placement_valid:
			_status_label.text = "Ready to place %s.\nLeft-drag the chair, use the gizmo handles, or click a floor cell. Q/E still rotates." % SimpleWoodChair.DISPLAY_NAME
		else:
			match _placement_issue_code:
				"bounds":
					_status_label.text = "Blocked by the room edge.\nKeep the chair fully inside the floor before placing."
				"occupied":
					_status_label.text = "Blocked by another chair.\nMove to a clear cell, or press X / Esc to cancel."
				_:
					_status_label.text = "Blocked placement.\nMove away from walls or another chair, or press X / Esc to cancel."
		return

	if _chair_stock <= 0:
		_status_label.text = "All chairs are deployed.\nUse the grid toggle if you still want to inspect spacing."
		return

	_status_label.text = "Click %s to start placement.\nThe dotted grid will turn on automatically while placing." % SimpleWoodChair.DISPLAY_NAME

func _update_grid_visibility() -> void:
	if _grid_overlay == null:
		return

	_refresh_grid_overlay_transform()
	_grid_overlay.visible = _manual_grid_visible or _placement_active

func _refresh_grid_overlay_transform() -> void:
	if _grid_overlay == null or _room_shell == null:
		return

	_grid_overlay.global_position = _room_shell.global_position + Vector3(0.0, 0.03, 0.0)

func _update_popup_position() -> void:
	if _preview_chair == null:
		return

	var camera := _get_active_camera()
	if camera == null:
		return

	var anchor_world: Vector3 = _preview_chair.global_position + Vector3(0.0, 2.22, 0.0)
	if camera.is_position_behind(anchor_world):
		_popup_panel.visible = false
		return

	_popup_panel.visible = true
	var popup_size: Vector2 = _popup_panel.get_combined_minimum_size()
	var screen_position: Vector2 = camera.unproject_position(anchor_world) - popup_size * 0.5
	screen_position.y -= 10.0
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	screen_position.x = clamp(screen_position.x, POPUP_MARGIN, viewport_size.x - popup_size.x - POPUP_MARGIN)
	screen_position.y = clamp(screen_position.y, POPUP_MARGIN, viewport_size.y - popup_size.y - POPUP_MARGIN)
	_popup_panel.position = screen_position

func _update_gizmo_transform() -> void:
	if _preview_chair == null:
		return

	_gizmo_root.global_position = _preview_chair.global_position + Vector3(0.0, 0.88, 0.0)
	_gizmo_root.rotation.y = _preview_chair.rotation.y
	var camera := _get_active_camera()
	if camera != null:
		var camera_distance: float = camera.global_position.distance_to(_gizmo_root.global_position)
		var gizmo_scale: float = clampf(camera_distance * GIZMO_DISTANCE_SCALE, GIZMO_MIN_SCALE, GIZMO_MAX_SCALE)
		_gizmo_root.scale = Vector3.ONE * gizmo_scale

func _get_active_camera() -> Camera3D:
	if _room_camera_controller != null and _room_camera_controller.has_method("get_camera"):
		return _room_camera_controller.call("get_camera") as Camera3D

	return get_viewport().get_camera_3d()

func _get_overlay_size() -> Vector2:
	if _room_shell == null:
		return Vector2(12.0, 12.0)

	var extents := _room_shell.get_inner_half_extents()
	return extents * 2.0

func _get_grid_min_corner() -> Vector2:
	if _room_shell == null:
		return Vector2(-6.0, -6.0)

	var extents: Vector2 = _room_shell.get_inner_half_extents()
	return Vector2(
		_room_shell.global_position.x - extents.x,
		_room_shell.global_position.z - extents.y
	)

func _is_pointer_over_placement_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered != null:
		if hovered == _inventory_panel or hovered == _popup_panel:
			return true
		hovered = hovered.get_parent() as Control

	return false

func _pick_interaction_target(mouse_position: Vector2) -> String:
	if _preview_chair == null or _is_pointer_over_placement_ui():
		return ""

	var gizmo_hit := _raycast_from_mouse(mouse_position, GIZMO_COLLISION_LAYER)
	if not gizmo_hit.is_empty():
		var gizmo_collider := gizmo_hit.get("collider") as CollisionObject3D
		if gizmo_collider != null and gizmo_collider.has_meta("handle_id"):
			return String(gizmo_collider.get_meta("handle_id"))

	var preview_hit := _raycast_from_mouse(mouse_position, SimpleWoodChair.PREVIEW_PICK_LAYER)
	if not preview_hit.is_empty():
		return "move"
	if _try_get_floor_hit(mouse_position).get("valid", false):
		return "floor"

	return ""

func _begin_drag(mode: String, mouse_position: Vector2) -> void:
	_drag_mode = mode
	_drag_start_position = _preview_chair.global_position
	_drag_start_rotation_y = _preview_chair.rotation.y
	_drag_rotation_start_angle = _get_floor_angle_around_preview(mouse_position)
	_hover_target = mode
	_update_gizmo_hover_state()

func _update_drag(mouse_position: Vector2) -> void:
	match _drag_mode:
		"move":
			var free_hit := _try_get_floor_hit(mouse_position)
			if free_hit.get("valid", false):
				_set_preview_position(free_hit["position"] as Vector3)
		"axis_x":
			var x_hit := _try_get_floor_hit(mouse_position)
			if x_hit.get("valid", false):
				_set_preview_position(_project_point_onto_drag_axis(x_hit["position"] as Vector3, "axis_x"))
		"axis_z":
			var z_hit := _try_get_floor_hit(mouse_position)
			if z_hit.get("valid", false):
				_set_preview_position(_project_point_onto_drag_axis(z_hit["position"] as Vector3, "axis_z"))
		"rotate":
			var current_angle := _get_floor_angle_around_preview(mouse_position)
			var delta_angle := wrapf(current_angle - _drag_rotation_start_angle, -PI, PI)
			var rotation_steps: float = round(delta_angle / ROTATION_SNAP_STEP)
			_preview_chair.rotation.y = _drag_start_rotation_y + rotation_steps * ROTATION_SNAP_STEP
			_refresh_preview_validity()

func _end_drag() -> void:
	_drag_mode = ""
	_hover_target = _pick_interaction_target(get_viewport().get_mouse_position())
	_update_gizmo_hover_state()

func _set_preview_position(target_position: Vector3) -> void:
	_preview_chair.global_position = _snap_position_to_grid(target_position)
	_refresh_preview_validity()

func _project_point_onto_drag_axis(target_position: Vector3, axis_mode: String) -> Vector3:
	var axis_direction := _get_drag_axis_direction(axis_mode)
	if axis_direction.length_squared() <= 0.0001:
		return _drag_start_position

	var planar_offset := Vector3(
		target_position.x - _drag_start_position.x,
		0.0,
		target_position.z - _drag_start_position.z
	)
	var distance_along_axis: float = planar_offset.dot(axis_direction)
	var constrained_position := _drag_start_position + axis_direction * distance_along_axis
	constrained_position.y = _room_shell.get_floor_y()
	return constrained_position

func _get_drag_axis_direction(axis_mode: String) -> Vector3:
	if _preview_chair == null:
		return Vector3.ZERO

	var axis_basis := Basis(Vector3.UP, _drag_start_rotation_y)
	var axis_direction := axis_basis.x if axis_mode == "axis_x" else axis_basis.z
	axis_direction.y = 0.0
	if axis_direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	return axis_direction.normalized()

func _snap_position_to_grid(target_position: Vector3) -> Vector3:
	var grid_min: Vector2 = _get_grid_min_corner()
	var room_extents: Vector2 = _room_shell.get_inner_half_extents()
	var cell_count_x: int = maxi(1, int(round(room_extents.x * 2.0 / GRID_SIZE)))
	var cell_count_z: int = maxi(1, int(round(room_extents.y * 2.0 / GRID_SIZE)))
	var snapped_cell_x: int = clampi(int(floor((target_position.x - grid_min.x) / GRID_SIZE)), 0, cell_count_x - 1)
	var snapped_cell_z: int = clampi(int(floor((target_position.z - grid_min.y) / GRID_SIZE)), 0, cell_count_z - 1)
	return Vector3(
		grid_min.x + (float(snapped_cell_x) + 0.5) * GRID_SIZE,
		_room_shell.get_floor_y(),
		grid_min.y + (float(snapped_cell_z) + 0.5) * GRID_SIZE
	)

func _try_get_floor_hit(mouse_position: Vector2) -> Dictionary:
	var camera := _get_active_camera()
	if camera == null or _room_shell == null:
		return {"valid": false}

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_position)
	var floor_y := _room_shell.get_floor_y()
	if absf(ray_normal.y) <= 0.0001:
		return {"valid": false}

	var hit_distance: float = (floor_y - ray_origin.y) / ray_normal.y
	if hit_distance <= 0.0:
		return {"valid": false}

	return {
		"valid": true,
		"position": ray_origin + ray_normal * hit_distance,
	}

func _raycast_from_mouse(mouse_position: Vector2, collision_mask: int) -> Dictionary:
	var camera := _get_active_camera()
	if camera == null:
		return {}

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_position)
	var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 128.0, collision_mask)
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(ray_query)

func _get_floor_angle_around_preview(mouse_position: Vector2) -> float:
	var hit := _try_get_floor_hit(mouse_position)
	if not hit.get("valid", false):
		return 0.0

	var hit_position := hit["position"] as Vector3
	var flat_offset := Vector2(
		hit_position.x - _preview_chair.global_position.x,
		hit_position.z - _preview_chair.global_position.z
	)
	if flat_offset.length_squared() <= 0.0001:
		return 0.0
	return flat_offset.angle()

func _update_gizmo_hover_state() -> void:
	for handle_id in _gizmo_handle_materials.keys():
		var material := _gizmo_handle_materials[handle_id] as StandardMaterial3D
		var base_color := _gizmo_handle_base_colors[handle_id] as Color
		var handle_node := _gizmo_handle_nodes.get(handle_id) as Node3D
		if material == null:
			continue

		var is_active: bool = handle_id == _hover_target or handle_id == _drag_mode
		var next_color: Color = base_color.lerp(Color.WHITE, 0.5) if is_active else base_color
		material.albedo_color = next_color
		material.emission_enabled = true
		material.emission = next_color * (0.92 if is_active else 0.24)
		if handle_node != null:
			handle_node.scale = Vector3.ONE * (1.12 if is_active else 1.0)

func _update_popup_visuals() -> void:
	if _popup_panel == null or _confirm_button == null or _cancel_button == null:
		return

	var panel_bg: Color
	var panel_border: Color
	var status_color: Color
	if _placement_valid:
		panel_bg = Color(0.08, 0.12, 0.1, 0.92)
		panel_border = Color(0.38, 0.92, 0.58, 0.96)
		status_color = Color(0.9, 1.0, 0.92, 1.0)
		if _popup_status_label != null:
			_popup_status_label.text = "Ready"
		if _popup_hint_label != null:
			_popup_hint_label.text = "LMB drag  |  Q/E rotate"
	else:
		panel_bg = Color(0.15, 0.09, 0.09, 0.94)
		panel_border = Color(0.98, 0.34, 0.34, 0.98)
		status_color = Color(1.0, 0.92, 0.92, 1.0)
		if _popup_status_label != null:
			_popup_status_label.text = _placement_issue_text
		if _popup_hint_label != null:
			_popup_hint_label.text = "Move to a clear cell"

	_popup_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_bg, panel_border))
	if _popup_status_label != null:
		_popup_status_label.add_theme_color_override("font_color", status_color)
	if _popup_hint_label != null:
		_popup_hint_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.95, 0.84))

	_apply_button_style(
		_confirm_button,
		Color(0.22, 0.58, 0.33, 0.98),
		Color(0.42, 0.98, 0.62, 0.98),
		Color(0.96, 1.0, 0.97, 1.0)
	)
	_apply_button_style(
		_cancel_button,
		Color(0.24, 0.26, 0.31, 0.98),
		Color(0.54, 0.58, 0.68, 0.98),
		Color(0.97, 0.98, 1.0, 1.0)
	)

func _apply_button_style(button: Button, bg_color: Color, border_color: Color, font_color: Color) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", _make_panel_style(bg_color, border_color, 1, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(bg_color.lerp(Color.WHITE, 0.12), border_color.lerp(Color.WHITE, 0.22), 1, 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(bg_color.lerp(Color.BLACK, 0.18), border_color, 1, 8))
	button.add_theme_stylebox_override("disabled", _make_panel_style(bg_color.lerp(Color.BLACK, 0.45), border_color.lerp(Color.BLACK, 0.55), 1, 8))
	button.add_theme_stylebox_override("focus", _make_panel_style(bg_color, border_color, 1, 8))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", font_color.lerp(Color.BLACK, 0.45))

func _make_panel_style(background_color: Color, border_color: Color, border_width: int = 2, corner_radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	style.shadow_size = 6
	return style

func _make_arrow_gizmo(handle_id: String, axis: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = handle_id

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.metallic = 0.0
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = color * 0.18

	_gizmo_handle_nodes[handle_id] = root
	_gizmo_handle_materials[handle_id] = material
	_gizmo_handle_base_colors[handle_id] = color

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

	root.add_child(_make_gizmo_pick_body(handle_id, Vector3(0.0, 0.44, 0.0), BoxShape3D.new(), Vector3(0.18, 0.9, 0.18)))
	return root

func _make_rotation_ring(handle_id: String) -> Node3D:
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

	_gizmo_handle_nodes[handle_id] = ring_root
	_gizmo_handle_materials[handle_id] = material
	_gizmo_handle_base_colors[handle_id] = Color(1.0, 0.74, 0.24, 0.95)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = GIZMO_RING_RADIUS - 0.03
	torus.outer_radius = GIZMO_RING_RADIUS + 0.03
	torus.rings = 28
	torus.ring_segments = 12
	ring.mesh = torus
	ring.material_override = material
	ring_root.add_child(ring)
	_add_rotation_ring_pick_bodies(ring_root, handle_id)

	return ring_root

func _make_gizmo_pick_body(handle_id: String, local_position: Vector3, shape: Shape3D, shape_size: Vector3 = Vector3.ONE) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = GIZMO_COLLISION_LAYER
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

func _add_rotation_ring_pick_bodies(ring_root: Node3D, handle_id: String) -> void:
	for segment_index in 12:
		var angle := TAU * float(segment_index) / 12.0
		var pick_body := _make_gizmo_pick_body(
			handle_id,
			Vector3(cos(angle) * GIZMO_RING_RADIUS, 0.0, sin(angle) * GIZMO_RING_RADIUS),
			SphereShape3D.new(),
			Vector3(0.11, 0.0, 0.0)
		)
		ring_root.add_child(pick_body)
