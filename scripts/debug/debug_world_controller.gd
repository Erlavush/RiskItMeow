class_name DebugWorldController
extends Node3D

signal debug_world_enabled_changed(enabled: bool)

const PlacementItemProfileOverrideStoreScript := preload("res://scripts/placement/placement_item_profile_override_store.gd")
const CheckerShader := preload("res://shaders/floor_checker.gdshader")

const DEBUG_GIZMO_COLLISION_LAYER := 1 << 4

const STUDIO_MODE_PREVIEW := "preview"
const STUDIO_MODE_EDIT := "edit"

const HEADER_WIDTH := 640.0
const HEADER_HEIGHT := 108.0
const SIDE_BUTTON_SIZE := Vector2(76.0, 104.0)
const EXIT_BUTTON_SIZE := Vector2(88.0, 44.0)
const EDIT_BUTTON_SIZE := Vector2(188.0, 52.0)
const EDIT_PANEL_WIDTH := 372.0
const EDIT_PANEL_TOP := 112.0
const EDIT_PANEL_BOTTOM := 28.0
const UI_MARGIN := 18.0
const FIELD_HEIGHT := 36.0
const CHIP_HEIGHT := 32.0

const CAMERA_FOV := 34.0
const CAMERA_NEAR := 0.02
const CAMERA_FAR := 128.0
const CAMERA_MIN_DISTANCE := 1.9
const CAMERA_MAX_DISTANCE := 16.0
const CAMERA_DISTANCE_PADDING := 1.9
const CAMERA_DEFAULT_YAW := 0.72
const CAMERA_DEFAULT_PITCH := 0.32
const CAMERA_MIN_PITCH := -1.1
const CAMERA_MAX_PITCH := 1.18
const CAMERA_DRAG_SENSITIVITY := 0.008
const CAMERA_ZOOM_STEP := 0.72

const PREVIEW_SPIN_SPEED := 0.42

const FLOOR_GUIDE_SIZE := 3.0
const FLOOR_GUIDE_THICKNESS := 0.06
const WALL_GUIDE_WIDTH := 4.8
const WALL_GUIDE_HEIGHT := 3.8
const WALL_GUIDE_THICKNESS := 0.08
const CEILING_GUIDE_SIZE := Vector2(3.2, 3.2)
const CEILING_GUIDE_THICKNESS := 0.08
const CEILING_GUIDE_Y := 3.3
const SURFACE_TABLE_TOP_Y := 1.08
const SURFACE_TABLE_HEIGHT := 0.96
const SURFACE_TABLE_TOP_SIZE := Vector2(2.1, 1.4)
const SURFACE_ITEM_CLEARANCE := 0.01
const GUIDE_WALL_SURFACE := RoomConstants.WALL_BACK

const OVERLAY_THICKNESS := 0.028
const SUPPORT_OVERLAY_THICKNESS := 0.024
const WALL_GUIDE_ALPHA := 0.28
const WALL_GUIDE_HIDDEN_ALPHA := 0.0

const GIZMO_DISTANCE_SCALE := 0.08
const GIZMO_MIN_SCALE := 0.92
const GIZMO_MAX_SCALE := 1.36
const TUNING_SCALE_MIN := 0.01
const TUNING_SCALE_MAX := 6.0
const TUNING_DIMENSION_MAX := 12.0
const TUNING_OFFSET_MAX := 8.0
const TUNING_YAW_MIN := -360.0
const TUNING_YAW_MAX := 360.0
const TUNING_FINE_STEP := 0.01

const GIZMO_MODE_VISUAL_SCALE := "visual_scale"
const GIZMO_MODE_VISUAL_LIFT := "visual_lift"
const GIZMO_MODE_VISUAL_YAW := "visual_yaw"
const GIZMO_MODE_COLLISION_SIZE := "collision_size"
const GIZMO_MODE_COLLISION_OFFSET := "collision_offset"
const GIZMO_MODE_FOOTPRINT := "footprint"
const GIZMO_MODE_WALL_BOUNDS := "wall_bounds"
const GIZMO_MODE_WALL_OPENING := "wall_opening"

@export var room_shell_path: NodePath
@export var placement_manager_path: NodePath
@export var room_camera_controller_path: NodePath
@export var player_path: NodePath

var _room_shell: RoomShell
var _placement_manager: PlacementManager
var _room_camera_controller: RoomViewCameraController
var _player: Node

var _saved_room_camera_target := Vector3.ZERO
var _has_saved_room_camera_target := false

var _debug_world_enabled := false
var _studio_mode := STUDIO_MODE_PREVIEW
var _search_text := ""
var _all_item_defs: Array[Dictionary] = []
var _filtered_item_defs: Array[Dictionary] = []
var _selected_filtered_index := -1
var _current_item_id := ""
var _current_item: SimpleWoodChair
var _current_item_def: Dictionary = {}
var _has_unsaved_changes := false
var _syncing_controls := false

var _orbit_yaw := CAMERA_DEFAULT_YAW
var _orbit_pitch := CAMERA_DEFAULT_PITCH
var _orbit_distance := 5.6
var _orbit_drag_active := false
var _orbit_drag_start_mouse := Vector2.ZERO

var _gizmo_mode := ""
var _gizmo_drag_active := false
var _gizmo_drag_handle_id := ""
var _gizmo_drag_start_mouse := Vector2.ZERO
var _gizmo_drag_start_values: Dictionary = {}

var _overlay_collision_visible := true
var _overlay_footprint_visible := false
var _overlay_wall_bounds_visible := false
var _overlay_wall_opening_visible := false
var _overlay_support_visible := false
var _wall_guide_visible := true

var _studio_root: Node3D
var _stage_root: Node3D
var _guide_root: Node3D
var _item_holder: Node3D
var _camera: Camera3D
var _gizmo_root: Node3D

var _floor_guide: MeshInstance3D
var _wall_guide_root: Node3D
var _ceiling_guide: MeshInstance3D
var _surface_table_root: Node3D

var _collision_overlay: MeshInstance3D
var _footprint_overlay: MeshInstance3D
var _wall_bounds_overlay: MeshInstance3D
var _wall_opening_overlay: MeshInstance3D
var _support_overlay_root: Node3D

var _ui_layer: CanvasLayer
var _ui_root: Control
var _exit_button: Button
var _header_panel: PanelContainer
var _search_input: LineEdit
var _title_label: Label
var _meta_label: Label
var _previous_item_button: Button
var _next_item_button: Button
var _edit_mode_button: Button
var _edit_panel: PanelContainer
var _edit_scroll: ScrollContainer
var _edit_content: VBoxContainer
var _edit_summary_label: Label
var _edit_status_label: Label
var _back_button: Button
var _save_button: Button
var _reset_saved_button: Button
var _revert_unsaved_button: Button
var _overlay_buttons: Dictionary = {}
var _gizmo_buttons: Dictionary = {}
var _mount_option: OptionButton
var _visual_scale_spin_boxes: Array[SpinBox] = []
var _visual_lift_spin_box: SpinBox
var _visual_yaw_spin_box: SpinBox
var _collision_size_spin_boxes: Array[SpinBox] = []
var _collision_offset_spin_boxes: Array[SpinBox] = []
var _footprint_spin_boxes: Array[SpinBox] = []
var _wall_bounds_spin_boxes: Array[SpinBox] = []
var _wall_opening_spin_boxes: Array[SpinBox] = []
var _can_host_surface_button: CheckButton
var _requires_wall_opening_button: CheckButton

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_room_shell = get_node_or_null(room_shell_path) as RoomShell
	_placement_manager = get_node_or_null(placement_manager_path) as PlacementManager
	_room_camera_controller = get_node_or_null(room_camera_controller_path) as RoomViewCameraController
	_player = get_node_or_null(player_path)
	if _room_camera_controller != null:
		_saved_room_camera_target = _room_camera_controller.target_position
		_has_saved_room_camera_target = true

	_refresh_catalog_item_defs()
	_build_studio_world()
	_build_ui()
	_set_studio_visible(false)
	set_process(true)
	set_process_unhandled_input(true)

func is_debug_world_enabled() -> bool:
	return _debug_world_enabled

func set_debug_world_enabled(enabled: bool) -> void:
	if _debug_world_enabled == enabled:
		return

	_debug_world_enabled = enabled
	if _debug_world_enabled:
		if _room_camera_controller != null:
			_saved_room_camera_target = _room_camera_controller.target_position
			_has_saved_room_camera_target = true
		_apply_external_mode_state(true)
		_refresh_catalog_item_defs()
		_apply_search_filter()
		_set_studio_mode(STUDIO_MODE_PREVIEW)
		_set_studio_visible(true)
		_set_debug_camera_current(true)
		if _filtered_item_defs.is_empty():
			_clear_current_item()
		elif not _load_item_by_id(_current_item_id, true):
			_load_filtered_index(0, true)
	else:
		_discard_unsaved_changes()
		_end_gizmo_drag()
		_orbit_drag_active = false
		_set_debug_camera_current(false)
		_set_studio_visible(false)
		_apply_external_mode_state(false)
		_restore_room_camera()

	debug_world_enabled_changed.emit(_debug_world_enabled)

func _process(delta: float) -> void:
	if not _debug_world_enabled:
		return

	if _studio_mode == STUDIO_MODE_PREVIEW and not _filtered_item_defs.is_empty() and not _orbit_drag_active and not _gizmo_drag_active:
		_item_holder.rotation.y += PREVIEW_SPIN_SPEED * delta

	_update_camera_transform()
	_update_gizmo_scale()

func _is_debug_world_toggle_key(key_event: InputEventKey) -> bool:
	if key_event == null:
		return false
	return key_event.keycode == KEY_KP_7 \
		or key_event.physical_keycode == KEY_KP_7 \
		or key_event.keycode == KEY_HOME \
		or key_event.physical_keycode == KEY_HOME

func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return

	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and not key_event.echo and _is_debug_world_toggle_key(key_event):
			set_debug_world_enabled(not _debug_world_enabled)
			get_viewport().set_input_as_handled()
			return

	if not _debug_world_enabled:
		return

	if event is InputEventKey:
		var studio_key_event = event as InputEventKey
		if studio_key_event.pressed and not studio_key_event.echo and studio_key_event.keycode == KEY_ESCAPE:
			if _studio_mode == STUDIO_MODE_EDIT:
				_set_studio_mode(STUDIO_MODE_PREVIEW)
			else:
				set_debug_world_enabled(false)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		var mouse_button = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			if not _is_pointer_over_ui():
				_orbit_distance = clampf(_orbit_distance - CAMERA_ZOOM_STEP, CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE)
				get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			if not _is_pointer_over_ui():
				_orbit_distance = clampf(_orbit_distance + CAMERA_ZOOM_STEP, CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE)
				get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_button.pressed and not _is_pointer_over_ui() and not _gizmo_drag_active:
				_orbit_drag_active = true
				_orbit_drag_start_mouse = mouse_button.position
				get_viewport().set_input_as_handled()
			else:
				_orbit_drag_active = false
			return
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				if _studio_mode == STUDIO_MODE_EDIT and not _is_pointer_over_ui():
					var handle_id = _pick_gizmo_handle(mouse_button.position)
					if not handle_id.is_empty():
						_begin_gizmo_drag(handle_id, mouse_button.position)
						get_viewport().set_input_as_handled()
				return
			if _gizmo_drag_active:
				_end_gizmo_drag()
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		var mouse_motion = event as InputEventMouseMotion
		if _gizmo_drag_active:
			_update_gizmo_drag(mouse_motion.position)
			get_viewport().set_input_as_handled()
			return
		if _orbit_drag_active:
			_orbit_yaw -= mouse_motion.relative.x * CAMERA_DRAG_SENSITIVITY
			_orbit_pitch = clampf(_orbit_pitch + mouse_motion.relative.y * CAMERA_DRAG_SENSITIVITY, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
			get_viewport().set_input_as_handled()

func _build_studio_world() -> void:
	_studio_root = Node3D.new()
	_studio_root.name = "StudioRoot"
	add_child(_studio_root)

	_stage_root = Node3D.new()
	_stage_root.name = "StageRoot"
	_studio_root.add_child(_stage_root)

	_guide_root = Node3D.new()
	_guide_root.name = "GuideRoot"
	_stage_root.add_child(_guide_root)

	_item_holder = Node3D.new()
	_item_holder.name = "ItemHolder"
	_stage_root.add_child(_item_holder)

	_gizmo_root = Node3D.new()
	_gizmo_root.name = "GizmoRoot"
	_stage_root.add_child(_gizmo_root)

	_camera = Camera3D.new()
	_camera.name = "DebugStudioCamera"
	_camera.fov = CAMERA_FOV
	_camera.near = CAMERA_NEAR
	_camera.far = CAMERA_FAR
	_camera.current = false
	_studio_root.add_child(_camera)

	_build_stage_guides()

func _build_stage_guides() -> void:
	_floor_guide = MeshInstance3D.new()
	_floor_guide.name = "FloorGuide"
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(FLOOR_GUIDE_SIZE, FLOOR_GUIDE_THICKNESS, FLOOR_GUIDE_SIZE)
	_floor_guide.mesh = floor_mesh
	_floor_guide.position = Vector3(0.0, FLOOR_GUIDE_THICKNESS * 0.5, 0.0)
	var floor_material = ShaderMaterial.new()
	floor_material.shader = CheckerShader
	floor_material.set_shader_parameter("checker_size", 1.0)
	floor_material.set_shader_parameter("light_color", Color(0.98, 0.97, 0.93, 1.0))
	floor_material.set_shader_parameter("dark_color", Color(0.05, 0.05, 0.07, 1.0))
	floor_material.set_shader_parameter("checker_offset", Vector2(0.5, 0.5))
	_floor_guide.material_override = floor_material
	_floor_guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_guide_root.add_child(_floor_guide)

	_wall_guide_root = Node3D.new()
	_wall_guide_root.name = "WallGuideRoot"
	_guide_root.add_child(_wall_guide_root)

	_ceiling_guide = MeshInstance3D.new()
	_ceiling_guide.name = "CeilingGuide"
	var ceiling_mesh = BoxMesh.new()
	ceiling_mesh.size = Vector3(CEILING_GUIDE_SIZE.x, CEILING_GUIDE_THICKNESS, CEILING_GUIDE_SIZE.y)
	_ceiling_guide.mesh = ceiling_mesh
	_ceiling_guide.position = Vector3(0.0, CEILING_GUIDE_Y, 0.0)
	_ceiling_guide.material_override = _make_guide_material(Color(0.92, 0.95, 1.0, 0.55))
	_ceiling_guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_guide_root.add_child(_ceiling_guide)

	_surface_table_root = Node3D.new()
	_surface_table_root.name = "SurfaceTable"
	_guide_root.add_child(_surface_table_root)
	_build_surface_table_geometry()
	_update_stage_guides()

func _build_surface_table_geometry() -> void:
	for child in _surface_table_root.get_children():
		child.queue_free()

	var top = MeshInstance3D.new()
	var top_mesh = BoxMesh.new()
	top_mesh.size = Vector3(SURFACE_TABLE_TOP_SIZE.x, 0.12, SURFACE_TABLE_TOP_SIZE.y)
	top.mesh = top_mesh
	top.position = Vector3(0.0, SURFACE_TABLE_TOP_Y, 0.0)
	top.material_override = _make_solid_material(Color(0.67, 0.49, 0.32, 1.0), 0.95)
	_surface_table_root.add_child(top)

	var leg_offsets = [
		Vector3(-0.86, SURFACE_TABLE_HEIGHT * 0.5, -0.52),
		Vector3(0.86, SURFACE_TABLE_HEIGHT * 0.5, -0.52),
		Vector3(-0.86, SURFACE_TABLE_HEIGHT * 0.5, 0.52),
		Vector3(0.86, SURFACE_TABLE_HEIGHT * 0.5, 0.52),
	]
	for leg_offset_value in leg_offsets:
		var leg = MeshInstance3D.new()
		var leg_mesh = BoxMesh.new()
		leg_mesh.size = Vector3(0.14, SURFACE_TABLE_HEIGHT, 0.14)
		leg.mesh = leg_mesh
		leg.position = leg_offset_value
		leg.material_override = _make_solid_material(Color(0.52, 0.37, 0.24, 1.0), 0.96)
		_surface_table_root.add_child(leg)

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 30
	add_child(_ui_layer)

	_ui_root = Control.new()
	_ui_root.name = "DebugStudioUi"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_ui_root)

	_exit_button = Button.new()
	_exit_button.text = "Exit"
	_exit_button.custom_minimum_size = EXIT_BUTTON_SIZE
	_exit_button.position = Vector2(UI_MARGIN, UI_MARGIN)
	_exit_button.pressed.connect(_on_exit_pressed)
	_apply_action_button_style(_exit_button, false, false)
	_configure_scroll_passthrough(_exit_button)
	_ui_root.add_child(_exit_button)

	_header_panel = PanelContainer.new()
	_header_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	PlacementUiStyles.apply_panel_style(_header_panel, PlacementUiStyles.COLOR_PANEL, PlacementUiStyles.COLOR_BORDER, 1, 18, 8, 0.2)
	_header_panel.custom_minimum_size = Vector2(HEADER_WIDTH, HEADER_HEIGHT)
	_header_panel.position = Vector2((_get_viewport_size().x - HEADER_WIDTH) * 0.5, UI_MARGIN)
	_ui_root.add_child(_header_panel)

	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_top", 14)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	_header_panel.add_child(header_margin)

	var header_layout = VBoxContainer.new()
	header_layout.add_theme_constant_override("separation", 8)
	header_margin.add_child(header_layout)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Search items..."
	_search_input.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	_search_input.text_changed.connect(_on_search_text_changed)
	PlacementUiStyles.apply_line_edit_style(_search_input)
	_configure_scroll_passthrough(_search_input)
	header_layout.add_child(_search_input)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 19)
	PlacementUiStyles.apply_label_style(_title_label, PlacementUiStyles.COLOR_TEXT, true)
	header_layout.add_child(_title_label)

	_meta_label = Label.new()
	_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_label.add_theme_font_size_override("font_size", 12)
	PlacementUiStyles.apply_label_style(_meta_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	header_layout.add_child(_meta_label)

	_previous_item_button = Button.new()
	_previous_item_button.text = "<"
	_previous_item_button.custom_minimum_size = SIDE_BUTTON_SIZE
	_previous_item_button.pressed.connect(_on_previous_item_pressed)
	_apply_action_button_style(_previous_item_button, false, false)
	_ui_root.add_child(_previous_item_button)

	_next_item_button = Button.new()
	_next_item_button.text = ">"
	_next_item_button.custom_minimum_size = SIDE_BUTTON_SIZE
	_next_item_button.pressed.connect(_on_next_item_pressed)
	_apply_action_button_style(_next_item_button, false, false)
	_ui_root.add_child(_next_item_button)

	_edit_mode_button = Button.new()
	_edit_mode_button.text = "Edit Mode"
	_edit_mode_button.custom_minimum_size = EDIT_BUTTON_SIZE
	_edit_mode_button.pressed.connect(_on_edit_mode_pressed)
	_apply_action_button_style(_edit_mode_button, true, false)
	_ui_root.add_child(_edit_mode_button)

	_build_edit_panel()
	_relayout_ui()
	_update_mode_visibility()

func _build_edit_panel() -> void:
	_edit_panel = PanelContainer.new()
	_edit_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	PlacementUiStyles.apply_panel_style(_edit_panel, PlacementUiStyles.COLOR_PANEL, PlacementUiStyles.COLOR_BORDER, 1, 18, 8, 0.2)
	_edit_panel.position = Vector2(UI_MARGIN, EDIT_PANEL_TOP)
	_edit_panel.custom_minimum_size = Vector2(EDIT_PANEL_WIDTH, 540.0)
	_ui_root.add_child(_edit_panel)

	var edit_margin = MarginContainer.new()
	edit_margin.add_theme_constant_override("margin_left", 12)
	edit_margin.add_theme_constant_override("margin_top", 12)
	edit_margin.add_theme_constant_override("margin_right", 12)
	edit_margin.add_theme_constant_override("margin_bottom", 12)
	_edit_panel.add_child(edit_margin)

	_edit_scroll = ScrollContainer.new()
	_edit_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_edit_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_edit_scroll.mouse_force_pass_scroll_events = true
	edit_margin.add_child(_edit_scroll)

	_edit_content = VBoxContainer.new()
	_edit_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_content.add_theme_constant_override("separation", 14)
	_edit_content.mouse_force_pass_scroll_events = true
	_edit_scroll.add_child(_edit_content)

	var action_row_one = HBoxContainer.new()
	action_row_one.add_theme_constant_override("separation", 10)
	_edit_content.add_child(action_row_one)

	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back_button.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	_back_button.pressed.connect(_on_back_pressed)
	_apply_action_button_style(_back_button, false, false)
	action_row_one.add_child(_back_button)

	_save_button = Button.new()
	_save_button.text = "Save"
	_save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_button.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	_save_button.pressed.connect(_on_save_pressed)
	_apply_action_button_style(_save_button, true, false)
	action_row_one.add_child(_save_button)

	var action_row_two = HBoxContainer.new()
	action_row_two.add_theme_constant_override("separation", 10)
	_edit_content.add_child(action_row_two)

	_reset_saved_button = Button.new()
	_reset_saved_button.text = "Reset Saved"
	_reset_saved_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset_saved_button.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	_reset_saved_button.pressed.connect(_on_reset_saved_pressed)
	_apply_action_button_style(_reset_saved_button, false, true)
	action_row_two.add_child(_reset_saved_button)

	_revert_unsaved_button = Button.new()
	_revert_unsaved_button.text = "Revert Unsaved"
	_revert_unsaved_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_revert_unsaved_button.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	_revert_unsaved_button.pressed.connect(_on_revert_unsaved_pressed)
	_apply_action_button_style(_revert_unsaved_button, false, false)
	action_row_two.add_child(_revert_unsaved_button)

	_edit_summary_label = _build_section_label("")
	_edit_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_edit_content.add_child(_wrap_section("Summary", _edit_summary_label))

	var overlays_flow = HFlowContainer.new()
	overlays_flow.add_theme_constant_override("h_separation", 8)
	overlays_flow.add_theme_constant_override("v_separation", 8)
	_edit_content.add_child(_wrap_section("Overlays", overlays_flow))
	_add_overlay_toggle_button(overlays_flow, "Collision", "collision")
	_add_overlay_toggle_button(overlays_flow, "Footprint", "footprint")
	_add_overlay_toggle_button(overlays_flow, "Wall Bounds", "wall_bounds")
	_add_overlay_toggle_button(overlays_flow, "Wall Opening", "wall_opening")
	_add_overlay_toggle_button(overlays_flow, "Support", "support")
	_add_overlay_toggle_button(overlays_flow, "Wall Guide", "wall_guide")

	var gizmo_flow = HFlowContainer.new()
	gizmo_flow.add_theme_constant_override("h_separation", 8)
	gizmo_flow.add_theme_constant_override("v_separation", 8)
	_edit_content.add_child(_wrap_section("Gizmos", gizmo_flow))
	_add_gizmo_toggle_button(gizmo_flow, "Visual Scale", GIZMO_MODE_VISUAL_SCALE)
	_add_gizmo_toggle_button(gizmo_flow, "Visual Lift", GIZMO_MODE_VISUAL_LIFT)
	_add_gizmo_toggle_button(gizmo_flow, "Visual Yaw", GIZMO_MODE_VISUAL_YAW)
	_add_gizmo_toggle_button(gizmo_flow, "Collision Size", GIZMO_MODE_COLLISION_SIZE)
	_add_gizmo_toggle_button(gizmo_flow, "Collision Offset", GIZMO_MODE_COLLISION_OFFSET)
	_add_gizmo_toggle_button(gizmo_flow, "Footprint", GIZMO_MODE_FOOTPRINT)
	_add_gizmo_toggle_button(gizmo_flow, "Wall Bounds", GIZMO_MODE_WALL_BOUNDS)
	_add_gizmo_toggle_button(gizmo_flow, "Wall Opening", GIZMO_MODE_WALL_OPENING)

	var properties_layout = VBoxContainer.new()
	properties_layout.add_theme_constant_override("separation", 10)
	_edit_content.add_child(_wrap_section("Properties", properties_layout))

	var mount_row = HBoxContainer.new()
	mount_row.add_theme_constant_override("separation", 10)
	properties_layout.add_child(mount_row)

	var mount_label = Label.new()
	mount_label.text = "Placement"
	mount_label.custom_minimum_size = Vector2(108.0, 0.0)
	mount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	PlacementUiStyles.apply_label_style(mount_label, PlacementUiStyles.COLOR_TEXT)
	mount_row.add_child(mount_label)

	_mount_option = OptionButton.new()
	_mount_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mount_option.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	_mount_option.item_selected.connect(_on_numeric_property_changed)
	PlacementUiStyles.apply_button_style(_mount_option, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	PlacementUiStyles.apply_option_button_style(_mount_option)
	_configure_scroll_passthrough(_mount_option)
	_add_option_button_item(_mount_option, "Floor", RoomConstants.MOUNT_FLOOR)
	_add_option_button_item(_mount_option, "Wall", RoomConstants.MOUNT_WALL)
	_add_option_button_item(_mount_option, "Ceiling", RoomConstants.MOUNT_CEILING)
	_add_option_button_item(_mount_option, "Surface", RoomConstants.MOUNT_SURFACE)
	mount_row.add_child(_mount_option)

	_can_host_surface_button = CheckButton.new()
	_can_host_surface_button.text = "Can host surface items"
	_can_host_surface_button.toggled.connect(_on_boolean_property_changed)
	PlacementUiStyles.apply_check_button_style(_can_host_surface_button)
	properties_layout.add_child(_can_host_surface_button)

	_requires_wall_opening_button = CheckButton.new()
	_requires_wall_opening_button.text = "Requires wall opening"
	_requires_wall_opening_button.toggled.connect(_on_boolean_property_changed)
	PlacementUiStyles.apply_check_button_style(_requires_wall_opening_button)
	properties_layout.add_child(_requires_wall_opening_button)

	_visual_scale_spin_boxes = _build_vector_row(properties_layout, "Visual Scale", ["X", "Y", "Z"], TUNING_SCALE_MIN, TUNING_SCALE_MAX, TUNING_FINE_STEP)
	_visual_lift_spin_box = _build_single_spin_row(properties_layout, "Visual Lift", -TUNING_OFFSET_MAX, TUNING_OFFSET_MAX, TUNING_FINE_STEP)
	_visual_yaw_spin_box = _build_single_spin_row(properties_layout, "Visual Yaw (deg)", TUNING_YAW_MIN, TUNING_YAW_MAX, 1.0)
	_collision_size_spin_boxes = _build_vector_row(properties_layout, "Collision Size", ["W", "H", "D"], TUNING_SCALE_MIN, TUNING_DIMENSION_MAX, TUNING_FINE_STEP)
	_collision_offset_spin_boxes = _build_vector_row(properties_layout, "Collision Offset", ["X", "Y", "Z"], -TUNING_OFFSET_MAX, TUNING_OFFSET_MAX, TUNING_FINE_STEP)
	_footprint_spin_boxes = _build_vector_row(properties_layout, "Footprint", ["W", "D"], 0.0, TUNING_DIMENSION_MAX, TUNING_FINE_STEP)
	_wall_bounds_spin_boxes = _build_vector_row(properties_layout, "Wall Bounds", ["W", "H"], 0.0, TUNING_DIMENSION_MAX, TUNING_FINE_STEP)
	_wall_opening_spin_boxes = _build_vector_row(properties_layout, "Wall Opening", ["W", "H"], 0.0, TUNING_DIMENSION_MAX, TUNING_FINE_STEP)

	_edit_status_label = Label.new()
	_edit_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_edit_status_label.add_theme_font_size_override("font_size", 11)
	PlacementUiStyles.apply_label_style(_edit_status_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	_edit_content.add_child(_edit_status_label)

	_configure_scroll_passthrough(_edit_panel)

func _wrap_section(title_text: String, content: Control) -> PanelContainer:
	var shell = PanelContainer.new()
	PlacementUiStyles.apply_panel_style(shell, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, 1, 16, 4, 0.12)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	shell.add_child(margin)

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 12)
	PlacementUiStyles.apply_label_style(title, PlacementUiStyles.COLOR_TEXT, true)
	layout.add_child(title)
	layout.add_child(content)
	return shell

func _build_section_label(text_value: String) -> Label:
	var label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	PlacementUiStyles.apply_label_style(label, PlacementUiStyles.COLOR_TEXT)
	return label

func _add_overlay_toggle_button(parent: HFlowContainer, text_value: String, key_name: String) -> void:
	var button = Button.new()
	button.toggle_mode = true
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, CHIP_HEIGHT)
	button.toggled.connect(func(enabled: bool) -> void:
		_on_overlay_toggle_changed(key_name, enabled)
	)
	_overlay_buttons[key_name] = button
	_apply_chip_style(button, false)
	_configure_scroll_passthrough(button)
	parent.add_child(button)

func _add_gizmo_toggle_button(parent: HFlowContainer, text_value: String, mode_name: String) -> void:
	var button = Button.new()
	button.toggle_mode = true
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, CHIP_HEIGHT)
	button.toggled.connect(func(enabled: bool) -> void:
		if enabled:
			_set_gizmo_mode(mode_name)
		elif _gizmo_mode == mode_name:
			_set_gizmo_mode("")
	)
	_gizmo_buttons[mode_name] = button
	_apply_chip_style(button, false)
	_configure_scroll_passthrough(button)
	parent.add_child(button)

func _build_vector_row(parent: VBoxContainer, title_text: String, component_labels: Array[String], min_value: float, max_value: float, step_value: float) -> Array[SpinBox]:
	var wrapper = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	parent.add_child(wrapper)

	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 11)
	PlacementUiStyles.apply_label_style(title, PlacementUiStyles.COLOR_TEXT)
	wrapper.add_child(title)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	wrapper.add_child(row)

	var spin_boxes: Array[SpinBox] = []
	for component_label_value in component_labels:
		var component_box = VBoxContainer.new()
		component_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		component_box.add_theme_constant_override("separation", 2)
		row.add_child(component_box)

		var label = Label.new()
		label.text = String(component_label_value)
		label.add_theme_font_size_override("font_size", 10)
		PlacementUiStyles.apply_label_style(label, PlacementUiStyles.COLOR_TEXT_SUBTLE)
		component_box.add_child(label)

		var spin_box = _create_spin_box(min_value, max_value, step_value)
		component_box.add_child(spin_box)
		spin_boxes.append(spin_box)
	return spin_boxes

func _build_single_spin_row(parent: VBoxContainer, title_text: String, min_value: float, max_value: float, step_value: float) -> SpinBox:
	var spin_boxes = _build_vector_row(parent, title_text, ["Value"], min_value, max_value, step_value)
	return spin_boxes[0] if not spin_boxes.is_empty() else null

func _create_spin_box(min_value: float, max_value: float, step_value: float) -> SpinBox:
	var spin_box = SpinBox.new()
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = step_value
	spin_box.custom_minimum_size = Vector2(0.0, FIELD_HEIGHT)
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_box.value_changed.connect(_on_numeric_property_changed)
	_configure_scroll_passthrough(spin_box)
	var line_edit = spin_box.get_line_edit()
	if line_edit != null:
		PlacementUiStyles.apply_line_edit_style(line_edit)
		_configure_scroll_passthrough(line_edit)
	return spin_box

func _configure_scroll_passthrough(control: Control) -> void:
	if control == null:
		return
	control.mouse_force_pass_scroll_events = true
	for child in control.get_children():
		if child is Control:
			_configure_scroll_passthrough(child as Control)

func _set_studio_visible(visible_state: bool) -> void:
	if _studio_root != null:
		_studio_root.visible = visible_state
	if _ui_layer != null:
		_ui_layer.visible = visible_state

func _apply_external_mode_state(debug_enabled: bool) -> void:
	if _room_shell != null:
		_room_shell.visible = not debug_enabled
	if _placement_manager != null:
		_placement_manager.set_debug_world_active(debug_enabled)
	if _player != null and _player.has_method("set_debug_world_active"):
		_player.call("set_debug_world_active", debug_enabled)
	_set_room_camera_current(not debug_enabled)

func _restore_room_camera() -> void:
	if _room_camera_controller != null and _has_saved_room_camera_target:
		_room_camera_controller.target_position = _saved_room_camera_target
		_room_camera_controller.reset_camera()
	_set_room_camera_current(true)

func _set_room_camera_current(current_value: bool) -> void:
	var target_camera: Camera3D = null
	if _room_camera_controller != null and _room_camera_controller.has_method("get_camera"):
		target_camera = _room_camera_controller.get_camera()
	elif _player != null and _player.has_method("get_active_camera"):
		target_camera = _player.call("get_active_camera") as Camera3D
	if target_camera != null:
		target_camera.current = current_value

func _set_debug_camera_current(current_value: bool) -> void:
	if _camera != null:
		_camera.current = current_value

func _refresh_catalog_item_defs() -> void:
	_all_item_defs.clear()
	for item_def in PlacementInventoryCatalog.build_item_defs():
		if not PlacementInventoryCatalog.supports_runtime_placement(item_def):
			continue
		_all_item_defs.append((item_def as Dictionary).duplicate(true))

func _apply_search_filter() -> void:
	_filtered_item_defs.clear()
	var search_value = _search_text.strip_edges().to_lower()
	for item_def in _all_item_defs:
		var item_id = String(item_def.get("id", ""))
		var display_name = String(item_def.get("display_name", item_id))
		if not search_value.is_empty():
			var lower_id = item_id.to_lower()
			var lower_name = display_name.to_lower()
			if not lower_id.contains(search_value) and not lower_name.contains(search_value):
				continue
		_filtered_item_defs.append(item_def)

	if _filtered_item_defs.is_empty():
		_selected_filtered_index = -1
		return

	if not _current_item_id.is_empty():
		for index in range(_filtered_item_defs.size()):
			var filtered_id = String(_filtered_item_defs[index].get("id", ""))
			if filtered_id == _current_item_id:
				_selected_filtered_index = index
				return
	_selected_filtered_index = 0

func _load_filtered_index(index: int, reset_camera: bool) -> void:
	if _filtered_item_defs.is_empty():
		_clear_current_item()
		return
	var clamped_index = clampi(index, 0, _filtered_item_defs.size() - 1)
	_selected_filtered_index = clamped_index
	var item_id = String(_filtered_item_defs[_selected_filtered_index].get("id", ""))
	_load_item_by_id(item_id, reset_camera)

func _load_item_by_id(item_id: String, reset_camera: bool) -> bool:
	if item_id.is_empty():
		return false

	var item_def = PlacementInventoryCatalog.find_item_definition(_all_item_defs, item_id)
	if item_def.is_empty():
		return false

	_current_item_id = item_id
	_current_item_def = item_def.duplicate(true)
	_rebuild_current_item(_current_item_def, reset_camera)
	return true

func _clear_current_item() -> void:
	_current_item_id = ""
	_current_item_def.clear()
	_destroy_current_item()
	_update_stage_guides()
	_update_ui()

func _destroy_current_item() -> void:
	_end_gizmo_drag()
	_clear_gizmo_handles()
	if _current_item != null and _current_item.get_parent() != null:
		_current_item.get_parent().remove_child(_current_item)
	if _current_item != null:
		_current_item.queue_free()
	_current_item = null
	for overlay_node in [_collision_overlay, _footprint_overlay, _wall_bounds_overlay, _wall_opening_overlay, _support_overlay_root]:
		if overlay_node != null:
			overlay_node.queue_free()
	_collision_overlay = null
	_footprint_overlay = null
	_wall_bounds_overlay = null
	_wall_opening_overlay = null
	_support_overlay_root = null
	_item_holder.rotation = Vector3.ZERO

func _rebuild_current_item(item_def: Dictionary, reset_camera: bool) -> void:
	_destroy_current_item()
	if item_def.is_empty():
		_update_ui()
		return

	var placeable = _create_item_instance(item_def)
	if placeable == null:
		_update_ui()
		return

	_current_item = placeable
	_current_item.ensure_runtime_visual_setup()
	_current_item.set_preview_mode(false)
	_current_item.set_camera_cutaway(false)
	_position_current_item()
	_item_holder.add_child(_current_item)
	_build_current_item_overlays()
	_update_stage_guides()
	_refresh_gizmo()
	if reset_camera:
		_frame_current_item()
	_update_ui()

func _position_current_item() -> void:
	if _current_item == null:
		return

	_current_item.position = Vector3.ZERO
	_current_item.rotation = Vector3.ZERO
	var mount_kind = _current_item.get_primary_mount_kind()
	match mount_kind:
		RoomConstants.MOUNT_WALL:
			var wall_center_y = WALL_GUIDE_HEIGHT * 0.5
			_current_item.position.y = wall_center_y - _current_item.get_collision_center_offset().y
			if not _current_item.requires_wall_opening():
				_current_item.position += PlacementSurfaceQueries.get_wall_interior_normal(GUIDE_WALL_SURFACE) * _current_item.get_wall_mount_depth_offset()
			_current_item.rotation.y = RoomConstants.get_wall_rotation(GUIDE_WALL_SURFACE) + _current_item.get_wall_rotation_offset()
		RoomConstants.MOUNT_CEILING:
			_current_item.position.y = CEILING_GUIDE_Y
		RoomConstants.MOUNT_SURFACE:
			_current_item.position.y = SURFACE_TABLE_TOP_Y + 0.06 + SURFACE_ITEM_CLEARANCE
		_:
			_current_item.position = Vector3.ZERO

func _create_item_instance(item_def: Dictionary) -> SimpleWoodChair:
	if PlacementInventoryCatalog.uses_imported_scene_factory(item_def):
		return PlacementInventoryCatalog.create_imported_scene_instance(item_def) as SimpleWoodChair
	var script_ref = PlacementInventoryCatalog.get_item_script(item_def)
	if script_ref == null:
		return null
	return script_ref.new() as SimpleWoodChair

func _build_current_item_overlays() -> void:
	if _current_item == null:
		return

	_collision_overlay = _make_box_overlay(_current_item.get_collision_size(), _current_item.get_collision_center_offset(), Color(0.16, 0.86, 1.0, 0.38))
	_current_item.add_child(_collision_overlay)

	var footprint_half_extents = _current_item.get_footprint_half_extents()
	if footprint_half_extents.length_squared() > 0.0001:
		var footprint_y = OVERLAY_THICKNESS * 0.5
		if _current_item.get_primary_mount_kind() == RoomConstants.MOUNT_SURFACE:
			footprint_y = SURFACE_TABLE_TOP_Y + 0.06 + SUPPORT_OVERLAY_THICKNESS * 0.5
		elif _current_item.get_primary_mount_kind() == RoomConstants.MOUNT_CEILING:
			footprint_y = -OVERLAY_THICKNESS * 0.5
		_footprint_overlay = _make_box_overlay(
			Vector3(footprint_half_extents.x * 2.0, SUPPORT_OVERLAY_THICKNESS, footprint_half_extents.y * 2.0),
			Vector3(0.0, footprint_y, 0.0),
			Color(1.0, 0.76, 0.24, 0.34)
		)
		_current_item.add_child(_footprint_overlay)

	if _current_item.get_primary_mount_kind() == RoomConstants.MOUNT_WALL:
		var wall_half_extents = _current_item.get_wall_half_extents()
		if wall_half_extents.length_squared() > 0.0001:
			_wall_bounds_overlay = _make_box_overlay(
				Vector3(wall_half_extents.x * 2.0, wall_half_extents.y * 2.0, OVERLAY_THICKNESS),
				Vector3(0.0, _current_item.get_collision_center_offset().y, 0.0),
				Color(1.0, 0.72, 0.24, 0.38)
			)
			_current_item.add_child(_wall_bounds_overlay)

		var wall_opening_half_extents = _current_item.get_wall_opening_half_extents()
		if wall_opening_half_extents.length_squared() > 0.0001 or _current_item.requires_wall_opening():
			var opening_size = wall_opening_half_extents
			if opening_size.length_squared() <= 0.0001:
				opening_size = Vector2(0.5, 0.5)
			_wall_opening_overlay = _make_box_overlay(
				Vector3(opening_size.x * 2.0, opening_size.y * 2.0, OVERLAY_THICKNESS),
				Vector3(0.0, _current_item.get_collision_center_offset().y, 0.0),
				Color(1.0, 0.46, 0.82, 0.4)
			)
			_current_item.add_child(_wall_opening_overlay)

	var support_surfaces = _current_item.get_support_surfaces()
	if not support_surfaces.is_empty():
		_support_overlay_root = Node3D.new()
		_support_overlay_root.name = "SupportOverlays"
		_current_item.add_child(_support_overlay_root)
		for raw_support_surface in support_surfaces:
			if typeof(raw_support_surface) != TYPE_DICTIONARY:
				continue
			var support_surface = raw_support_surface as Dictionary
			var center_offset = support_surface.get("center_offset", Vector3.ZERO) as Vector3
			var half_extents = support_surface.get("half_extents", Vector2.ZERO) as Vector2
			if half_extents.x <= 0.001 or half_extents.y <= 0.001:
				continue
			var overlay = _make_box_overlay(
				Vector3(half_extents.x * 2.0, SUPPORT_OVERLAY_THICKNESS, half_extents.y * 2.0),
				center_offset + Vector3(0.0, SUPPORT_OVERLAY_THICKNESS * 0.5, 0.0),
				Color(0.3, 0.9, 0.54, 0.34)
			)
			_support_overlay_root.add_child(overlay)

	_update_overlay_visibility()

func _make_box_overlay(size_value: Vector3, local_position: Vector3, color_value: Color) -> MeshInstance3D:
	var overlay = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size_value
	overlay.mesh = mesh
	overlay.position = local_position
	overlay.material_override = _make_overlay_material(color_value)
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return overlay

func _make_overlay_material(color_value: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color_value
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	material.emission_enabled = true
	material.emission = color_value
	material.emission_energy_multiplier = 0.36
	return material

func _make_guide_material(color_value: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color_value
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color_value
	material.emission_energy_multiplier = 0.16
	return material

func _make_solid_material(color_value: Color, roughness_value: float) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color_value
	material.roughness = roughness_value
	material.metallic = 0.0
	return material

func _update_stage_guides() -> void:
	if _guide_root == null:
		return

	_floor_guide.visible = false
	_ceiling_guide.visible = false
	_surface_table_root.visible = false
	_wall_guide_root.visible = false
	_rebuild_wall_guide()

	if _studio_mode != STUDIO_MODE_EDIT or _current_item == null:
		return

	match _current_item.get_primary_mount_kind():
		RoomConstants.MOUNT_WALL:
			_wall_guide_root.visible = _wall_guide_visible
		RoomConstants.MOUNT_CEILING:
			_ceiling_guide.visible = true
		RoomConstants.MOUNT_SURFACE:
			_surface_table_root.visible = true
		_:
			_floor_guide.visible = true

func _rebuild_wall_guide() -> void:
	if _wall_guide_root == null:
		return
	for child in _wall_guide_root.get_children():
		child.queue_free()

	if _current_item == null:
		return

	var wall_alpha = WALL_GUIDE_ALPHA if _wall_guide_visible else WALL_GUIDE_HIDDEN_ALPHA
	var material = _make_guide_material(Color(0.82, 0.93, 1.0, wall_alpha))
	var opening_size = _current_item.get_wall_opening_half_extents()
	var opening_enabled = _current_item.get_primary_mount_kind() == RoomConstants.MOUNT_WALL and (_current_item.requires_wall_opening() or opening_size.length_squared() > 0.0001)
	if not opening_enabled:
		var full_wall = MeshInstance3D.new()
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(WALL_GUIDE_WIDTH, WALL_GUIDE_HEIGHT, WALL_GUIDE_THICKNESS)
		full_wall.mesh = wall_mesh
		full_wall.position = Vector3(0.0, WALL_GUIDE_HEIGHT * 0.5, 0.0)
		full_wall.material_override = material
		full_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_wall_guide_root.add_child(full_wall)
		return

	if opening_size.length_squared() <= 0.0001:
		opening_size = Vector2(0.54, 0.72)

	var opening_center_y = _current_item.position.y + _current_item.get_collision_center_offset().y
	var half_wall_width = WALL_GUIDE_WIDTH * 0.5
	var left_width = maxf(half_wall_width - opening_size.x, 0.0)
	var right_width = left_width
	var bottom_height = maxf(opening_center_y - opening_size.y, 0.0)
	var top_height = maxf(WALL_GUIDE_HEIGHT - (opening_center_y + opening_size.y), 0.0)

	if left_width > 0.02:
		_wall_guide_root.add_child(_make_wall_piece(Vector3(left_width, WALL_GUIDE_HEIGHT, WALL_GUIDE_THICKNESS), Vector3(-(opening_size.x + left_width * 0.5), WALL_GUIDE_HEIGHT * 0.5, 0.0), material))
	if right_width > 0.02:
		_wall_guide_root.add_child(_make_wall_piece(Vector3(right_width, WALL_GUIDE_HEIGHT, WALL_GUIDE_THICKNESS), Vector3(opening_size.x + right_width * 0.5, WALL_GUIDE_HEIGHT * 0.5, 0.0), material))
	if bottom_height > 0.02:
		_wall_guide_root.add_child(_make_wall_piece(Vector3(opening_size.x * 2.0, bottom_height, WALL_GUIDE_THICKNESS), Vector3(0.0, bottom_height * 0.5, 0.0), material))
	if top_height > 0.02:
		_wall_guide_root.add_child(_make_wall_piece(Vector3(opening_size.x * 2.0, top_height, WALL_GUIDE_THICKNESS), Vector3(0.0, opening_center_y + opening_size.y + top_height * 0.5, 0.0), material))

func _make_wall_piece(size_value: Vector3, local_position: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var piece = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size_value
	piece.mesh = mesh
	piece.position = local_position
	piece.material_override = material
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return piece

func _frame_current_item() -> void:
	_orbit_yaw = CAMERA_DEFAULT_YAW
	_orbit_pitch = CAMERA_DEFAULT_PITCH
	if _current_item == null:
		_orbit_distance = 5.6
		return
	var collision_size = _current_item.get_collision_size()
	var max_dimension = maxf(collision_size.x, maxf(collision_size.y, collision_size.z))
	_orbit_distance = clampf(max_dimension * CAMERA_DISTANCE_PADDING + 2.2, CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE)

func _get_camera_target() -> Vector3:
	if _current_item == null:
		return global_position
	return _current_item.global_position + _current_item.get_collision_center_offset()

func _update_camera_transform() -> void:
	if _camera == null:
		return
	var target = _get_camera_target()
	var cos_pitch = cos(_orbit_pitch)
	var offset = Vector3(
		sin(_orbit_yaw) * cos_pitch,
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos_pitch
	) * _orbit_distance
	_camera.global_position = target + offset
	_camera.look_at(target, Vector3.UP)

func _update_overlay_visibility() -> void:
	if _collision_overlay != null:
		_collision_overlay.visible = _studio_mode == STUDIO_MODE_EDIT and _overlay_collision_visible
	if _footprint_overlay != null:
		_footprint_overlay.visible = _studio_mode == STUDIO_MODE_EDIT and _overlay_footprint_visible and _current_item != null and _current_item.get_primary_mount_kind() != RoomConstants.MOUNT_WALL
	if _wall_bounds_overlay != null:
		_wall_bounds_overlay.visible = _studio_mode == STUDIO_MODE_EDIT and _overlay_wall_bounds_visible and _current_item != null and _current_item.get_primary_mount_kind() == RoomConstants.MOUNT_WALL
	if _wall_opening_overlay != null:
		_wall_opening_overlay.visible = _studio_mode == STUDIO_MODE_EDIT and _overlay_wall_opening_visible and _current_item != null and _current_item.get_primary_mount_kind() == RoomConstants.MOUNT_WALL
	if _support_overlay_root != null:
		_support_overlay_root.visible = _studio_mode == STUDIO_MODE_EDIT and _overlay_support_visible

func _clear_gizmo_handles() -> void:
	if _gizmo_root == null:
		return
	for child in _gizmo_root.get_children():
		child.queue_free()

func _refresh_gizmo() -> void:
	_clear_gizmo_handles()
	if _studio_mode != STUDIO_MODE_EDIT or _current_item == null or _gizmo_mode.is_empty():
		return

	var collision_center = _current_item.get_collision_center_offset()
	var collision_size = _current_item.get_collision_size()
	var gizmo_transform = Transform3D(_current_item.global_basis.orthonormalized(), _current_item.to_global(collision_center))
	_gizmo_root.global_transform = gizmo_transform
	_gizmo_root.scale = Vector3.ONE

	match _gizmo_mode:
		GIZMO_MODE_VISUAL_SCALE:
			_spawn_gizmo_arrow("scale", Vector3.UP, Vector3(0.0, collision_size.y * 0.5 + 0.42, 0.0), Color(1.0, 0.84, 0.24, 0.96))
		GIZMO_MODE_VISUAL_LIFT:
			_spawn_gizmo_arrow("lift", Vector3.UP, Vector3(0.0, collision_size.y * 0.5 + 0.42, 0.0), Color(0.48, 1.0, 0.66, 0.96))
		GIZMO_MODE_VISUAL_YAW:
			var ring = PlacementGizmoFactory.make_rotation_ring("yaw", maxf(maxf(collision_size.x, collision_size.z) * 0.55, 0.7), DEBUG_GIZMO_COLLISION_LAYER, {}, {}, {})
			_gizmo_root.add_child(ring)
		GIZMO_MODE_COLLISION_SIZE:
			_spawn_gizmo_arrow("x", Vector3.RIGHT, Vector3(collision_size.x * 0.5 + 0.34, 0.0, 0.0), Color(0.96, 0.38, 0.38, 0.96))
			_spawn_gizmo_arrow("y", Vector3.UP, Vector3(0.0, collision_size.y * 0.5 + 0.34, 0.0), Color(0.44, 0.96, 0.58, 0.96))
			_spawn_gizmo_arrow("z", Vector3.BACK, Vector3(0.0, 0.0, collision_size.z * 0.5 + 0.34), Color(0.4, 0.7, 1.0, 0.96))
		GIZMO_MODE_COLLISION_OFFSET:
			_spawn_gizmo_arrow("x", Vector3.RIGHT, Vector3(0.56, 0.0, 0.0), Color(0.96, 0.38, 0.38, 0.96))
			_spawn_gizmo_arrow("y", Vector3.UP, Vector3(0.0, 0.56, 0.0), Color(0.44, 0.96, 0.58, 0.96))
			_spawn_gizmo_arrow("z", Vector3.BACK, Vector3(0.0, 0.0, 0.56), Color(0.4, 0.7, 1.0, 0.96))
		GIZMO_MODE_FOOTPRINT:
			var footprint_half_extents = _read_spin_box_vector2(_footprint_spin_boxes, 0.0) * 0.5
			_gizmo_root.global_transform = Transform3D(_current_item.global_basis.orthonormalized(), _current_item.to_global(Vector3(0.0, _get_footprint_gizmo_y(), 0.0)))
			_spawn_gizmo_arrow("x", Vector3.RIGHT, Vector3(footprint_half_extents.x + 0.3, 0.0, 0.0), Color(0.96, 0.38, 0.38, 0.96))
			_spawn_gizmo_arrow("z", Vector3.BACK, Vector3(0.0, 0.0, footprint_half_extents.y + 0.3), Color(0.4, 0.7, 1.0, 0.96))
		GIZMO_MODE_WALL_BOUNDS:
			var wall_half_extents = _read_spin_box_vector2(_wall_bounds_spin_boxes, 0.0) * 0.5
			_gizmo_root.global_transform = Transform3D(_current_item.global_basis.orthonormalized(), _current_item.to_global(Vector3(0.0, _current_item.get_collision_center_offset().y, 0.0)))
			_spawn_gizmo_arrow("x", Vector3.RIGHT, Vector3(wall_half_extents.x + 0.3, 0.0, 0.0), Color(0.96, 0.38, 0.38, 0.96))
			_spawn_gizmo_arrow("y", Vector3.UP, Vector3(0.0, wall_half_extents.y + 0.3, 0.0), Color(0.44, 0.96, 0.58, 0.96))
		GIZMO_MODE_WALL_OPENING:
			var opening_half_extents = _read_spin_box_vector2(_wall_opening_spin_boxes, 0.0) * 0.5
			_gizmo_root.global_transform = Transform3D(_current_item.global_basis.orthonormalized(), _current_item.to_global(Vector3(0.0, _current_item.get_collision_center_offset().y, 0.0)))
			_spawn_gizmo_arrow("x", Vector3.RIGHT, Vector3(opening_half_extents.x + 0.3, 0.0, 0.0), Color(0.96, 0.38, 0.38, 0.96))
			_spawn_gizmo_arrow("y", Vector3.UP, Vector3(0.0, opening_half_extents.y + 0.3, 0.0), Color(0.44, 0.96, 0.58, 0.96))

	_update_gizmo_scale()

func _get_footprint_gizmo_y() -> float:
	if _current_item == null:
		return OVERLAY_THICKNESS * 0.5
	match _current_item.get_primary_mount_kind():
		RoomConstants.MOUNT_SURFACE:
			return SURFACE_TABLE_TOP_Y + 0.06
		RoomConstants.MOUNT_CEILING:
			return -OVERLAY_THICKNESS * 0.5
		_:
			return OVERLAY_THICKNESS * 0.5

func _spawn_gizmo_arrow(handle_id: String, axis: Vector3, local_position: Vector3, color_value: Color) -> void:
	var handle_nodes: Dictionary = {}
	var handle_materials: Dictionary = {}
	var handle_base_colors: Dictionary = {}
	var root = PlacementGizmoFactory.make_arrow_gizmo(handle_id, axis, color_value, DEBUG_GIZMO_COLLISION_LAYER, handle_nodes, handle_materials, handle_base_colors)
	root.position = local_position
	_gizmo_root.add_child(root)

func _update_gizmo_scale() -> void:
	if _gizmo_root == null or _gizmo_root.get_child_count() == 0 or _camera == null:
		return
	var camera_distance = _camera.global_position.distance_to(_gizmo_root.global_position)
	var gizmo_scale = clampf(camera_distance * GIZMO_DISTANCE_SCALE, GIZMO_MIN_SCALE, GIZMO_MAX_SCALE)
	_gizmo_root.scale = Vector3.ONE * gizmo_scale

func _pick_gizmo_handle(mouse_position: Vector2) -> String:
	if _camera == null or _gizmo_root.get_child_count() == 0:
		return ""
	var hit = PlacementSurfaceQueries.raycast_from_mouse(get_world_3d().direct_space_state, _camera, mouse_position, DEBUG_GIZMO_COLLISION_LAYER)
	if hit.is_empty():
		return ""
	var collider = hit.get("collider", null) as CollisionObject3D
	if collider == null or not collider.has_meta("handle_id"):
		return ""
	return String(collider.get_meta("handle_id"))

func _begin_gizmo_drag(handle_id: String, mouse_position: Vector2) -> void:
	if handle_id.is_empty():
		return
	_gizmo_drag_active = true
	_gizmo_drag_handle_id = handle_id
	_gizmo_drag_start_mouse = mouse_position
	_gizmo_drag_start_values.clear()
	match _gizmo_mode:
		GIZMO_MODE_VISUAL_SCALE:
			_gizmo_drag_start_values["visual_scale"] = _read_spin_box_vector3(_visual_scale_spin_boxes, TUNING_SCALE_MIN)
		GIZMO_MODE_VISUAL_LIFT:
			_gizmo_drag_start_values["visual_lift"] = _visual_lift_spin_box.value
		GIZMO_MODE_VISUAL_YAW:
			_gizmo_drag_start_values["visual_yaw"] = _visual_yaw_spin_box.value
		GIZMO_MODE_COLLISION_SIZE:
			_gizmo_drag_start_values["collision_size"] = _read_spin_box_vector3(_collision_size_spin_boxes, TUNING_SCALE_MIN)
		GIZMO_MODE_COLLISION_OFFSET:
			_gizmo_drag_start_values["collision_offset"] = _read_spin_box_vector3(_collision_offset_spin_boxes, -TUNING_OFFSET_MAX)
		GIZMO_MODE_FOOTPRINT:
			_gizmo_drag_start_values["footprint"] = _read_spin_box_vector2(_footprint_spin_boxes, 0.0)
		GIZMO_MODE_WALL_BOUNDS:
			_gizmo_drag_start_values["wall_bounds"] = _read_spin_box_vector2(_wall_bounds_spin_boxes, 0.0)
		GIZMO_MODE_WALL_OPENING:
			_gizmo_drag_start_values["wall_opening"] = _read_spin_box_vector2(_wall_opening_spin_boxes, 0.0)
	get_viewport().gui_release_focus()

func _end_gizmo_drag() -> void:
	_gizmo_drag_active = false
	_gizmo_drag_handle_id = ""
	_gizmo_drag_start_values.clear()

func _update_gizmo_drag(mouse_position: Vector2) -> void:
	if not _gizmo_drag_active or _camera == null:
		return

	var delta = mouse_position - _gizmo_drag_start_mouse
	var scaled_delta = delta.length() * 0.01
	if delta.x + delta.y < 0.0:
		scaled_delta *= -1.0

	_syncing_controls = true
	match _gizmo_mode:
		GIZMO_MODE_VISUAL_SCALE:
			var start_scale = _gizmo_drag_start_values.get("visual_scale", Vector3.ONE) as Vector3
			var next_scale = start_scale + Vector3.ONE * scaled_delta
			next_scale.x = clampf(next_scale.x, TUNING_SCALE_MIN, TUNING_SCALE_MAX)
			next_scale.y = clampf(next_scale.y, TUNING_SCALE_MIN, TUNING_SCALE_MAX)
			next_scale.z = clampf(next_scale.z, TUNING_SCALE_MIN, TUNING_SCALE_MAX)
			_set_vector3_spin_boxes(_visual_scale_spin_boxes, next_scale)
		GIZMO_MODE_VISUAL_LIFT:
			var start_lift = float(_gizmo_drag_start_values.get("visual_lift", 0.0))
			_visual_lift_spin_box.value = clampf(start_lift + scaled_delta, -TUNING_OFFSET_MAX, TUNING_OFFSET_MAX)
		GIZMO_MODE_VISUAL_YAW:
			var start_yaw = float(_gizmo_drag_start_values.get("visual_yaw", 0.0))
			_visual_yaw_spin_box.value = clampf(start_yaw + delta.x * 0.35, TUNING_YAW_MIN, TUNING_YAW_MAX)
		GIZMO_MODE_COLLISION_SIZE:
			var start_collision = _gizmo_drag_start_values.get("collision_size", Vector3.ONE) as Vector3
			match _gizmo_drag_handle_id:
				"x":
					_collision_size_spin_boxes[0].value = clampf(start_collision.x + scaled_delta * 2.0, TUNING_SCALE_MIN, TUNING_DIMENSION_MAX)
				"y":
					_collision_size_spin_boxes[1].value = clampf(start_collision.y + scaled_delta * 2.0, TUNING_SCALE_MIN, TUNING_DIMENSION_MAX)
				"z":
					_collision_size_spin_boxes[2].value = clampf(start_collision.z + scaled_delta * 2.0, TUNING_SCALE_MIN, TUNING_DIMENSION_MAX)
		GIZMO_MODE_COLLISION_OFFSET:
			var start_offset = _gizmo_drag_start_values.get("collision_offset", Vector3.ZERO) as Vector3
			match _gizmo_drag_handle_id:
				"x":
					_collision_offset_spin_boxes[0].value = clampf(start_offset.x + scaled_delta, -TUNING_OFFSET_MAX, TUNING_OFFSET_MAX)
				"y":
					_collision_offset_spin_boxes[1].value = clampf(start_offset.y + scaled_delta, -TUNING_OFFSET_MAX, TUNING_OFFSET_MAX)
				"z":
					_collision_offset_spin_boxes[2].value = clampf(start_offset.z + scaled_delta, -TUNING_OFFSET_MAX, TUNING_OFFSET_MAX)
		GIZMO_MODE_FOOTPRINT:
			var start_footprint = _gizmo_drag_start_values.get("footprint", Vector2.ZERO) as Vector2
			match _gizmo_drag_handle_id:
				"x":
					_footprint_spin_boxes[0].value = clampf(start_footprint.x + scaled_delta * 2.0, 0.0, TUNING_DIMENSION_MAX)
				"z":
					_footprint_spin_boxes[1].value = clampf(start_footprint.y + scaled_delta * 2.0, 0.0, TUNING_DIMENSION_MAX)
		GIZMO_MODE_WALL_BOUNDS:
			var start_wall_bounds = _gizmo_drag_start_values.get("wall_bounds", Vector2.ZERO) as Vector2
			match _gizmo_drag_handle_id:
				"x":
					_wall_bounds_spin_boxes[0].value = clampf(start_wall_bounds.x + scaled_delta * 2.0, 0.0, TUNING_DIMENSION_MAX)
				"y":
					_wall_bounds_spin_boxes[1].value = clampf(start_wall_bounds.y + scaled_delta * 2.0, 0.0, TUNING_DIMENSION_MAX)
		GIZMO_MODE_WALL_OPENING:
			var start_wall_opening = _gizmo_drag_start_values.get("wall_opening", Vector2.ZERO) as Vector2
			match _gizmo_drag_handle_id:
				"x":
					_wall_opening_spin_boxes[0].value = clampf(start_wall_opening.x + scaled_delta * 2.0, 0.0, TUNING_DIMENSION_MAX)
				"y":
					_wall_opening_spin_boxes[1].value = clampf(start_wall_opening.y + scaled_delta * 2.0, 0.0, TUNING_DIMENSION_MAX)
	_syncing_controls = false
	_apply_live_preview()

func _is_pointer_over_ui() -> bool:
	var hovered = get_viewport().gui_get_hovered_control()
	while hovered != null and hovered.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		hovered = hovered.get_parent() as Control
	return hovered != null and hovered != _ui_root

func _set_studio_mode(next_mode: String) -> void:
	var resolved_mode = next_mode if next_mode == STUDIO_MODE_EDIT else STUDIO_MODE_PREVIEW
	if _studio_mode == resolved_mode:
		_update_mode_visibility()
		return

	_studio_mode = resolved_mode
	if _studio_mode == STUDIO_MODE_PREVIEW:
		_set_gizmo_mode("")
		_end_gizmo_drag()
	else:
		_item_holder.rotation = Vector3.ZERO
	_update_stage_guides()
	_update_overlay_visibility()
	_refresh_gizmo()
	_update_mode_visibility()
	_update_ui()

func _set_gizmo_mode(mode_name: String) -> void:
	_gizmo_mode = mode_name
	_end_gizmo_drag()
	_refresh_gizmo()
	_update_gizmo_button_styles()

func _update_mode_visibility() -> void:
	if _edit_panel != null:
		_edit_panel.visible = _debug_world_enabled and _studio_mode == STUDIO_MODE_EDIT
	if _edit_mode_button != null:
		_edit_mode_button.visible = _debug_world_enabled and _studio_mode == STUDIO_MODE_PREVIEW
	_relayout_ui()

func _relayout_ui() -> void:
	if _ui_root == null:
		return
	var viewport_size = _get_viewport_size()
	if _header_panel != null:
		_header_panel.position = Vector2((viewport_size.x - HEADER_WIDTH) * 0.5, UI_MARGIN)
	if _previous_item_button != null:
		_previous_item_button.position = Vector2(UI_MARGIN, (viewport_size.y - SIDE_BUTTON_SIZE.y) * 0.5)
	if _next_item_button != null:
		_next_item_button.position = Vector2(viewport_size.x - UI_MARGIN - SIDE_BUTTON_SIZE.x, (viewport_size.y - SIDE_BUTTON_SIZE.y) * 0.5)
	if _edit_mode_button != null:
		_edit_mode_button.position = Vector2((viewport_size.x - EDIT_BUTTON_SIZE.x) * 0.5, viewport_size.y - EDIT_BUTTON_SIZE.y - 26.0)
	if _edit_panel != null:
		_edit_panel.position = Vector2(UI_MARGIN, EDIT_PANEL_TOP)
		_edit_panel.custom_minimum_size = Vector2(EDIT_PANEL_WIDTH, maxf(viewport_size.y - EDIT_PANEL_TOP - EDIT_PANEL_BOTTOM, 420.0))

func _update_ui() -> void:
	_update_header_labels()
	_update_summary()
	_update_status()
	_update_overlay_button_styles()
	_update_gizmo_button_styles()
	_update_control_values_from_item_def()
	_update_button_states()

func _update_header_labels() -> void:
	if _title_label == null or _meta_label == null:
		return
	if _filtered_item_defs.is_empty():
		_title_label.text = "No Items"
		_meta_label.text = "Search returned no active items"
		return
	var display_name = String(_current_item_def.get("display_name", ""))
	var category = String(_current_item_def.get("category", "Miscellaneous"))
	var mount_text = PlacementInventoryCatalog.get_mount_badge_text(_current_item_def)
	_title_label.text = display_name
	_meta_label.text = "%s • %s • %d / %d" % [category, mount_text, _selected_filtered_index + 1, _filtered_item_defs.size()]

func _update_summary() -> void:
	if _edit_summary_label == null:
		return
	if _current_item_def.is_empty():
		_edit_summary_label.text = "No active item."
		return
	var item_id = String(_current_item_def.get("id", ""))
	var category = String(_current_item_def.get("category", "Miscellaneous"))
	var mount_text = PlacementInventoryCatalog.get_mount_badge_text(_current_item_def)
	var source_path = String(_current_item_def.get("source_scene_path", ""))
	var saved_override = PlacementItemProfileOverrideStoreScript.has_override(item_id)
	var support_surfaces = 0
	if _current_item != null:
		support_surfaces = _current_item.get_support_surfaces().size()
	_edit_summary_label.text = "%s\nID: %s\nCategory: %s\nMount: %s\nSaved override: %s\nSource: %s\nSupport surfaces: %d" % [
		String(_current_item_def.get("display_name", item_id)),
		item_id,
		category,
		mount_text,
		"Yes" if saved_override else "No",
		source_path,
		support_surfaces,
	]

func _update_status() -> void:
	if _edit_status_label == null:
		return
	if _current_item_def.is_empty():
		_edit_status_label.text = ""
		return
	_edit_status_label.text = "Unsaved changes are active in the studio preview." if _has_unsaved_changes else "Values match the saved local profile."

func _update_button_states() -> void:
	var has_item = not _current_item_def.is_empty()
	var can_edit = has_item and PlacementInventoryCatalog.uses_imported_scene_factory(_current_item_def)
	if _previous_item_button != null:
		_previous_item_button.disabled = _filtered_item_defs.size() <= 1
	if _next_item_button != null:
		_next_item_button.disabled = _filtered_item_defs.size() <= 1
	if _edit_mode_button != null:
		_edit_mode_button.disabled = not can_edit
	if _save_button != null:
		_save_button.disabled = not can_edit
	if _reset_saved_button != null:
		_reset_saved_button.disabled = not has_item
	if _revert_unsaved_button != null:
		_revert_unsaved_button.disabled = not _has_unsaved_changes

func _update_overlay_button_styles() -> void:
	for key_name in _overlay_buttons.keys():
		var button = _overlay_buttons.get(key_name, null) as Button
		if button == null:
			continue
		var active = false
		match String(key_name):
			"collision":
				active = _overlay_collision_visible
			"footprint":
				active = _overlay_footprint_visible
			"wall_bounds":
				active = _overlay_wall_bounds_visible
			"wall_opening":
				active = _overlay_wall_opening_visible
			"support":
				active = _overlay_support_visible
			"wall_guide":
				active = _wall_guide_visible
		button.set_pressed_no_signal(active)
		_apply_chip_style(button, active)

func _update_gizmo_button_styles() -> void:
	for mode_name in _gizmo_buttons.keys():
		var button = _gizmo_buttons.get(mode_name, null) as Button
		if button == null:
			continue
		var active = String(mode_name) == _gizmo_mode
		button.set_pressed_no_signal(active)
		_apply_chip_style(button, active)

func _apply_action_button_style(button: Button, is_primary: bool, is_danger: bool) -> void:
	if button == null:
		return
	if is_danger:
		PlacementUiStyles.apply_button_style(button, PlacementUiStyles.COLOR_DANGER, PlacementUiStyles.COLOR_DANGER_BORDER, PlacementUiStyles.COLOR_TEXT)
		return
	if is_primary:
		PlacementUiStyles.apply_button_style(button, PlacementUiStyles.COLOR_SUCCESS, PlacementUiStyles.COLOR_SUCCESS_BORDER, PlacementUiStyles.COLOR_TEXT)
		return
	PlacementUiStyles.apply_button_style(button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)

func _apply_chip_style(button: Button, active: bool) -> void:
	if button == null:
		return
	PlacementUiStyles.apply_button_style(
		button,
		PlacementUiStyles.COLOR_ACCENT_DARK if active else PlacementUiStyles.COLOR_PANEL_ALT,
		PlacementUiStyles.COLOR_ACCENT_BRIGHT if active else PlacementUiStyles.COLOR_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)

func _update_control_values_from_item_def() -> void:
	if _syncing_controls:
		return
	_syncing_controls = true

	if _current_item_def.is_empty():
		_syncing_controls = false
		return

	var mount_kind = String(_current_item_def.get("mount_kind", RoomConstants.MOUNT_FLOOR))
	_select_option_button_metadata(_mount_option, mount_kind)
	_set_vector3_spin_boxes(_visual_scale_spin_boxes, _current_item_def.get("visual_scale", Vector3.ONE) as Vector3)
	_visual_lift_spin_box.value = float(_current_item_def.get("visual_y_offset", 0.0))
	_visual_yaw_spin_box.value = rad_to_deg(float(_current_item_def.get("visual_yaw", 0.0)))
	_set_vector3_spin_boxes(_collision_size_spin_boxes, _current_item_def.get("collision_size", Vector3.ONE) as Vector3)
	_set_vector3_spin_boxes(_collision_offset_spin_boxes, _current_item_def.get("collision_center_offset", Vector3.ZERO) as Vector3)
	_set_vector2_spin_boxes(_footprint_spin_boxes, (_current_item_def.get("footprint_half_extents", Vector2.ZERO) as Vector2) * 2.0)
	_set_vector2_spin_boxes(_wall_bounds_spin_boxes, (_current_item_def.get("wall_half_extents", Vector2.ZERO) as Vector2) * 2.0)
	_set_vector2_spin_boxes(_wall_opening_spin_boxes, (_current_item_def.get("wall_opening_half_extents", Vector2.ZERO) as Vector2) * 2.0)
	_can_host_surface_button.button_pressed = bool(_current_item_def.get("can_host_surface_items", false))
	_requires_wall_opening_button.button_pressed = bool(_current_item_def.get("requires_wall_opening", false))

	_syncing_controls = false

func _select_option_button_metadata(option_button: OptionButton, metadata_value: String) -> void:
	if option_button == null:
		return
	for index in range(option_button.item_count):
		if String(option_button.get_item_metadata(index)) == metadata_value:
			option_button.select(index)
			return
	if option_button.item_count > 0:
		option_button.select(0)

func _add_option_button_item(option_button: OptionButton, text_value: String, metadata: Variant) -> void:
	option_button.add_item(text_value)
	option_button.set_item_metadata(option_button.item_count - 1, metadata)

func _set_vector3_spin_boxes(spin_boxes: Array[SpinBox], value: Vector3) -> void:
	if spin_boxes.size() < 3:
		return
	spin_boxes[0].value = value.x
	spin_boxes[1].value = value.y
	spin_boxes[2].value = value.z

func _set_vector2_spin_boxes(spin_boxes: Array[SpinBox], value: Vector2) -> void:
	if spin_boxes.size() < 2:
		return
	spin_boxes[0].value = value.x
	spin_boxes[1].value = value.y

func _read_spin_box_vector3(spin_boxes: Array[SpinBox], minimum_value: float = -INF) -> Vector3:
	if spin_boxes.size() < 3:
		return Vector3.ZERO
	return Vector3(
		maxf(spin_boxes[0].value, minimum_value),
		maxf(spin_boxes[1].value, minimum_value),
		maxf(spin_boxes[2].value, minimum_value)
	)

func _read_spin_box_vector2(spin_boxes: Array[SpinBox], minimum_value: float = 0.0) -> Vector2:
	if spin_boxes.size() < 2:
		return Vector2.ZERO
	return Vector2(
		maxf(spin_boxes[0].value, minimum_value),
		maxf(spin_boxes[1].value, minimum_value)
	)

func _get_selected_mount_kind() -> String:
	if _mount_option == null or _mount_option.selected < 0:
		return RoomConstants.MOUNT_FLOOR
	return String(_mount_option.get_item_metadata(_mount_option.selected))

func _build_selected_override() -> Dictionary:
	var mount_kind = _get_selected_mount_kind()
	var requires_wall_opening = _requires_wall_opening_button.button_pressed and mount_kind == RoomConstants.MOUNT_WALL
	return {
		"visual_scale": _read_spin_box_vector3(_visual_scale_spin_boxes, TUNING_SCALE_MIN),
		"visual_y_offset": _visual_lift_spin_box.value,
		"visual_yaw": deg_to_rad(_visual_yaw_spin_box.value),
		"mount_kind": mount_kind,
		"collision_size": _read_spin_box_vector3(_collision_size_spin_boxes, TUNING_SCALE_MIN),
		"collision_center_offset": _read_spin_box_vector3(_collision_offset_spin_boxes, -TUNING_OFFSET_MAX),
		"footprint_half_extents": _read_spin_box_vector2(_footprint_spin_boxes, 0.0) * 0.5,
		"wall_half_extents": _read_spin_box_vector2(_wall_bounds_spin_boxes, 0.0) * 0.5,
		"wall_opening_half_extents": _read_spin_box_vector2(_wall_opening_spin_boxes, 0.0) * 0.5,
		"can_host_surface_items": _can_host_surface_button.button_pressed,
		"requires_wall_opening": requires_wall_opening,
	}

func _build_preview_item_def(base_item_def: Dictionary) -> Dictionary:
	var preview_item_def = base_item_def.duplicate(true)
	var override_values = _build_selected_override()
	for key_name in override_values.keys():
		preview_item_def[key_name] = override_values[key_name]
	var mount_kind = String(override_values.get("mount_kind", RoomConstants.MOUNT_FLOOR))
	preview_item_def["mount_kind"] = mount_kind
	preview_item_def["mount_kinds"] = [mount_kind]
	preview_item_def["placement_surface_kind"] = RoomConstants.SURFACE_DECOR if mount_kind == RoomConstants.MOUNT_WALL else RoomConstants.FLOOR_SURFACE
	if mount_kind == RoomConstants.MOUNT_WALL:
		preview_item_def["supported_wall_surfaces"] = RoomConstants.WALL_SURFACES
	return preview_item_def

func _apply_live_preview() -> void:
	if _syncing_controls or _current_item_id.is_empty():
		return
	var saved_item_def = PlacementInventoryCatalog.find_item_definition(_all_item_defs, _current_item_id)
	if saved_item_def.is_empty():
		return
	_current_item_def = _build_preview_item_def(saved_item_def)
	_has_unsaved_changes = true
	_rebuild_current_item(_current_item_def, false)

func _discard_unsaved_changes() -> void:
	if not _has_unsaved_changes:
		return
	_refresh_catalog_item_defs()
	_has_unsaved_changes = false
	if not _current_item_id.is_empty():
		_current_item_def = PlacementInventoryCatalog.find_item_definition(_all_item_defs, _current_item_id).duplicate(true)

func _revert_unsaved_changes() -> void:
	if _current_item_id.is_empty():
		return
	_refresh_catalog_item_defs()
	_has_unsaved_changes = false
	var saved_item_def = PlacementInventoryCatalog.find_item_definition(_all_item_defs, _current_item_id)
	if saved_item_def.is_empty():
		return
	_current_item_def = saved_item_def.duplicate(true)
	_rebuild_current_item(_current_item_def, false)

func _save_current_override() -> void:
	if _current_item_id.is_empty():
		return
	PlacementItemProfileOverrideStoreScript.save_override(_current_item_id, _build_selected_override())
	_refresh_catalog_item_defs()
	_apply_search_filter()
	_has_unsaved_changes = false
	if _placement_manager != null:
		_placement_manager.reload_item_catalog_from_source()
	_load_item_by_id(_current_item_id, false)

func _reset_saved_override() -> void:
	if _current_item_id.is_empty():
		return
	PlacementItemProfileOverrideStoreScript.remove_override(_current_item_id)
	_refresh_catalog_item_defs()
	_apply_search_filter()
	_has_unsaved_changes = false
	if _placement_manager != null:
		_placement_manager.reload_item_catalog_from_source()
	_load_item_by_id(_current_item_id, false)

func _on_exit_pressed() -> void:
	set_debug_world_enabled(false)

func _on_previous_item_pressed() -> void:
	if _filtered_item_defs.is_empty():
		return
	var next_index = _selected_filtered_index - 1
	if next_index < 0:
		next_index = _filtered_item_defs.size() - 1
	_load_filtered_index(next_index, true)

func _on_next_item_pressed() -> void:
	if _filtered_item_defs.is_empty():
		return
	var next_index = (_selected_filtered_index + 1) % _filtered_item_defs.size()
	_load_filtered_index(next_index, true)

func _on_edit_mode_pressed() -> void:
	if _current_item_def.is_empty():
		return
	_set_studio_mode(STUDIO_MODE_EDIT)

func _on_back_pressed() -> void:
	_set_studio_mode(STUDIO_MODE_PREVIEW)

func _on_save_pressed() -> void:
	_save_current_override()

func _on_reset_saved_pressed() -> void:
	_reset_saved_override()

func _on_revert_unsaved_pressed() -> void:
	_revert_unsaved_changes()

func _on_search_text_changed(next_text: String) -> void:
	_search_text = next_text
	_apply_search_filter()
	if _filtered_item_defs.is_empty():
		_clear_current_item()
		return
	if not _load_item_by_id(_current_item_id, false):
		_load_filtered_index(0, true)

func _on_overlay_toggle_changed(key_name: String, enabled: bool) -> void:
	match key_name:
		"collision":
			_overlay_collision_visible = enabled
		"footprint":
			_overlay_footprint_visible = enabled
		"wall_bounds":
			_overlay_wall_bounds_visible = enabled
		"wall_opening":
			_overlay_wall_opening_visible = enabled
		"support":
			_overlay_support_visible = enabled
		"wall_guide":
			_wall_guide_visible = enabled
	_update_stage_guides()
	_update_overlay_visibility()
	_update_overlay_button_styles()

func _on_numeric_property_changed(_value: Variant = null) -> void:
	_apply_live_preview()

func _on_boolean_property_changed(_enabled: bool) -> void:
	_apply_live_preview()

func _get_viewport_size() -> Vector2:
	var viewport = get_viewport()
	return viewport.get_visible_rect().size if viewport != null else Vector2(1280.0, 720.0)
