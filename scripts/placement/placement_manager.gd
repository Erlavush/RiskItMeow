@tool
class_name PlacementManager
extends Node3D

signal room_layout_visuals_changed

const GRID_SIZE := 1.0
const UI_SIDE_MARGIN := 16.0
const POPUP_MARGIN := 10.0
const BROWSER_TOGGLE_BUTTON_SIZE := Vector2(176.0, 40.0)
const BROWSER_PANEL_WIDTH_MIN := 292.0
const BROWSER_PANEL_WIDTH_MAX := 360.0
const BROWSER_PANEL_HEIGHT_RATIO := 0.82
const BROWSER_PANEL_HEIGHT_MIN := 420.0
const BROWSER_PANEL_TOP_GAP := 10.0
const BROWSER_ANIMATION_DURATION := 0.18
const BROWSER_GRID_H_SEPARATION := 8.0
const BROWSER_CARD_MIN_WIDTH := 126.0
const GIZMO_RING_RADIUS := 0.6
const ROTATION_SNAP_STEP := PI * 0.5
const GIZMO_COLLISION_LAYER := 1 << 4
const GIZMO_DISTANCE_SCALE := 0.08
const GIZMO_MIN_SCALE := 0.92
const GIZMO_MAX_SCALE := 1.34
const SUPPORT_SURFACE_SNAP_SIZE := 0.25
const SUPPORT_SURFACE_CLEARANCE := 0.01
const DEFAULT_SUPPORT_SURFACE_ID := "top"
const FLOOR_STYLE_COZY_BROWN := 0
const FLOOR_STYLE_CHECKERBOARD := 1
const WALL_SNAP_SIZE := 0.25
const EDITOR_PREVIEW_POLL_SECONDS := 0.6
const EDITOR_MODE_BUILD := "build"
const EDITOR_MODE_EDIT := "edit"
const BROWSER_MODE_INVENTORY := "inventory"
const BROWSER_MODE_SHOP := "shop"
const PLACEMENT_SESSION_NONE := ""
const PLACEMENT_SESSION_NEW := "new"
const PLACEMENT_SESSION_EDIT := "edit"
const PLACEMENT_SESSION_DUPLICATE := "duplicate"

const GridOverlayShader := preload("res://shaders/grid_overlay.gdshader")

var _inventory_item_defs: Array[Dictionary] = PlacementInventoryCatalog.build_item_defs()

@export var room_shell_path: NodePath
@export var room_camera_controller_path: NodePath
@export var player_path: NodePath

var _item_stock: Dictionary = {}
var _item_owned_totals: Dictionary = {}
var _placed_item_counts: Dictionary = {}
var _shop_categories: Array[String] = []
var _manual_grid_visible := false
var _editor_mode := EDITOR_MODE_BUILD
var _browser_mode := BROWSER_MODE_INVENTORY
var _browser_open := false
var _browser_search_text := ""
var _selected_inventory_category := ""
var _selected_shop_category := ""
var _selected_mount_filter := ""
var _placement_active := false
var _placement_valid := false
var _placement_issue_code := ""
var _placement_issue_text := ""
var _hover_target := ""
var _drag_mode := ""
var _drag_start_position := Vector3.ZERO
var _drag_start_rotation_y := 0.0
var _drag_rotation_start_angle := 0.0
var _active_item_id := ""
var _active_surface_name := RoomConstants.FLOOR_SURFACE
var _placement_session := PLACEMENT_SESSION_NONE
var _editing_original_transform := Transform3D.IDENTITY
var _editing_original_local_transform := Transform3D.IDENTITY
var _editing_original_parent: Node
var _editing_original_surface_name := RoomConstants.FLOOR_SURFACE
var _editing_original_host_surface_id := DEFAULT_SUPPORT_SURFACE_ID
var _drag_start_basis := Basis.IDENTITY
var _next_placeable_instance_serial := 1

var _room_shell: RoomShell
var _room_camera_controller: Node
var _player: Node
var _placed_items_root: Node3D
var _grid_overlay: MeshInstance3D
var _gizmo_root: Node3D
var _preview_item: SimpleWoodChair
var _active_support_host: SimpleWoodChair
var _active_support_surface_id := DEFAULT_SUPPORT_SURFACE_ID
var _placement_query_shape := BoxShape3D.new()
var _gizmo_handle_nodes := {}
var _gizmo_handle_materials := {}
var _gizmo_handle_base_colors := {}

var _ui_layer: CanvasLayer
var _ui_root: Control
var _browser_toggle_button: Button
var _inventory_panel: PanelContainer
var _mode_buttons: Dictionary = {}
var _browser_mode_buttons: Dictionary = {}
var _shop_category_buttons: Dictionary = {}
var _mount_filter_buttons: Dictionary = {}
var _floor_style_buttons: Dictionary = {}
var _panel_title_label: Label
var _mode_label: Label
var _browser_section_label: Label
var _status_label: Label
var _floor_style_label: Label
var _browser_search_input: LineEdit
var _mount_filter_option: OptionButton
var _category_filter_option: OptionButton
var _browser_scroll: ScrollContainer
var _browser_grid: GridContainer
var _shop_category_scroll: ScrollContainer
var _shop_category_flow: HFlowContainer
var _mount_filter_flow: HFlowContainer
var _tools_toggle_button: Button
var _tools_section: VBoxContainer
var _status_shell: PanelContainer
var _grid_toggle_button: Button
var _save_button: Button
var _load_button: Button
var _clear_room_button: Button
var _popup_panel: PanelContainer
var _popup_status_label: Label
var _popup_hint_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _duplicate_button: Button
var _delete_button: Button
var _popup_edit_row: HBoxContainer
var _editor_preview_poll_time := 0.0
var _editor_preview_layout_signature := ""
var _editor_default_floor_style := FLOOR_STYLE_COZY_BROWN
var _wall_openings_signature := ""
var _popup_visual_signature := ""
var _browser_panel_tween: Tween
var _debug_world_active := false
var _wall_surface_cutaway_states: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
}
var _ceiling_surface_cutaway := false

func _ready() -> void:
	_room_shell = get_node_or_null(room_shell_path) as RoomShell
	_room_camera_controller = get_node_or_null(room_camera_controller_path)
	_player = get_node_or_null(player_path)
	_initialize_inventory_state()

	_placed_items_root = get_node_or_null("PlacedItems") as Node3D
	if _placed_items_root == null:
		_placed_items_root = Node3D.new()
		_placed_items_root.name = "PlacedItems"
		add_child(_placed_items_root)

	if Engine.is_editor_hint():
		_editor_default_floor_style = _get_current_floor_style()
		_load_room_layout_on_startup()
		set_process(true)
		return

	_build_grid_overlay()
	_build_gizmo()
	_build_ui()
	_cleanup_stray_placeable_artifacts()
	_sync_player_with_room()
	_load_room_layout_on_startup()
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()
	_update_floor_style_ui()

func _initialize_inventory_state() -> void:
	_item_stock.clear()
	_item_owned_totals.clear()
	_placed_item_counts.clear()
	_shop_categories = PlacementInventoryCatalog.build_category_names(_inventory_item_defs)
	_selected_shop_category = ""
	_selected_inventory_category = ""
	for item_def in _inventory_item_defs:
		var item_id: String = String(item_def.get("id", ""))
		var initial_owned := PlacementInventoryCatalog.get_initial_owned(item_def)
		_item_stock[item_id] = initial_owned
		_item_owned_totals[item_id] = initial_owned
		_placed_item_counts[item_id] = 0

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_process_editor_preview(_delta)
		return

	if not _placement_active or _preview_item == null:
		_popup_panel.visible = false
		_gizmo_root.visible = false
		return

	if _drag_mode == "":
		_hover_target = _pick_interaction_target(get_viewport().get_mouse_position())
	else:
		_hover_target = _drag_mode

	if _preview_item != null:
		_preview_item.set_hovered(_hover_target == "move" or _drag_mode == "move")

	_update_gizmo_hover_state()
	_update_popup_position()
	_update_gizmo_transform()

func _input(event: InputEvent) -> void:
	if not _placement_active or _preview_item == null or event == null:
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
	if event == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var global_key_event := event as InputEventKey
		if _handle_runtime_shortcuts(global_key_event):
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if _is_edit_mode() and not _placement_active and mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed and mouse_button.double_click:
			if _is_pointer_over_placement_ui():
				return

			var picked_item := _pick_placeable_item(mouse_button.position)
			if picked_item != null:
				_begin_edit_session(picked_item)
				get_viewport().set_input_as_handled()
			return

	if not _placement_active:
		if event is InputEventKey and event.pressed and not event.echo:
			var idle_key_event := event as InputEventKey
			if idle_key_event.keycode == KEY_ESCAPE and _browser_open:
				_set_browser_open(false)
				get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_on_confirm_button_pressed()
				get_viewport().set_input_as_handled()
			KEY_Q:
				if _can_rotate_preview():
					_rotate_preview(-1)
					get_viewport().set_input_as_handled()
			KEY_E, KEY_R:
				if _can_rotate_preview():
					_rotate_preview(1)
					get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_cancel_current_placement()
				get_viewport().set_input_as_handled()

func _handle_runtime_shortcuts(key_event: InputEventKey) -> bool:
	if key_event == null:
		return false
	if _debug_world_active:
		return false

	match key_event.keycode:
		KEY_B:
			_activate_browser_shortcut(EDITOR_MODE_BUILD, BROWSER_MODE_INVENTORY)
			return true
		KEY_N:
			_activate_browser_shortcut(EDITOR_MODE_BUILD, BROWSER_MODE_SHOP)
			return true
		_:
			return false

func blocks_room_camera_input(event: InputEvent) -> bool:
	if event == null or _debug_world_active:
		return false

	if _placement_active:
		if _drag_mode != "":
			if event is InputEventMouseButton:
				var drag_mouse_button := event as InputEventMouseButton
				return drag_mouse_button.button_index == MOUSE_BUTTON_LEFT
			return event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

		if event is InputEventMouseButton:
			var mouse_button := event as InputEventMouseButton
			return mouse_button.button_index == MOUSE_BUTTON_LEFT \
				and mouse_button.pressed \
				and _has_camera_conflicting_placement_target(mouse_button.position)
		return false

	if _is_edit_mode() and not _placement_active and event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return mouse_button.button_index == MOUSE_BUTTON_LEFT \
			and mouse_button.pressed \
			and mouse_button.double_click \
			and not _is_pointer_over_placement_ui()

	return false

func _activate_browser_shortcut(next_editor_mode: String, next_browser_mode: String) -> void:
	_cancel_current_placement()
	_editor_mode = next_editor_mode
	_browser_mode = next_browser_mode
	_set_browser_open(true)
	_update_inventory_ui()
	_update_status_text()
	_update_popup_visuals()
	_update_grid_visibility()

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

	_gizmo_root.add_child(
		PlacementGizmoFactory.make_arrow_gizmo(
			"axis_x",
			Vector3.RIGHT,
			Color(0.96, 0.29, 0.24, 1.0),
			GIZMO_COLLISION_LAYER,
			_gizmo_handle_nodes,
			_gizmo_handle_materials,
			_gizmo_handle_base_colors
		)
	)
	_gizmo_root.add_child(
		PlacementGizmoFactory.make_arrow_gizmo(
			"axis_z",
			Vector3.BACK,
			Color(0.28, 0.62, 1.0, 1.0),
			GIZMO_COLLISION_LAYER,
			_gizmo_handle_nodes,
			_gizmo_handle_materials,
			_gizmo_handle_base_colors
		)
	)
	_gizmo_root.add_child(
		PlacementGizmoFactory.make_rotation_ring(
			"rotate",
			GIZMO_RING_RADIUS,
			GIZMO_COLLISION_LAYER,
			_gizmo_handle_nodes,
			_gizmo_handle_materials,
			_gizmo_handle_base_colors
		)
	)

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "PlacementUi"
	add_child(_ui_layer)

	_ui_root = Control.new()
	_ui_root.name = "Root"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_ui_root)

	_browser_toggle_button = Button.new()
	_browser_toggle_button.name = "BuildBrowserToggle"
	_browser_toggle_button.toggle_mode = true
	_browser_toggle_button.anchor_left = 0.0
	_browser_toggle_button.anchor_right = 0.0
	_browser_toggle_button.offset_left = UI_SIDE_MARGIN
	_browser_toggle_button.offset_right = UI_SIDE_MARGIN + BROWSER_TOGGLE_BUTTON_SIZE.x
	_browser_toggle_button.offset_top = 60.0
	_browser_toggle_button.offset_bottom = 60.0 + BROWSER_TOGGLE_BUTTON_SIZE.y
	_browser_toggle_button.pressed.connect(_on_browser_toggle_button_pressed)
	_ui_root.add_child(_browser_toggle_button)

	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_inventory_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_inventory_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	_panel_title_label = Label.new()
	_panel_title_label.text = "Build Browser"
	_panel_title_label.add_theme_font_size_override("font_size", 18)
	PlacementUiStyles.apply_label_color(_panel_title_label, PlacementUiStyles.COLOR_TEXT)
	layout.add_child(_panel_title_label)

	_mode_label = null

	var mode_button_row := HBoxContainer.new()
	mode_button_row.add_theme_constant_override("separation", 6)
	layout.add_child(mode_button_row)

	_add_mode_button(mode_button_row, "Build", EDITOR_MODE_BUILD)
	_add_mode_button(mode_button_row, "Edit", EDITOR_MODE_EDIT)

	var browser_mode_row := HBoxContainer.new()
	browser_mode_row.add_theme_constant_override("separation", 6)
	layout.add_child(browser_mode_row)

	_add_browser_mode_button(browser_mode_row, "Inventory", BROWSER_MODE_INVENTORY)
	_add_browser_mode_button(browser_mode_row, "Shop", BROWSER_MODE_SHOP)

	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 6)
	layout.add_child(search_row)

	_browser_search_input = LineEdit.new()
	_browser_search_input.placeholder_text = "Search items..."
	_browser_search_input.clear_button_enabled = true
	_browser_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browser_search_input.text_changed.connect(_on_browser_search_text_changed)
	PlacementUiStyles.apply_line_edit_style(_browser_search_input)
	search_row.add_child(_browser_search_input)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	layout.add_child(filter_row)

	_mount_filter_option = OptionButton.new()
	_mount_filter_option.custom_minimum_size = Vector2(0.0, 34.0)
	_mount_filter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mount_filter_option.item_selected.connect(_on_mount_filter_option_selected)
	filter_row.add_child(_mount_filter_option)

	_browser_section_label = Label.new()
	_browser_section_label.text = "Browse Items"
	_browser_section_label.add_theme_font_size_override("font_size", 11)
	PlacementUiStyles.apply_label_color(_browser_section_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	layout.add_child(_browser_section_label)

	_category_filter_option = OptionButton.new()
	_category_filter_option.custom_minimum_size = Vector2(0.0, 34.0)
	_category_filter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_filter_option.item_selected.connect(_on_category_filter_option_selected)
	filter_row.add_child(_category_filter_option)

	_browser_scroll = ScrollContainer.new()
	_browser_scroll.custom_minimum_size = Vector2(0.0, 140.0)
	_browser_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browser_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_browser_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_browser_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(_browser_scroll)

	_browser_grid = GridContainer.new()
	_browser_grid.columns = 2
	_browser_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browser_grid.add_theme_constant_override("h_separation", BROWSER_GRID_H_SEPARATION)
	_browser_grid.add_theme_constant_override("v_separation", 12)
	_browser_scroll.add_child(_browser_grid)

	_status_shell = PanelContainer.new()
	PlacementUiStyles.apply_panel_style(_status_shell, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, 1, 14, 4, 0.12)
	_status_shell.visible = false
	layout.add_child(_status_shell)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 10)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_right", 10)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	_status_shell.add_child(status_margin)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0.0, 40.0)
	_status_label.add_theme_font_size_override("font_size", 10)
	PlacementUiStyles.apply_label_color(_status_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	status_margin.add_child(_status_label)

	_tools_toggle_button = Button.new()
	_tools_toggle_button.toggle_mode = true
	_tools_toggle_button.text = "More Tools"
	_tools_toggle_button.pressed.connect(_on_tools_toggle_pressed)
	layout.add_child(_tools_toggle_button)

	_tools_section = VBoxContainer.new()
	_tools_section.visible = false
	_tools_section.add_theme_constant_override("separation", 8)
	layout.add_child(_tools_section)

	_floor_style_label = Label.new()
	_floor_style_label.text = "Floor Finish"
	_floor_style_label.add_theme_font_size_override("font_size", 11)
	PlacementUiStyles.apply_label_color(_floor_style_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	_tools_section.add_child(_floor_style_label)

	var floor_button_row := HBoxContainer.new()
	floor_button_row.add_theme_constant_override("separation", 8)
	_tools_section.add_child(floor_button_row)

	_add_floor_style_button(floor_button_row, "Brown Mat", FLOOR_STYLE_COZY_BROWN)
	_add_floor_style_button(floor_button_row, "Checkerboard", FLOOR_STYLE_CHECKERBOARD)

	_grid_toggle_button = Button.new()
	_grid_toggle_button.custom_minimum_size = Vector2(0.0, 36.0)
	_grid_toggle_button.pressed.connect(_on_grid_toggle_button_pressed)
	_tools_section.add_child(_grid_toggle_button)

	var persistence_row := HBoxContainer.new()
	persistence_row.add_theme_constant_override("separation", 8)
	_tools_section.add_child(persistence_row)

	_save_button = Button.new()
	_save_button.text = "Save"
	_save_button.custom_minimum_size = Vector2(80.0, 34.0)
	_save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_button.pressed.connect(_on_save_button_pressed)
	persistence_row.add_child(_save_button)

	_load_button = Button.new()
	_load_button.text = "Load"
	_load_button.custom_minimum_size = Vector2(80.0, 34.0)
	_load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_load_button.pressed.connect(_on_load_button_pressed)
	persistence_row.add_child(_load_button)

	_clear_room_button = Button.new()
	_clear_room_button.text = "Clear Room"
	_clear_room_button.custom_minimum_size = Vector2(96.0, 34.0)
	_clear_room_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear_room_button.pressed.connect(_on_clear_room_button_pressed)
	persistence_row.add_child(_clear_room_button)

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

	_popup_edit_row = HBoxContainer.new()
	_popup_edit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_popup_edit_row.add_theme_constant_override("separation", 6)
	popup_layout.add_child(_popup_edit_row)

	_duplicate_button = Button.new()
	_duplicate_button.text = "Duplicate"
	_duplicate_button.custom_minimum_size = Vector2(86.0, 32.0)
	_duplicate_button.add_theme_font_size_override("font_size", 14)
	_duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	_popup_edit_row.add_child(_duplicate_button)

	_delete_button = Button.new()
	_delete_button.text = "Delete"
	_delete_button.custom_minimum_size = Vector2(72.0, 32.0)
	_delete_button.add_theme_font_size_override("font_size", 14)
	_delete_button.pressed.connect(_on_delete_button_pressed)
	_popup_edit_row.add_child(_delete_button)

	_popup_hint_label = Label.new()
	_popup_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_hint_label.add_theme_font_size_override("font_size", 11)
	popup_layout.add_child(_popup_hint_label)

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	_rebuild_shop_category_tabs()
	_rebuild_item_browser()
	_update_mode_ui()
	_update_browser_mode_ui()
	_update_browser_toggle_button_visual()
	_update_popup_visuals()
	_update_floor_style_ui()
	_update_browser_layout_metrics(false)
	_set_browser_open(false, false)

func _add_mode_button(parent: HBoxContainer, title_text: String, mode_id: String) -> void:
	var button := Button.new()
	button.text = title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(116.0, 32.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_mode_button_pressed.bind(mode_id))
	parent.add_child(button)
	_mode_buttons[mode_id] = button

func _add_browser_mode_button(parent: HBoxContainer, title_text: String, mode_id: String) -> void:
	var button := Button.new()
	button.text = title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(116.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_browser_mode_button_pressed.bind(mode_id))
	parent.add_child(button)
	_browser_mode_buttons[mode_id] = button

func _add_mount_filter_button(parent: HFlowContainer, title_text: String, mount_kind: String) -> void:
	var button := Button.new()
	button.text = title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(72.0, 30.0)
	button.pressed.connect(_on_mount_filter_button_pressed.bind(mount_kind))
	parent.add_child(button)
	_mount_filter_buttons[mount_kind] = button

func _rebuild_filter_options() -> void:
	if _mount_filter_option != null:
		_mount_filter_option.clear()
		_add_option_button_item(_mount_filter_option, "Type: All", "")
		_add_option_button_item(_mount_filter_option, "Type: Floor", RoomConstants.MOUNT_FLOOR)
		_add_option_button_item(_mount_filter_option, "Type: Wall", RoomConstants.MOUNT_WALL)
		_add_option_button_item(_mount_filter_option, "Type: Ceiling", RoomConstants.MOUNT_CEILING)
		_add_option_button_item(_mount_filter_option, "Type: Surface", RoomConstants.MOUNT_SURFACE)

	if _category_filter_option != null:
		_category_filter_option.clear()
		_add_option_button_item(_category_filter_option, "Category: All", "")
		for category_name in _shop_categories:
			_add_option_button_item(_category_filter_option, category_name, category_name)

func _add_option_button_item(option_button: OptionButton, text_value: String, metadata: Variant) -> void:
	if option_button == null:
		return
	option_button.add_item(text_value)
	option_button.set_item_metadata(option_button.item_count - 1, metadata)

func _select_option_button_value(option_button: OptionButton, metadata_value: String) -> void:
	if option_button == null:
		return
	for option_index in range(option_button.item_count):
		if String(option_button.get_item_metadata(option_index)) == metadata_value:
			option_button.select(option_index)
			return
	if option_button.item_count > 0:
		option_button.select(0)

func _on_viewport_size_changed() -> void:
	_update_browser_layout_metrics(false)

func _on_browser_toggle_button_pressed() -> void:
	_set_browser_open(_browser_toggle_button.button_pressed)

func _on_browser_search_text_changed(new_text: String) -> void:
	_browser_search_text = new_text.strip_edges()
	_update_inventory_ui()

func _on_mount_filter_option_selected(index: int) -> void:
	if _placement_active or _mount_filter_option == null:
		return
	_selected_mount_filter = String(_mount_filter_option.get_item_metadata(index))
	_update_inventory_ui()

func _on_category_filter_option_selected(index: int) -> void:
	if _placement_active or _category_filter_option == null:
		return
	var selected_category := String(_category_filter_option.get_item_metadata(index))
	if _browser_mode == BROWSER_MODE_SHOP:
		_selected_shop_category = selected_category
	else:
		_selected_inventory_category = selected_category
	_update_inventory_ui()

func _on_mount_filter_button_pressed(mount_kind: String) -> void:
	if _placement_active:
		return
	if mount_kind == _selected_mount_filter:
		return
	_selected_mount_filter = mount_kind
	_update_browser_mode_ui()
	_update_inventory_ui()

func _on_tools_toggle_pressed() -> void:
	if _tools_section != null:
		_tools_section.visible = _tools_toggle_button.button_pressed
	_update_section_toggle_ui()

func _set_browser_open(is_open: bool, animate: bool = true) -> void:
	_browser_open = is_open
	_update_browser_toggle_button_visual()
	if _inventory_panel == null:
		return

	var top_margin := _get_browser_top_margin(get_viewport().get_visible_rect().size)
	var target_position := Vector2(UI_SIDE_MARGIN, top_margin + BROWSER_TOGGLE_BUTTON_SIZE.y + BROWSER_PANEL_TOP_GAP)
	if not _browser_open:
		target_position.x = -_inventory_panel.size.x - 24.0

	if _browser_panel_tween != null and _browser_panel_tween.is_running():
		_browser_panel_tween.kill()

	if not animate:
		_inventory_panel.position = target_position
		_inventory_panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if _browser_open else 0.0)
		return

	_browser_panel_tween = create_tween()
	_browser_panel_tween.set_trans(Tween.TRANS_QUAD)
	_browser_panel_tween.set_ease(Tween.EASE_OUT)
	_browser_panel_tween.parallel().tween_property(_inventory_panel, "position", target_position, BROWSER_ANIMATION_DURATION)
	_browser_panel_tween.parallel().tween_property(_inventory_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0 if _browser_open else 0.0), BROWSER_ANIMATION_DURATION * 0.9)

func _get_browser_top_margin(viewport_size: Vector2) -> float:
	return clampf(viewport_size.y * 0.09, 56.0, 72.0)

func _update_browser_layout_metrics(animate: bool = false) -> void:
	if _inventory_panel == null or _browser_toggle_button == null or _ui_root == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var top_margin := _get_browser_top_margin(viewport_size)
	_browser_toggle_button.offset_left = UI_SIDE_MARGIN
	_browser_toggle_button.offset_right = UI_SIDE_MARGIN + BROWSER_TOGGLE_BUTTON_SIZE.x
	_browser_toggle_button.offset_top = top_margin
	_browser_toggle_button.offset_bottom = top_margin + BROWSER_TOGGLE_BUTTON_SIZE.y
	var available_width := maxf(252.0, viewport_size.x - (UI_SIDE_MARGIN * 2.0) - 24.0)
	var panel_width := minf(clampf(viewport_size.x * 0.29, BROWSER_PANEL_WIDTH_MIN, BROWSER_PANEL_WIDTH_MAX), available_width)
	var available_height := maxf(260.0, viewport_size.y - top_margin - BROWSER_TOGGLE_BUTTON_SIZE.y - 22.0)
	var panel_height := minf(maxf(viewport_size.y * BROWSER_PANEL_HEIGHT_RATIO, BROWSER_PANEL_HEIGHT_MIN), available_height)
	_inventory_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	_inventory_panel.size = Vector2(panel_width, panel_height)
	if _browser_scroll != null:
		_browser_scroll.custom_minimum_size = Vector2(0.0, clampf(panel_height * 0.34, 120.0, 220.0))
	var browser_content_width := panel_width - 24.0
	var two_column_width := (BROWSER_CARD_MIN_WIDTH * 2.0) + BROWSER_GRID_H_SEPARATION + 8.0
	var panel_position := Vector2(UI_SIDE_MARGIN, top_margin + BROWSER_TOGGLE_BUTTON_SIZE.y + BROWSER_PANEL_TOP_GAP)
	if not _browser_open:
		panel_position.x = -panel_width - 24.0
	_inventory_panel.position = panel_position
	_browser_grid.columns = 2 if browser_content_width >= two_column_width else 1
	if animate:
		_set_browser_open(_browser_open, true)

func _update_browser_toggle_button_visual() -> void:
	if _browser_toggle_button == null:
		return
	_browser_toggle_button.button_pressed = _browser_open
	_browser_toggle_button.text = "Hide Build Browser" if _browser_open else "Open Build Browser"
	_browser_toggle_button.tooltip_text = "Show or hide the build browser"
	PlacementUiStyles.apply_button_style(
		_browser_toggle_button,
		PlacementUiStyles.COLOR_ACCENT_DARK if not _browser_open else PlacementUiStyles.COLOR_ACCENT,
		PlacementUiStyles.COLOR_BORDER if not _browser_open else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
		PlacementUiStyles.COLOR_TEXT
	)

func _update_section_toggle_ui() -> void:
	if _tools_toggle_button != null:
		_tools_toggle_button.text = "More Tools %s" % ("[-]" if _tools_toggle_button.button_pressed else "[+]")
		PlacementUiStyles.apply_button_style(
			_tools_toggle_button,
			PlacementUiStyles.COLOR_PANEL_ALT if _tools_toggle_button.button_pressed else PlacementUiStyles.COLOR_PANEL_SOFT,
			PlacementUiStyles.COLOR_BORDER_STRONG if _tools_toggle_button.button_pressed else PlacementUiStyles.COLOR_BORDER_SOFT,
			PlacementUiStyles.COLOR_TEXT
		)

func _get_selected_browser_category() -> String:
	return _selected_shop_category if _browser_mode == BROWSER_MODE_SHOP else _selected_inventory_category

func _rebuild_shop_category_tabs() -> void:
	_rebuild_filter_options()

func _rebuild_item_browser() -> void:
	if _browser_grid == null:
		return

	for child in _browser_grid.get_children():
		_browser_grid.remove_child(child)
		child.queue_free()

	var visible_item_defs := _get_visible_browser_item_defs()
	if visible_item_defs.is_empty():
		var empty_state := PanelContainer.new()
		PlacementUiStyles.apply_panel_style(empty_state, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, 1, 14, 4, 0.12)
		empty_state.custom_minimum_size = Vector2(0.0, 108.0)
		_browser_grid.add_child(empty_state)

		var empty_margin := MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 12)
		empty_margin.add_theme_constant_override("margin_top", 12)
		empty_margin.add_theme_constant_override("margin_right", 12)
		empty_margin.add_theme_constant_override("margin_bottom", 12)
		empty_state.add_child(empty_margin)

		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.text = "No items match the current search or filters."
		PlacementUiStyles.apply_label_color(empty_label, PlacementUiStyles.COLOR_TEXT_MUTED)
		empty_margin.add_child(empty_label)
		return

	var item_factory := Callable(self, "_create_item_instance_from_definition")
	for item_def in visible_item_defs:
		var item_id := String(item_def.get("id", ""))
		var card := PlacementBrowserCard.new()
		card.configure(
			item_def,
			_browser_mode,
			int(_item_stock.get(item_id, 0)),
			int(_item_owned_totals.get(item_id, 0)),
			item_factory
		)
		card.place_requested.connect(_on_inventory_item_button_pressed)
		card.buy_requested.connect(_on_shop_buy_requested)
		_browser_grid.add_child(card)

func _get_visible_browser_item_defs() -> Array[Dictionary]:
	var visible_items: Array[Dictionary] = []
	var selected_category := _get_selected_browser_category()
	var search_filter := _browser_search_text.to_lower()
	for item_def in _inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		if _browser_mode == BROWSER_MODE_INVENTORY:
			if int(_item_owned_totals.get(item_id, 0)) <= 0:
				continue

		if not selected_category.is_empty() and String(item_def.get("category", "")) != selected_category:
			continue
		if not _selected_mount_filter.is_empty() and PlacementInventoryCatalog.get_primary_mount_kind(item_def) != _selected_mount_filter:
			continue
		if not search_filter.is_empty():
			var display_name := String(item_def.get("display_name", item_id)).to_lower()
			var category_name := String(item_def.get("category", "")).to_lower()
			var badge_text := PlacementInventoryCatalog.get_mount_badge_text(item_def).to_lower()
			if not display_name.contains(search_filter) and not category_name.contains(search_filter) and not badge_text.contains(search_filter):
				continue
		visible_items.append(item_def)
	return visible_items

func _add_floor_style_button(parent: HBoxContainer, title_text: String, style_id: int) -> void:
	var button := Button.new()
	button.text = title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(126.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_floor_style_button_pressed.bind(style_id))
	parent.add_child(button)
	_floor_style_buttons[style_id] = button

func _sync_player_with_room() -> void:
	if _room_shell == null or _player == null:
		return

	if _player.has_method("set_room_bounds_half_extents"):
		_player.call("set_room_bounds_half_extents", _room_shell.get_walkable_half_extents())

	if _player.has_method("set_floor_y"):
		_player.call("set_floor_y", _room_shell.get_floor_y())

func _get_item_definition(item_id: String) -> Dictionary:
	return PlacementInventoryCatalog.find_item_definition(_inventory_item_defs, item_id)

func _get_item_script(item_def: Dictionary) -> Script:
	return PlacementInventoryCatalog.get_item_script(item_def)

func _get_item_display_name(item_id: String) -> String:
	return PlacementInventoryCatalog.get_item_display_name(_inventory_item_defs, item_id)

func _get_active_item_display_name() -> String:
	return _get_item_display_name(_active_item_id if not _active_item_id.is_empty() else "item")

func _is_wall_placeable(item: SimpleWoodChair) -> bool:
	return PlacementSurfaceQueries.is_wall_placeable(item)

func _is_ceiling_placeable(item: SimpleWoodChair) -> bool:
	return PlacementSurfaceQueries.is_ceiling_placeable(item)

func _is_support_surface_placeable(item: SimpleWoodChair) -> bool:
	return PlacementSurfaceQueries.is_support_surface_placeable(item)

func _active_preview_is_wall_placeable() -> bool:
	return _is_wall_placeable(_preview_item)

func _active_preview_is_ceiling_placeable() -> bool:
	return _is_ceiling_placeable(_preview_item)

func _active_preview_is_support_surface_placeable() -> bool:
	return _is_support_surface_placeable(_preview_item)

func _can_rotate_preview() -> bool:
	return _preview_item != null and _preview_item.supports_rotation()

func _is_edit_mode() -> bool:
	return _editor_mode == EDITOR_MODE_EDIT

func _is_edit_session() -> bool:
	return _placement_session == PLACEMENT_SESSION_EDIT

func _is_stock_consuming_session() -> bool:
	return _placement_session == PLACEMENT_SESSION_NEW or _placement_session == PLACEMENT_SESSION_DUPLICATE

func _has_any_stock() -> bool:
	return PlacementInventoryCatalog.has_any_stock(_inventory_item_defs, _item_stock)

func _get_current_floor_style() -> int:
	if _room_shell != null and _room_shell.has_method("get_floor_style"):
		return int(_room_shell.call("get_floor_style"))
	return FLOOR_STYLE_COZY_BROWN

func _save_room_layout() -> bool:
	var layout := PlacementRoomLayoutStore.serialize_layout(
		_placed_items_root,
		Callable(self, "_resolve_item_id_for_placeable"),
		Callable(self, "_get_placeable_instance_id"),
		_get_current_floor_style(),
		_item_owned_totals
	)
	return PlacementRoomLayoutStore.save_layout(layout)

func _load_room_layout_data() -> Dictionary:
	return PlacementRoomLayoutStore.load_layout_data()

func _build_default_owned_stock() -> Dictionary:
	var defaults: Dictionary = {}
	for item_def in _inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		defaults[item_id] = PlacementInventoryCatalog.get_initial_owned(item_def)
	return defaults

func _build_owned_stock_from_layout(layout: Dictionary) -> Dictionary:
	var owned_stock := _build_default_owned_stock()
	var loaded_owned_stock := PlacementRoomLayoutStore.deserialize_owned_stock(layout.get("owned_stock", {}))
	for item_id in loaded_owned_stock.keys():
		owned_stock[String(item_id)] = int(loaded_owned_stock[item_id])

	var raw_items: Variant = layout.get("items", [])
	if raw_items is Array:
		var placed_counts: Dictionary = {}
		for raw_item in raw_items:
			if typeof(raw_item) != TYPE_DICTIONARY:
				continue
			var item_entry := raw_item as Dictionary
			var item_id := String(item_entry.get("item_id", ""))
			if item_id.is_empty():
				continue
			placed_counts[item_id] = int(placed_counts.get(item_id, 0)) + 1
		for item_id in placed_counts.keys():
			owned_stock[item_id] = maxi(int(owned_stock.get(item_id, 0)), int(placed_counts[item_id]))

	return owned_stock

func _apply_owned_stock_state(owned_stock: Dictionary) -> void:
	_item_stock.clear()
	_item_owned_totals.clear()
	for item_def in _inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		var owned_total := maxi(0, int(owned_stock.get(item_id, PlacementInventoryCatalog.get_initial_owned(item_def))))
		_item_owned_totals[item_id] = owned_total
		_item_stock[item_id] = owned_total
		_placed_item_counts[item_id] = 0

func _rebuild_room_from_layout(layout: Dictionary) -> void:
	_clear_room(false)
	_apply_owned_stock_state(_build_owned_stock_from_layout(layout))

	if _room_shell != null and _room_shell.has_method("set_floor_style"):
		_room_shell.call("set_floor_style", int(layout.get("floor_style", FLOOR_STYLE_COZY_BROWN)))

	var raw_items: Variant = layout.get("items", [])
	if raw_items is Array:
		var root_items: Array[Dictionary] = []
		var hosted_items: Array[Dictionary] = []
		for raw_item in raw_items:
			if typeof(raw_item) != TYPE_DICTIONARY:
				continue
			var item_entry: Dictionary = raw_item
			var attachment := _build_saved_attachment(item_entry)
			if String(attachment.get("kind", RoomConstants.ATTACHMENT_ROOM)) == RoomConstants.ATTACHMENT_SUPPORT_SURFACE:
				hosted_items.append(item_entry)
			else:
				root_items.append(item_entry)

		var loaded_instances: Dictionary = {}
		for item_entry in root_items:
			var loaded_placeable := _instantiate_saved_item(item_entry, loaded_instances)
			if loaded_placeable == null:
				continue
			loaded_instances[_get_placeable_instance_id(loaded_placeable)] = loaded_placeable

		var pending_hosted := hosted_items.duplicate()
		var made_progress := true
		while made_progress and not pending_hosted.is_empty():
			made_progress = false
			var next_pending: Array[Dictionary] = []
			for item_entry in pending_hosted:
				var loaded_placeable := _instantiate_saved_item(item_entry, loaded_instances)
				if loaded_placeable == null:
					next_pending.append(item_entry)
					continue
				loaded_instances[_get_placeable_instance_id(loaded_placeable)] = loaded_placeable
				made_progress = true
			pending_hosted = next_pending

		if not pending_hosted.is_empty():
			push_warning("Skipped %d hosted layout item(s) because their host instance was unavailable." % pending_hosted.size())

	_sync_room_wall_openings()
	_update_floor_style_ui()
	_update_inventory_ui()
	_update_status_text()
	_notify_room_layout_visuals_changed()

func _load_room_layout() -> bool:
	var layout := _load_room_layout_data()
	if layout.is_empty():
		return false

	_rebuild_room_from_layout(layout)
	return true

func _load_room_layout_on_startup() -> void:
	if Engine.is_editor_hint():
		_refresh_editor_preview_from_saved_layout(true)
		return
	_load_room_layout()

func _process_editor_preview(delta: float) -> void:
	_editor_preview_poll_time -= delta
	if _editor_preview_poll_time > 0.0:
		return

	_editor_preview_poll_time = EDITOR_PREVIEW_POLL_SECONDS
	_refresh_editor_preview_from_saved_layout()

func _refresh_editor_preview_from_saved_layout(force: bool = false) -> void:
	var layout_signature := PlacementRoomLayoutStore.get_file_signature()
	if not force and layout_signature == _editor_preview_layout_signature:
		return

	_editor_preview_layout_signature = layout_signature
	if layout_signature.is_empty():
		_clear_editor_preview_layout()
		return

	var layout := _load_room_layout_data()
	if layout.is_empty():
		_clear_editor_preview_layout()
		return

	_rebuild_room_from_layout(layout)

func _clear_editor_preview_layout() -> void:
	for child in _placed_items_root.get_children():
		child.free()

	_initialize_inventory_state()
	if _room_shell != null and _room_shell.has_method("set_floor_style"):
		_room_shell.call("set_floor_style", _editor_default_floor_style)
	_wall_openings_signature = ""
	_sync_room_wall_openings()

func _instantiate_saved_item(item_entry: Dictionary, loaded_instances: Dictionary = {}) -> SimpleWoodChair:
	var item_id := String(item_entry.get("item_id", ""))
	if item_id.is_empty():
		return null

	var placeable := _create_item_instance(item_id)
	if placeable == null:
		return null

	var attachment := _build_saved_attachment(item_entry)
	var attachment_kind := String(attachment.get("kind", RoomConstants.ATTACHMENT_ROOM))
	var rotation_y := float(item_entry.get("rotation_y", 0.0))
	var instance_id := String(item_entry.get("instance_id", ""))

	var placed_count: int = int(_placed_item_counts.get(item_id, 0)) + 1
	_placed_item_counts[item_id] = placed_count
	_ensure_placeable_metadata(placeable, item_id, instance_id)
	placeable.name = "%s %d" % [_get_item_display_name(item_id), placed_count]

	if attachment_kind == RoomConstants.ATTACHMENT_SUPPORT_SURFACE:
		var host_instance_id := String(attachment.get("host_instance_id", ""))
		var host_placeable := loaded_instances.get(host_instance_id, null) as SimpleWoodChair
		if host_placeable == null:
			placeable.free()
			return null
		host_placeable.add_child(placeable)
		placeable.position = PlacementRoomLayoutStore.deserialize_vector3(item_entry.get("position", {}))
		placeable.rotation.y = rotation_y
		_set_support_attachment_metadata(placeable, host_placeable, String(attachment.get("surface_id", DEFAULT_SUPPORT_SURFACE_ID)))
	else:
		var world_position := PlacementRoomLayoutStore.deserialize_vector3(item_entry.get("position", {}))
		var placement_surface := String(attachment.get("surface", item_entry.get("placement_surface", RoomConstants.FLOOR_SURFACE)))
		if _is_wall_placeable(placeable) and RoomConstants.is_wall_surface(placement_surface):
			rotation_y = RoomConstants.get_wall_rotation(placement_surface) + placeable.get_wall_rotation_offset()
			if _room_shell != null:
				var horizontal_value := PlacementSurfaceQueries.get_wall_surface_horizontal_value(placement_surface, world_position)
				world_position = PlacementSurfaceQueries.build_wall_mount_position(_room_shell, placement_surface, horizontal_value, world_position.y, placeable)
		var placement_transform := Transform3D(Basis.IDENTITY.rotated(Vector3.UP, rotation_y), world_position)
		_placed_items_root.add_child(placeable)
		placeable.global_transform = placement_transform
		_set_room_attachment_metadata(placeable, placement_surface)

	placeable.set_preview_mode(false)
	_apply_cutaway_to_placeable(placeable)
	_item_stock[item_id] = maxi(0, int(_item_stock.get(item_id, 0)) - 1)
	return placeable

func _autosave_room_layout() -> void:
	_save_room_layout()

func _clear_room(save_after_clear: bool = true) -> void:
	if _placement_active:
		_cancel_current_placement()

	for child in _placed_items_root.get_children():
		child.free()

	for item_id in _item_owned_totals.keys():
		_item_stock[item_id] = int(_item_owned_totals.get(item_id, 0))
		_placed_item_counts[item_id] = 0
	_wall_openings_signature = ""
	_sync_room_wall_openings()
	_update_inventory_ui()
	_update_status_text()
	_notify_room_layout_visuals_changed()
	if save_after_clear:
		_autosave_room_layout()

func reload_item_catalog_from_source(refresh_room_from_layout: bool = true) -> void:
	if _placement_active:
		_cancel_current_placement()

	_inventory_item_defs = PlacementInventoryCatalog.build_item_defs()
	_shop_categories = PlacementInventoryCatalog.build_category_names(_inventory_item_defs)
	_rebuild_filter_options()
	_select_option_button_value(_mount_filter_option, _selected_mount_filter)
	_select_option_button_value(_category_filter_option, _get_selected_browser_category())

	if refresh_room_from_layout:
		var layout := _load_room_layout_data()
		if not layout.is_empty():
			_rebuild_room_from_layout(layout)
			return

	_update_inventory_ui()
	_update_status_text()
	_update_floor_style_ui()
	_notify_room_layout_visuals_changed()

func _sync_room_wall_openings() -> bool:
	if _room_shell == null:
		return false

	var openings_by_surface: Dictionary = {
		RoomConstants.WALL_BACK: [],
		RoomConstants.WALL_LEFT: [],
		RoomConstants.WALL_FRONT: [],
		RoomConstants.WALL_RIGHT: [],
	}
	for placeable in _get_placeables_under_root():
		if not placeable.requires_wall_opening():
			continue

		var surface_name := String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
		if _placement_active and placeable == _preview_item and _active_preview_is_wall_placeable():
			surface_name = _active_surface_name
		_append_wall_opening_for_placeable(openings_by_surface, placeable, surface_name)

	if _placement_active and _preview_item != null and _preview_item.requires_wall_opening() and _preview_item.get_parent() != _placed_items_root:
		_append_wall_opening_for_placeable(openings_by_surface, _preview_item, _active_surface_name)

	var next_signature := _build_wall_openings_signature(openings_by_surface)
	if next_signature == _wall_openings_signature:
		return false

	_wall_openings_signature = next_signature
	if _room_shell.has_method("set_runtime_wall_openings_batch"):
		_room_shell.call("set_runtime_wall_openings_batch", openings_by_surface)
		return true

	for surface_name in RoomConstants.WALL_SURFACES:
		var openings: Array[Dictionary] = []
		var raw_openings: Variant = openings_by_surface.get(surface_name, [])
		if raw_openings is Array:
			for raw_opening in raw_openings:
				if typeof(raw_opening) != TYPE_DICTIONARY:
					continue
				openings.append(raw_opening as Dictionary)
		_room_shell.set_runtime_wall_openings(surface_name, openings)
	return true

func set_wall_surface_cutaway(surface_name: String, is_cutaway: bool) -> void:
	if not _wall_surface_cutaway_states.has(surface_name):
		return

	_wall_surface_cutaway_states[surface_name] = bool(is_cutaway)
	_apply_cutaway_to_surface(surface_name)

func set_ceiling_surface_cutaway(is_cutaway: bool) -> void:
	_ceiling_surface_cutaway = bool(is_cutaway)
	_apply_cutaway_to_surface(RoomConstants.CEILING_SURFACE)

func clear_wall_surface_cutaways() -> void:
	for surface_name in _wall_surface_cutaway_states.keys():
		_wall_surface_cutaway_states[surface_name] = false
		_apply_cutaway_to_surface(String(surface_name))
	_ceiling_surface_cutaway = false
	_apply_cutaway_to_surface(RoomConstants.CEILING_SURFACE)

func _apply_cutaway_to_surface(_surface_name: String) -> void:
	if _placed_items_root == null:
		return

	for placeable in _get_placeables_under_root():
		if _placement_active and placeable == _preview_item:
			placeable.set_camera_cutaway(false)
			continue
		_apply_cutaway_to_placeable(placeable)

func _apply_cutaway_to_placeable(placeable: SimpleWoodChair) -> void:
	if placeable == null:
		return

	placeable.set_camera_cutaway(_is_placeable_effectively_cutaway(placeable))

func _append_wall_opening_for_placeable(openings_by_surface: Dictionary, placeable: SimpleWoodChair, surface_name: String) -> void:
	if placeable == null or not RoomConstants.is_wall_surface(surface_name):
		return

	var half_extents: Vector2 = placeable.get_wall_opening_half_extents()
	var center_u: float
	if surface_name == RoomConstants.WALL_BACK or surface_name == RoomConstants.WALL_FRONT:
		center_u = placeable.global_position.x - _room_shell.global_position.x
	else:
		center_u = placeable.global_position.z - _room_shell.global_position.z
	var center_v: float = placeable.global_position.y - _room_shell.get_wall_bottom_y()

	var openings := openings_by_surface.get(surface_name, []) as Array
	openings.append(
		{
			"center_u": center_u,
			"center_v": center_v,
			"half_u": half_extents.x,
			"half_v": half_extents.y,
		}
	)
	openings_by_surface[surface_name] = openings

func _create_item_instance(item_id: String) -> SimpleWoodChair:
	var item_def: Dictionary = _get_item_definition(item_id)
	if item_def.is_empty():
		return null
	return PlacementInventoryCatalog.create_item_instance(item_def) as SimpleWoodChair

func _create_item_instance_from_definition(item_def: Dictionary) -> SimpleWoodChair:
	if item_def.is_empty():
		return null
	return _create_item_instance(String(item_def.get("id", "")))

func _activate_preview_session(preview_item: SimpleWoodChair, item_id: String, session_kind: String, rename_preview: bool) -> void:
	if preview_item == null:
		return

	_preview_item = preview_item
	_active_item_id = item_id
	_placement_session = session_kind
	_active_support_host = null
	_active_support_surface_id = DEFAULT_SUPPORT_SURFACE_ID
	if _is_wall_placeable(_preview_item):
		_active_surface_name = _preview_item.get_default_wall_surface()
	elif _is_ceiling_placeable(_preview_item):
		_active_surface_name = RoomConstants.CEILING_SURFACE
	elif _active_preview_is_support_surface_placeable():
		_active_surface_name = RoomConstants.MOUNT_SURFACE
	else:
		_active_surface_name = RoomConstants.FLOOR_SURFACE
	if rename_preview:
		_preview_item.name = "%s Preview" % _get_item_display_name(item_id)
	_preview_item.set_preview_mode(true)
	_placement_query_shape.size = _preview_item.get_collision_size()
	_placement_active = true
	_placement_valid = false
	_placement_issue_code = ""
	_placement_issue_text = ""
	_popup_visual_signature = ""
	_hover_target = ""
	_drag_mode = ""
	_update_mode_ui()
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()

func _start_inventory_placement(item_id: String) -> void:
	var current_stock: int = int(_item_stock.get(item_id, 0))
	if current_stock <= 0:
		return

	var preview_item := _create_item_instance(item_id)
	if preview_item == null:
		return

	_item_stock[item_id] = current_stock - 1
	add_child(preview_item)
	_activate_preview_session(preview_item, item_id, PLACEMENT_SESSION_NEW, true)
	_update_preview_from_mouse(true)

func _resolve_item_id_for_placeable(placeable: SimpleWoodChair) -> String:
	if placeable == null:
		return ""
	if placeable.has_meta("item_id"):
		return String(placeable.get_meta("item_id"))

	var placeable_script := placeable.get_script() as Script
	if placeable_script == null:
		return ""

	for item_def in _inventory_item_defs:
		var item_script: Script = _get_item_script(item_def)
		if item_script != null and item_script.resource_path == placeable_script.resource_path:
			return String(item_def.get("id", ""))

	return ""

func _get_placeable_instance_id(placeable: SimpleWoodChair) -> String:
	if placeable == null:
		return ""
	if placeable.has_meta("instance_id"):
		return String(placeable.get_meta("instance_id"))

	var instance_id := "placed_%d_%d" % [Time.get_ticks_usec(), _next_placeable_instance_serial]
	_next_placeable_instance_serial += 1
	placeable.set_meta("instance_id", instance_id)
	return instance_id

func _set_room_attachment_metadata(placeable: SimpleWoodChair, surface_name: String) -> void:
	if placeable == null:
		return
	placeable.set_meta("attachment_kind", RoomConstants.ATTACHMENT_ROOM)
	placeable.set_meta("placement_surface", surface_name)
	if placeable.has_meta("host_instance_id"):
		placeable.remove_meta("host_instance_id")
	if placeable.has_meta("host_surface_id"):
		placeable.remove_meta("host_surface_id")

func _set_support_attachment_metadata(placeable: SimpleWoodChair, host: SimpleWoodChair, surface_id: String) -> void:
	if placeable == null or host == null:
		return
	placeable.set_meta("attachment_kind", RoomConstants.ATTACHMENT_SUPPORT_SURFACE)
	placeable.set_meta("placement_surface", RoomConstants.MOUNT_SURFACE)
	placeable.set_meta("host_instance_id", _get_placeable_instance_id(host))
	placeable.set_meta("host_surface_id", surface_id if not surface_id.is_empty() else DEFAULT_SUPPORT_SURFACE_ID)

func _get_placeable_attachment_kind(placeable: SimpleWoodChair) -> String:
	if placeable == null:
		return RoomConstants.ATTACHMENT_ROOM
	if placeable.has_meta("attachment_kind"):
		return String(placeable.get_meta("attachment_kind"))
	return RoomConstants.ATTACHMENT_SUPPORT_SURFACE if placeable.get_parent() is SimpleWoodChair else RoomConstants.ATTACHMENT_ROOM

func _build_saved_attachment(item_entry: Dictionary) -> Dictionary:
	var raw_attachment: Variant = item_entry.get("attachment", {})
	if raw_attachment is Dictionary:
		var attachment := raw_attachment as Dictionary
		var attachment_kind := String(attachment.get("kind", ""))
		if attachment_kind == RoomConstants.ATTACHMENT_SUPPORT_SURFACE:
			return {
				"kind": RoomConstants.ATTACHMENT_SUPPORT_SURFACE,
				"host_instance_id": String(attachment.get("host_instance_id", "")),
				"surface_id": String(attachment.get("surface_id", DEFAULT_SUPPORT_SURFACE_ID)),
			}
		return {
			"kind": RoomConstants.ATTACHMENT_ROOM,
			"surface": String(attachment.get("surface", item_entry.get("placement_surface", RoomConstants.FLOOR_SURFACE))),
		}

	return {
		"kind": RoomConstants.ATTACHMENT_ROOM,
		"surface": String(item_entry.get("placement_surface", RoomConstants.FLOOR_SURFACE)),
	}

func _ensure_placeable_metadata(placeable: SimpleWoodChair, item_id: String, instance_id: String = "") -> void:
	if placeable == null or item_id.is_empty():
		return
	placeable.set_meta("item_id", item_id)
	placeable.set_meta("display_name", _get_item_display_name(item_id))
	if not instance_id.is_empty():
		placeable.set_meta("instance_id", instance_id)
	else:
		_get_placeable_instance_id(placeable)

func _begin_edit_session(placeable: SimpleWoodChair) -> void:
	if placeable == null:
		return

	var item_id := _resolve_item_id_for_placeable(placeable)
	if item_id.is_empty():
		return

	_ensure_placeable_metadata(placeable, item_id)
	_editing_original_transform = placeable.global_transform
	_editing_original_local_transform = placeable.transform
	_editing_original_parent = placeable.get_parent()
	_editing_original_surface_name = String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
	_editing_original_host_surface_id = String(placeable.get_meta("host_surface_id")) if placeable.has_meta("host_surface_id") else DEFAULT_SUPPORT_SURFACE_ID
	_activate_preview_session(placeable, item_id, PLACEMENT_SESSION_EDIT, false)
	_active_surface_name = _editing_original_surface_name
	if _active_preview_is_support_surface_placeable():
		_active_support_host = _editing_original_parent as SimpleWoodChair
		_active_support_surface_id = _editing_original_host_surface_id
	if _active_preview_is_wall_placeable() and RoomConstants.is_wall_surface(_active_surface_name):
		_preview_item.rotation.y = RoomConstants.get_wall_rotation(_active_surface_name) + _preview_item.get_wall_rotation_offset()
	_sync_room_wall_openings()
	_refresh_preview_validity()

func _commit_new_preview_item() -> void:
	if _preview_item == null or _active_item_id.is_empty():
		return

	var placed_count: int = int(_placed_item_counts.get(_active_item_id, 0)) + 1
	_placed_item_counts[_active_item_id] = placed_count
	_ensure_placeable_metadata(_preview_item, _active_item_id)
	_preview_item.name = "%s %d" % [_get_item_display_name(_active_item_id), placed_count]
	if _active_preview_is_support_surface_placeable():
		if _active_support_host == null:
			return
		if _preview_item.get_parent() != _active_support_host:
			_preview_item.reparent(_active_support_host, true)
		_set_support_attachment_metadata(_preview_item, _active_support_host, _active_support_surface_id)
	else:
		if _preview_item.get_parent() != _placed_items_root:
			_preview_item.reparent(_placed_items_root, true)
		_set_room_attachment_metadata(_preview_item, _active_surface_name)
	_preview_item.set_preview_mode(false)
	_apply_cutaway_to_placeable(_preview_item)

func _commit_edit_preview_item() -> void:
	if _preview_item == null:
		return

	_ensure_placeable_metadata(_preview_item, _active_item_id)
	if _active_preview_is_support_surface_placeable():
		if _active_support_host == null:
			return
		if _preview_item.get_parent() != _active_support_host:
			_preview_item.reparent(_active_support_host, true)
		_set_support_attachment_metadata(_preview_item, _active_support_host, _active_support_surface_id)
	else:
		if _preview_item.get_parent() != _placed_items_root:
			_preview_item.reparent(_placed_items_root, true)
		_set_room_attachment_metadata(_preview_item, _active_surface_name)
	_preview_item.set_preview_mode(false)
	_apply_cutaway_to_placeable(_preview_item)

func _restore_or_discard_active_preview(refund_stock: bool) -> void:
	if _preview_item == null:
		return

	match _placement_session:
		PLACEMENT_SESSION_EDIT:
			if _editing_original_parent != null and is_instance_valid(_editing_original_parent) and _preview_item.get_parent() != _editing_original_parent:
				_preview_item.reparent(_editing_original_parent, true)
			if _get_placeable_attachment_kind(_preview_item) == RoomConstants.ATTACHMENT_SUPPORT_SURFACE or _editing_original_parent is SimpleWoodChair:
				_preview_item.transform = _editing_original_local_transform
				var original_host := _editing_original_parent as SimpleWoodChair
				if original_host != null:
					_set_support_attachment_metadata(_preview_item, original_host, _editing_original_host_surface_id)
			else:
				_preview_item.global_transform = _editing_original_transform
				_set_room_attachment_metadata(_preview_item, _editing_original_surface_name)
			_preview_item.set_preview_mode(false)
			_apply_cutaway_to_placeable(_preview_item)
		PLACEMENT_SESSION_NEW, PLACEMENT_SESSION_DUPLICATE:
			if refund_stock and not _active_item_id.is_empty():
				_item_stock[_active_item_id] = int(_item_stock.get(_active_item_id, 0)) + 1
			_preview_item.queue_free()

func _clear_active_session() -> void:
	_preview_item = null
	_active_support_host = null
	_active_support_surface_id = DEFAULT_SUPPORT_SURFACE_ID
	_placement_active = false
	_placement_valid = false
	_placement_issue_code = ""
	_placement_issue_text = ""
	_hover_target = ""
	_drag_mode = ""
	_active_item_id = ""
	_active_surface_name = RoomConstants.FLOOR_SURFACE
	_placement_session = PLACEMENT_SESSION_NONE
	_editing_original_transform = Transform3D.IDENTITY
	_editing_original_local_transform = Transform3D.IDENTITY
	_editing_original_parent = null
	_editing_original_surface_name = RoomConstants.FLOOR_SURFACE
	_editing_original_host_surface_id = DEFAULT_SUPPORT_SURFACE_ID
	_popup_visual_signature = ""
	_popup_panel.visible = false
	_gizmo_root.visible = false
	_sync_room_wall_openings()
	_update_mode_ui()
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()

func _find_duplicate_seed_position(base_position: Vector3) -> Vector3:
	if _active_preview_is_wall_placeable():
		return _find_wall_duplicate_seed_position(base_position)
	if _active_preview_is_ceiling_placeable():
		return _find_planar_duplicate_seed_position(base_position, RoomConstants.CEILING_SURFACE)
	if _active_preview_is_support_surface_placeable():
		return _find_support_surface_duplicate_seed_position(base_position)
	return _find_planar_duplicate_seed_position(base_position, RoomConstants.FLOOR_SURFACE)

func _find_support_surface_duplicate_seed_position(base_position: Vector3) -> Vector3:
	if _active_support_host == null:
		return base_position

	var candidate_offsets: Array[Vector3] = [
		Vector3(SUPPORT_SURFACE_SNAP_SIZE, 0.0, 0.0),
		Vector3(-SUPPORT_SURFACE_SNAP_SIZE, 0.0, 0.0),
		Vector3(0.0, 0.0, SUPPORT_SURFACE_SNAP_SIZE),
		Vector3(0.0, 0.0, -SUPPORT_SURFACE_SNAP_SIZE),
		Vector3(SUPPORT_SURFACE_SNAP_SIZE, 0.0, SUPPORT_SURFACE_SNAP_SIZE),
		Vector3(SUPPORT_SURFACE_SNAP_SIZE, 0.0, -SUPPORT_SURFACE_SNAP_SIZE),
		Vector3(-SUPPORT_SURFACE_SNAP_SIZE, 0.0, SUPPORT_SURFACE_SNAP_SIZE),
		Vector3(-SUPPORT_SURFACE_SNAP_SIZE, 0.0, -SUPPORT_SURFACE_SNAP_SIZE),
	]

	for offset in candidate_offsets:
		_set_preview_position(base_position + offset)
		if _placement_valid:
			return _preview_item.global_position

	return _preview_item.global_position

func _find_planar_duplicate_seed_position(base_position: Vector3, surface_name: String) -> Vector3:
	var candidate_offsets: Array[Vector3] = [
		Vector3(GRID_SIZE, 0.0, 0.0),
		Vector3(-GRID_SIZE, 0.0, 0.0),
		Vector3(0.0, 0.0, GRID_SIZE),
		Vector3(0.0, 0.0, -GRID_SIZE),
		Vector3(GRID_SIZE, 0.0, GRID_SIZE),
		Vector3(GRID_SIZE, 0.0, -GRID_SIZE),
		Vector3(-GRID_SIZE, 0.0, GRID_SIZE),
		Vector3(-GRID_SIZE, 0.0, -GRID_SIZE),
		Vector3(GRID_SIZE * 2.0, 0.0, 0.0),
		Vector3(-GRID_SIZE * 2.0, 0.0, 0.0),
		Vector3(0.0, 0.0, GRID_SIZE * 2.0),
		Vector3(0.0, 0.0, -GRID_SIZE * 2.0),
	]

	for offset in candidate_offsets:
		var candidate := base_position + offset
		_preview_item.global_position = _snap_planar_position(candidate, surface_name)
		_refresh_preview_validity()
		if _placement_valid:
			return _preview_item.global_position

	return _snap_planar_position(base_position, surface_name)

func _find_wall_duplicate_seed_position(base_position: Vector3) -> Vector3:
	var candidate_offsets: Array[Vector2] = [
		Vector2(GRID_SIZE, 0.0),
		Vector2(-GRID_SIZE, 0.0),
		Vector2(0.0, GRID_SIZE),
		Vector2(0.0, -GRID_SIZE),
		Vector2(GRID_SIZE * 2.0, 0.0),
		Vector2(-GRID_SIZE * 2.0, 0.0),
		Vector2(0.0, GRID_SIZE * 2.0),
		Vector2(0.0, -GRID_SIZE * 2.0),
	]

	for offset in candidate_offsets:
		var candidate := base_position
		if _active_surface_name == RoomConstants.WALL_BACK or _active_surface_name == RoomConstants.WALL_FRONT:
			candidate.x += offset.x
			candidate.y += offset.y
		else:
			candidate.z += offset.x
			candidate.y += offset.y

		_preview_item.global_position = _snap_wall_position(candidate)
		_refresh_preview_validity()
		if _placement_valid:
			return _preview_item.global_position

	return _snap_wall_position(base_position)

func _on_inventory_item_button_pressed(item_id: String) -> void:
	var item_def: Dictionary = _get_item_definition(item_id)
	if _placement_active or item_def.is_empty():
		return
	if not PlacementInventoryCatalog.supports_runtime_placement(item_def):
		return
	if _is_edit_mode():
		_editor_mode = EDITOR_MODE_BUILD
		_update_mode_ui()
		_update_inventory_ui()
		_update_status_text()
		_update_grid_visibility()
	_set_browser_open(false)
	_start_inventory_placement(item_id)

func _on_shop_buy_requested(item_id: String) -> void:
	var item_def := _get_item_definition(item_id)
	if item_def.is_empty():
		return
	_item_owned_totals[item_id] = int(_item_owned_totals.get(item_id, 0)) + 1
	_item_stock[item_id] = int(_item_stock.get(item_id, 0)) + 1
	call_deferred("_update_inventory_ui")
	call_deferred("_update_status_text")
	_autosave_room_layout()

func _on_browser_mode_button_pressed(mode_id: String) -> void:
	if _placement_active:
		return
	if mode_id == _browser_mode:
		return
	_browser_mode = mode_id
	_update_browser_mode_ui()
	_update_inventory_ui()
	_update_status_text()

func _on_shop_category_button_pressed(category_name: String) -> void:
	if _placement_active:
		return
	if category_name == _get_selected_browser_category():
		return
	if _browser_mode == BROWSER_MODE_SHOP:
		_selected_shop_category = category_name
	else:
		_selected_inventory_category = category_name
	_update_browser_mode_ui()
	_update_inventory_ui()

func _on_mode_button_pressed(mode_id: String) -> void:
	if _placement_active or mode_id == _editor_mode:
		return

	_editor_mode = mode_id
	_update_mode_ui()
	_update_inventory_ui()
	_update_status_text()
	_update_grid_visibility()

func _on_grid_toggle_button_pressed() -> void:
	if _is_edit_mode():
		return
	_manual_grid_visible = not _manual_grid_visible
	_update_grid_visibility()
	_update_inventory_ui()

func _on_floor_style_button_pressed(style_id: int) -> void:
	if _room_shell == null:
		return

	if _room_shell.has_method("set_floor_style"):
		_room_shell.call("set_floor_style", style_id)
	_update_floor_style_ui()
	_autosave_room_layout()

func _on_save_button_pressed() -> void:
	_save_room_layout()

func _on_load_button_pressed() -> void:
	_load_room_layout()

func _on_clear_room_button_pressed() -> void:
	_clear_room(true)

func _on_confirm_button_pressed() -> void:
	if not _placement_active or not _placement_valid or _preview_item == null:
		return

	match _placement_session:
		PLACEMENT_SESSION_EDIT:
			_commit_edit_preview_item()
		PLACEMENT_SESSION_NEW, PLACEMENT_SESSION_DUPLICATE:
			_commit_new_preview_item()
		_:
			return

	_sync_room_wall_openings()
	_clear_active_session()
	_autosave_room_layout()
	_notify_room_layout_visuals_changed()

func _on_cancel_button_pressed() -> void:
	_cancel_current_placement()

func _on_duplicate_button_pressed() -> void:
	if not _is_edit_session() or _preview_item == null or not _placement_valid:
		return

	var current_stock: int = int(_item_stock.get(_active_item_id, 0))
	if current_stock <= 0:
		return

	var duplicate_preview := _create_item_instance(_active_item_id)
	if duplicate_preview == null:
		return

	var seed_transform := _preview_item.global_transform
	var seed_rotation := _preview_item.rotation.y
	var original_surface_name := _active_surface_name
	var original_support_host := _active_support_host
	var original_support_surface_id := _active_support_surface_id
	_commit_edit_preview_item()
	_item_stock[_active_item_id] = current_stock - 1
	add_child(duplicate_preview)
	_activate_preview_session(duplicate_preview, _active_item_id, PLACEMENT_SESSION_DUPLICATE, true)
	_active_surface_name = original_surface_name
	_active_support_host = original_support_host
	_active_support_surface_id = original_support_surface_id
	if _active_preview_is_support_surface_placeable() and _active_support_host != null:
		_preview_item.reparent(_active_support_host, true)
	_sync_room_wall_openings()
	_preview_item.rotation.y = seed_rotation
	_preview_item.global_position = _find_duplicate_seed_position(seed_transform.origin)
	_refresh_preview_validity()

func _on_delete_button_pressed() -> void:
	if not _is_edit_session() or _preview_item == null:
		return

	_refund_stock_for_placeable_tree(_preview_item)
	_preview_item.free()
	_sync_room_wall_openings()
	_clear_active_session()
	_autosave_room_layout()
	_notify_room_layout_visuals_changed()

func set_debug_world_active(active: bool) -> void:
	if _debug_world_active == active:
		return

	_debug_world_active = active
	if active:
		_cancel_current_placement()

	set_process_input(not active)
	set_process_unhandled_input(not active)
	if _ui_layer != null:
		_ui_layer.visible = not active
	if _status_shell != null:
		_status_shell.visible = not active
	if _popup_panel != null:
		_popup_panel.visible = false
	if _gizmo_root != null:
		_gizmo_root.visible = false
	if _grid_overlay != null:
		_grid_overlay.visible = not active and _manual_grid_visible
	if _placed_items_root != null:
		_placed_items_root.visible = not active
	if not active:
		_update_inventory_ui()
		_update_status_text()
		_update_grid_visibility()

func _cancel_current_placement() -> void:
	if not _placement_active:
		return

	_restore_or_discard_active_preview(true)
	_clear_active_session()

func _update_preview_from_mouse(use_current_mouse: bool) -> void:
	if _preview_item == null or _room_shell == null:
		return

	var target_position: Vector3 = _preview_item.global_position
	if use_current_mouse:
		var hit := _try_get_active_surface_hit(get_viewport().get_mouse_position())
		if hit.get("valid", false):
			_apply_preview_surface_hit(hit)
			return
		if _active_preview_is_support_surface_placeable():
			var nearest_support_hit := _find_nearest_support_surface_hit()
			if nearest_support_hit.get("valid", false):
				_apply_preview_surface_hit(nearest_support_hit)
				return

	_set_preview_position(target_position)

func _rotate_preview(direction: int) -> void:
	if _preview_item == null or not _preview_item.supports_rotation():
		return

	_preview_item.rotate_y(deg_to_rad(90.0 * float(direction)))
	_refresh_preview_validity()

func _evaluate_preview_transform() -> Dictionary:
	if _active_preview_is_support_surface_placeable():
		return _evaluate_support_surface_preview_transform()
	return PlacementValidator.evaluate_preview_transform(
		get_world_3d(),
		_room_shell,
		_preview_item,
		_active_surface_name,
		_placement_query_shape,
		_get_preview_excluded_rids()
	)

func _evaluate_support_surface_preview_transform() -> Dictionary:
	if _preview_item == null or _room_shell == null:
		return {"valid": false, "code": "missing", "reason": "Placement unavailable"}
	if _active_support_host == null:
		return {"valid": false, "code": "surface", "reason": "Select a flat surface"}

	var support_surface := _get_active_support_surface_data()
	if support_surface.is_empty():
		return {"valid": false, "code": "surface", "reason": "Select a flat surface"}

	var center_offset := support_surface.get("center_offset", Vector3.ZERO) as Vector3
	var half_extents := support_surface.get("half_extents", Vector2.ZERO) as Vector2
	var local_offset := _preview_item.position - center_offset
	var item_half_extents := _get_rotated_planar_half_extents(_preview_item.get_footprint_half_extents(), _preview_item.rotation.y)
	if absf(local_offset.x) + item_half_extents.x > half_extents.x + 0.001:
		return {"valid": false, "code": "bounds", "reason": "Too close to surface edge"}
	if absf(local_offset.z) + item_half_extents.y > half_extents.y + 0.001:
		return {"valid": false, "code": "bounds", "reason": "Too close to surface edge"}

	var expected_y := center_offset.y + SUPPORT_SURFACE_CLEARANCE
	if absf(_preview_item.position.y - expected_y) > 0.02:
		return {"valid": false, "code": "surface", "reason": "Move onto the flat surface"}

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _placement_query_shape
	query.collision_mask = SimpleWoodChair.COLLISION_LAYER
	query.exclude = _get_preview_excluded_rids()
	query.exclude.append(_active_support_host.get_rid())
	query.transform = _preview_item.global_transform.translated_local(_preview_item.get_collision_center_offset())
	if not get_world_3d().direct_space_state.intersect_shape(query, 8).is_empty():
		return {"valid": false, "code": "occupied", "reason": "Space occupied"}

	return {"valid": true, "code": "valid", "reason": "Ready to place"}

func _get_preview_excluded_rids() -> Array[RID]:
	var excluded_rids: Array[RID] = []
	if _preview_item == null:
		return excluded_rids
	for placeable in _collect_placeable_tree(_preview_item):
		excluded_rids.append(placeable.get_rid())
	return excluded_rids

func _refresh_preview_validity() -> void:
	if _preview_item == null:
		return

	var evaluation := _evaluate_preview_transform()
	_placement_valid = evaluation.get("valid", false)
	_placement_issue_code = String(evaluation.get("code", ""))
	_placement_issue_text = String(evaluation.get("reason", ""))
	_preview_item.set_preview_valid(_placement_valid)
	_preview_item.set_hovered(_hover_target == "move" or _drag_mode == "move")
	_confirm_button.disabled = not _placement_valid
	_popup_panel.visible = true
	_gizmo_root.visible = not _active_preview_is_wall_placeable()
	_update_popup_visuals()
	_update_status_text()

func _update_inventory_ui() -> void:
	var grid_visible := _manual_grid_visible or _placement_active or _is_edit_mode()
	_update_browser_mode_ui()
	_rebuild_item_browser()
	_update_section_toggle_ui()
	if _browser_search_input != null:
		_browser_search_input.editable = not _placement_active
	if _grid_toggle_button != null:
		if _is_edit_mode():
			_grid_toggle_button.text = "Grid Overlay: On (Edit Mode)"
			_grid_toggle_button.disabled = true
		else:
			_grid_toggle_button.text = "Grid Overlay: %s" % ("On" if grid_visible else "Off")
			_grid_toggle_button.disabled = false
		PlacementUiStyles.apply_button_style(
			_grid_toggle_button,
			PlacementUiStyles.COLOR_PANEL_ALT,
			PlacementUiStyles.COLOR_BORDER,
			PlacementUiStyles.COLOR_TEXT
		)
	if _save_button != null:
		_save_button.disabled = _placement_active
		PlacementUiStyles.apply_button_style(
			_save_button,
			PlacementUiStyles.COLOR_PANEL_ALT,
			PlacementUiStyles.COLOR_BORDER,
			PlacementUiStyles.COLOR_TEXT
		)
	if _load_button != null:
		_load_button.disabled = _placement_active
		PlacementUiStyles.apply_button_style(
			_load_button,
			PlacementUiStyles.COLOR_PANEL_ALT,
			PlacementUiStyles.COLOR_BORDER,
			PlacementUiStyles.COLOR_TEXT
		)
	if _clear_room_button != null:
		_clear_room_button.disabled = _placement_active
		PlacementUiStyles.apply_button_style(
			_clear_room_button,
			PlacementUiStyles.COLOR_DANGER,
			PlacementUiStyles.COLOR_DANGER_BORDER,
			PlacementUiStyles.COLOR_TEXT
		)
	if _browser_section_label != null:
		var result_count := _get_visible_browser_item_defs().size()
		var category_name := _get_selected_browser_category()
		var category_suffix := ": %s" % category_name if not category_name.is_empty() else ""
		if _browser_mode == BROWSER_MODE_SHOP:
			_browser_section_label.text = "Shop Catalog%s  |  %d results" % [category_suffix, result_count]
		else:
			_browser_section_label.text = "Inventory%s  |  %d results" % [category_suffix, result_count]
	if _status_shell != null:
		_status_shell.visible = _placement_active or _is_edit_mode() or not _has_any_stock()
	if _inventory_panel != null:
		PlacementUiStyles.apply_panel_style(_inventory_panel, PlacementUiStyles.COLOR_PANEL, PlacementUiStyles.COLOR_BORDER, 1, 18, 10, 0.24)

func _update_mode_ui() -> void:
	for mode_id in _mode_buttons.keys():
		var button := _mode_buttons.get(mode_id) as Button
		if button == null:
			continue

		var is_selected := String(mode_id) == _editor_mode
		button.button_pressed = is_selected
		button.disabled = is_selected or _placement_active
		PlacementUiStyles.apply_button_style(
			button,
			PlacementUiStyles.COLOR_PANEL_ALT if not is_selected else PlacementUiStyles.COLOR_ACCENT,
			PlacementUiStyles.COLOR_BORDER if not is_selected else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
			PlacementUiStyles.COLOR_TEXT
		)

	if _mode_label != null:
		_mode_label.text = "Mode: %s" % ("Edit" if _is_edit_mode() else "Build")

func _update_browser_mode_ui() -> void:
	for mode_id in _browser_mode_buttons.keys():
		var button := _browser_mode_buttons.get(mode_id) as Button
		if button == null:
			continue
		var is_selected := String(mode_id) == _browser_mode
		button.button_pressed = is_selected
		button.disabled = is_selected or _placement_active
		PlacementUiStyles.apply_button_style(
			button,
			PlacementUiStyles.COLOR_PANEL_SOFT if not is_selected else PlacementUiStyles.COLOR_ACCENT_DARK,
			PlacementUiStyles.COLOR_BORDER if not is_selected else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
			PlacementUiStyles.COLOR_TEXT
		)

	if _mount_filter_option != null:
		_mount_filter_option.disabled = _placement_active
		PlacementUiStyles.apply_button_style(
			_mount_filter_option,
			PlacementUiStyles.COLOR_PANEL_SOFT,
			PlacementUiStyles.COLOR_BORDER_SOFT,
			PlacementUiStyles.COLOR_TEXT
		)
		_select_option_button_value(_mount_filter_option, _selected_mount_filter)

	if _category_filter_option != null:
		_category_filter_option.disabled = _placement_active
		PlacementUiStyles.apply_button_style(
			_category_filter_option,
			PlacementUiStyles.COLOR_PANEL_SOFT,
			PlacementUiStyles.COLOR_BORDER_SOFT,
			PlacementUiStyles.COLOR_TEXT
		)
		_select_option_button_value(_category_filter_option, _get_selected_browser_category())

func _get_owned_item_type_count() -> int:
	var count := 0
	for item_id in _item_owned_totals.keys():
		if int(_item_owned_totals.get(item_id, 0)) > 0:
			count += 1
	return count

func _update_floor_style_ui() -> void:
	var current_style := FLOOR_STYLE_COZY_BROWN
	if _room_shell != null and _room_shell.has_method("get_floor_style"):
		current_style = int(_room_shell.call("get_floor_style"))

	for style_id in _floor_style_buttons.keys():
		var button := _floor_style_buttons.get(style_id) as Button
		if button == null:
			continue

		var is_selected := int(style_id) == current_style
		button.button_pressed = is_selected
		button.disabled = is_selected
		PlacementUiStyles.apply_button_style(
			button,
			PlacementUiStyles.COLOR_PANEL_ALT if not is_selected else PlacementUiStyles.COLOR_ACCENT,
			PlacementUiStyles.COLOR_BORDER if not is_selected else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
			PlacementUiStyles.COLOR_TEXT
		)

	if _floor_style_label != null:
		_floor_style_label.text = "Floor Finish: %s" % ("Brown Mat" if current_style == FLOOR_STYLE_COZY_BROWN else "Checkerboard")

func _update_status_text() -> void:
	if _status_label == null:
		return

	if _placement_active:
		var target_surface_name := "furniture surface" if _active_preview_is_support_surface_placeable() else ("ceiling" if _active_preview_is_ceiling_placeable() else ("wall" if _active_preview_is_wall_placeable() else "floor"))
		if _placement_valid:
			match _placement_session:
				PLACEMENT_SESSION_EDIT:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Editing %s on the wall.\nDrag the item itself to move it across the wall. Duplicate and Delete are available while editing." % _get_active_item_display_name()
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Editing %s on the ceiling.\nDrag the item itself, use the gizmo, or rotate with Q/E." % _get_active_item_display_name()
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Editing %s on a furniture surface.\nDrag the item itself across the surface, then rotate with Q/E if needed." % _get_active_item_display_name()
					else:
						_status_label.text = "Editing %s.\nDrag the item itself, use the gizmo, or orbit with left-drag on empty space. Duplicate and Delete are available while editing." % _get_active_item_display_name()
				PLACEMENT_SESSION_DUPLICATE:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\nDrag the item to a new wall spot, then confirm to keep both copies." % _get_active_item_display_name()
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\nDrag the item to a new ceiling spot, then confirm to keep both copies." % _get_active_item_display_name()
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\nDrag the item to a new spot on a table, shelf, or cabinet top, then confirm to keep both copies." % _get_active_item_display_name()
					else:
						_status_label.text = "Ready to place a duplicate of %s.\nDrag the item to a new floor spot, then confirm to keep both copies." % _get_active_item_display_name()
				_:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Ready to place %s.\nDrag the item onto the wall, then confirm. This item cuts a window opening into the wall." % _get_active_item_display_name()
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Ready to place %s.\nDrag the item onto the ceiling, then rotate with Q/E if needed." % _get_active_item_display_name()
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Ready to place %s.\nDrag the item across a flat table, shelf, or cabinet top, then rotate with Q/E if needed." % _get_active_item_display_name()
					else:
						_status_label.text = "Ready to place %s.\nLeft-drag the item, use the gizmo handles, or orbit with left-drag on empty space. Q/E still rotates." % _get_active_item_display_name()
		else:
			match _placement_issue_code:
				"bounds":
					if _active_preview_is_wall_placeable():
						_status_label.text = "Blocked by the wall edge.\nKeep %s fully inside the visible wall area before placing." % _get_active_item_display_name()
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Blocked by the ceiling edge.\nKeep %s fully inside the ceiling area before placing." % _get_active_item_display_name()
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Blocked by the surface edge.\nKeep %s fully on the flat furniture top before placing." % _get_active_item_display_name()
					else:
						_status_label.text = "Blocked by the room edge.\nKeep %s fully inside the floor before placing." % _get_active_item_display_name()
				"surface":
					_status_label.text = "Point at the visible %s.\nThis item can only be placed on its supported mount surface." % target_surface_name
				"occupied":
					_status_label.text = "Blocked by another placed item.\nMove to a clear cell, or press X / Esc to cancel."
				_:
					_status_label.text = "Blocked placement.\nMove away from walls or another item, or press X / Esc to cancel."
		return

	if _is_edit_mode():
		_status_label.text = "Edit mode is active.\nDouble-click any placed furniture to move it. The grid stays on automatically while editing."
		return

	if not _has_any_stock():
		_status_label.text = "No available inventory stock right now.\nOpen Shop to buy more items, or switch to Edit to move what is already placed."
		return

	_status_label.text = "Choose an owned item from Inventory to place it.\nOpen Shop to buy more furniture. The dotted grid will turn on automatically while placing."

func _update_grid_visibility() -> void:
	if _grid_overlay == null:
		return

	_refresh_grid_overlay_transform()
	_grid_overlay.visible = (_manual_grid_visible or _placement_active or _is_edit_mode()) and not (_placement_active and _active_preview_is_support_surface_placeable())

func _refresh_grid_overlay_transform() -> void:
	if _grid_overlay == null or _room_shell == null:
		return

	var overlay_y := _room_shell.get_ceiling_y() - 0.03 if _placement_active and _active_preview_is_ceiling_placeable() else _room_shell.global_position.y + 0.03
	_grid_overlay.global_position = Vector3(_room_shell.global_position.x, overlay_y, _room_shell.global_position.z)

func _update_popup_position() -> void:
	if _preview_item == null:
		return

	var camera := _get_active_camera()
	if camera == null:
		return

	var anchor_world: Vector3 = _preview_item.global_position + Vector3(0.0, _get_popup_anchor_offset_y(), 0.0)
	if camera.is_position_behind(anchor_world):
		_popup_panel.visible = false
		return

	_popup_panel.visible = true
	var popup_size: Vector2 = _popup_panel.get_combined_minimum_size()
	var anchor_screen_position: Vector2 = camera.unproject_position(anchor_world)
	var screen_position := Vector2(
		anchor_screen_position.x - popup_size.x * 0.5,
		anchor_screen_position.y - popup_size.y - _get_popup_screen_gap()
	)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	screen_position.x = clamp(screen_position.x, POPUP_MARGIN, viewport_size.x - popup_size.x - POPUP_MARGIN)
	screen_position.y = clamp(screen_position.y, POPUP_MARGIN, viewport_size.y - popup_size.y - POPUP_MARGIN)
	_popup_panel.position = screen_position

func _update_gizmo_transform() -> void:
	if _preview_item == null:
		return

	_gizmo_root.global_position = _preview_item.global_position + Vector3(0.0, _get_gizmo_offset_y(), 0.0)
	_gizmo_root.global_basis = _preview_item.global_transform.basis.orthonormalized()
	var camera := _get_active_camera()
	if camera != null:
		var camera_distance: float = camera.global_position.distance_to(_gizmo_root.global_position)
		var gizmo_scale: float = clampf(camera_distance * GIZMO_DISTANCE_SCALE, GIZMO_MIN_SCALE, GIZMO_MAX_SCALE)
		_gizmo_root.scale = Vector3.ONE * gizmo_scale

func _get_active_camera() -> Camera3D:
	if _player != null and _player.has_method("get_active_camera"):
		var player_camera := _player.call("get_active_camera") as Camera3D
		if player_camera != null:
			return player_camera
	if _room_camera_controller != null and _room_camera_controller.has_method("get_camera"):
		return _room_camera_controller.call("get_camera") as Camera3D

	return get_viewport().get_camera_3d()

func _get_overlay_size() -> Vector2:
	if _room_shell == null:
		return Vector2(12.0, 12.0)

	var extents := _room_shell.get_inner_half_extents()
	return extents * 2.0

func _is_pointer_over_placement_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null

func _pick_interaction_target(mouse_position: Vector2) -> String:
	if _preview_item == null or _is_pointer_over_placement_ui():
		return ""

	if not _active_preview_is_wall_placeable():
		var gizmo_hit := _raycast_from_mouse(mouse_position, GIZMO_COLLISION_LAYER)
		if not gizmo_hit.is_empty():
			var gizmo_collider := gizmo_hit.get("collider") as CollisionObject3D
			if gizmo_collider != null and gizmo_collider.has_meta("handle_id"):
				return String(gizmo_collider.get_meta("handle_id"))

	var preview_hit := _raycast_from_mouse(mouse_position, SimpleWoodChair.PREVIEW_PICK_LAYER)
	if not preview_hit.is_empty():
		return "move"
	if _try_get_active_surface_hit(mouse_position).get("valid", false):
		return "surface" if _active_preview_is_wall_placeable() else "plane"
	if _active_preview_is_support_surface_placeable():
		return ""
	if _active_preview_is_wall_placeable() and _try_get_wall_plane_hit(mouse_position, _active_surface_name).get("valid", false):
		return "surface"
	if _active_preview_is_ceiling_placeable() and _try_get_ceiling_hit(mouse_position).get("valid", false):
		return "plane"
	if _try_get_floor_hit(mouse_position).get("valid", false):
		return "plane"

	return ""

func _has_camera_conflicting_placement_target(mouse_position: Vector2) -> bool:
	match _pick_interaction_target(mouse_position):
		"move", "axis_x", "axis_z", "rotate":
			return true
		_:
			return false

func _pick_placeable_item(mouse_position: Vector2) -> SimpleWoodChair:
	if _is_pointer_over_placement_ui():
		return null

	var hit := _raycast_from_mouse(mouse_position, SimpleWoodChair.COLLISION_LAYER)
	if hit.is_empty():
		return null

	return hit.get("collider") as SimpleWoodChair

func _begin_drag(mode: String, mouse_position: Vector2) -> void:
	_drag_mode = mode
	_drag_start_position = _preview_item.global_position
	_drag_start_rotation_y = _preview_item.rotation.y
	_drag_start_basis = _preview_item.global_transform.basis
	_drag_rotation_start_angle = _get_active_plane_angle_around_preview(mouse_position)
	_hover_target = mode
	_update_gizmo_hover_state()

func _update_drag(mouse_position: Vector2) -> void:
	match _drag_mode:
		"move":
			var free_hit := _try_get_active_surface_hit(mouse_position)
			if free_hit.get("valid", false):
				_apply_preview_surface_hit(free_hit)
		"axis_x":
			if _active_preview_is_wall_placeable():
				return
			var x_hit := _try_get_active_planar_hit(mouse_position)
			if x_hit.get("valid", false):
				_set_preview_position(_project_point_onto_drag_axis(x_hit["position"] as Vector3, "axis_x"))
		"axis_z":
			if _active_preview_is_wall_placeable():
				return
			var z_hit := _try_get_active_planar_hit(mouse_position)
			if z_hit.get("valid", false):
				_set_preview_position(_project_point_onto_drag_axis(z_hit["position"] as Vector3, "axis_z"))
		"rotate":
			if _active_preview_is_wall_placeable():
				return
			var current_angle := _get_active_plane_angle_around_preview(mouse_position)
			var delta_angle := wrapf(current_angle - _drag_rotation_start_angle, -PI, PI)
			var rotation_steps: float = round(delta_angle / ROTATION_SNAP_STEP)
			_preview_item.rotation.y = _drag_start_rotation_y + rotation_steps * ROTATION_SNAP_STEP
			_refresh_preview_validity()

func _end_drag() -> void:
	_drag_mode = ""
	_hover_target = _pick_interaction_target(get_viewport().get_mouse_position())
	_update_gizmo_hover_state()

func _set_preview_position(target_position: Vector3) -> void:
	if _active_preview_is_wall_placeable():
		_preview_item.global_position = _snap_wall_position(target_position)
		_preview_item.rotation.y = RoomConstants.get_wall_rotation(_active_surface_name) + _preview_item.get_wall_rotation_offset()
		_sync_room_wall_openings()
	elif _active_preview_is_ceiling_placeable():
		_preview_item.global_position = _snap_ceiling_position(target_position)
	elif _active_preview_is_support_surface_placeable():
		var support_surface := _get_active_support_surface_data()
		if _active_support_host != null and not support_surface.is_empty():
			if _preview_item.get_parent() != _active_support_host:
				_preview_item.reparent(_active_support_host, true)
			_preview_item.position = _snap_support_surface_local_position(_active_support_host, support_surface, target_position)
	else:
		_preview_item.global_position = _snap_position_to_grid(target_position)
	_refresh_preview_validity()

func _apply_preview_surface_hit(hit: Dictionary) -> void:
	if not hit.get("valid", false):
		return
	_active_surface_name = String(hit.get("surface_name", _active_surface_name))
	if _active_preview_is_support_surface_placeable():
		var host := hit.get("host") as SimpleWoodChair
		var surface_id := String(hit.get("surface_id", DEFAULT_SUPPORT_SURFACE_ID))
		if host == null:
			return
		_active_support_host = host
		_active_support_surface_id = surface_id
		if _preview_item.get_parent() != host:
			_preview_item.reparent(host, true)
		_set_preview_position(hit["position"] as Vector3)
		return
	_set_preview_position(hit["position"] as Vector3)

func _get_active_support_surface_data() -> Dictionary:
	return _get_support_surface_data(_active_support_host, _active_support_surface_id)

func _get_support_surface_data(host: SimpleWoodChair, surface_id: String) -> Dictionary:
	if host == null:
		return {}
	for raw_surface in host.get_support_surfaces():
		if typeof(raw_surface) != TYPE_DICTIONARY:
			continue
		var surface_data := raw_surface as Dictionary
		if String(surface_data.get("id", DEFAULT_SUPPORT_SURFACE_ID)) == surface_id:
			return surface_data
	return {}

func _get_support_surface_hosts() -> Array[SimpleWoodChair]:
	var hosts: Array[SimpleWoodChair] = []
	for placeable in _get_placeables_under_root():
		if placeable == null or placeable == _preview_item:
			continue
		if not placeable.can_host_surface_items():
			continue
		if _is_placeable_effectively_cutaway(placeable):
			continue
		hosts.append(placeable)
	return hosts

func _get_rotated_planar_half_extents(half_extents: Vector2, rotation_y: float) -> Vector2:
	var cosine := absf(cos(rotation_y))
	var sine := absf(sin(rotation_y))
	return Vector2(
		cosine * half_extents.x + sine * half_extents.y,
		sine * half_extents.x + cosine * half_extents.y
	)

func _snap_support_surface_local_position(host: SimpleWoodChair, support_surface: Dictionary, target_world_position: Vector3) -> Vector3:
	if host == null or support_surface.is_empty() or _preview_item == null:
		return Vector3.ZERO

	var center_offset := support_surface.get("center_offset", Vector3.ZERO) as Vector3
	var half_extents := support_surface.get("half_extents", Vector2.ZERO) as Vector2
	var local_target := host.to_local(target_world_position)
	var local_offset := local_target - center_offset
	var item_half_extents := _get_rotated_planar_half_extents(_preview_item.get_footprint_half_extents(), _preview_item.rotation.y)
	var available_x := maxf(0.0, half_extents.x - item_half_extents.x)
	var available_z := maxf(0.0, half_extents.y - item_half_extents.y)
	var snapped_x := clampf(round(local_offset.x / SUPPORT_SURFACE_SNAP_SIZE) * SUPPORT_SURFACE_SNAP_SIZE, -available_x, available_x)
	var snapped_z := clampf(round(local_offset.z / SUPPORT_SURFACE_SNAP_SIZE) * SUPPORT_SURFACE_SNAP_SIZE, -available_z, available_z)
	return Vector3(
		center_offset.x + snapped_x,
		center_offset.y + SUPPORT_SURFACE_CLEARANCE,
		center_offset.z + snapped_z
	)

func _try_get_support_surface_hit(mouse_position: Vector2) -> Dictionary:
	var camera := _get_active_camera()
	if camera == null or _preview_item == null:
		return {"valid": false}

	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)
	if absf(ray_normal.y) <= 0.0001:
		return {"valid": false}

	var best_hit := {"valid": false}
	var best_distance := INF
	for host in _get_support_surface_hosts():
		for raw_surface in host.get_support_surfaces():
			if typeof(raw_surface) != TYPE_DICTIONARY:
				continue
			var support_surface := raw_surface as Dictionary
			var center_offset := support_surface.get("center_offset", Vector3.ZERO) as Vector3
			var half_extents := support_surface.get("half_extents", Vector2.ZERO) as Vector2
			if half_extents.x <= 0.001 or half_extents.y <= 0.001:
				continue

			var surface_center := host.global_transform * center_offset
			var hit_distance: float = (surface_center.y - ray_origin.y) / ray_normal.y
			if hit_distance <= 0.0 or hit_distance >= best_distance:
				continue

			var hit_position := ray_origin + ray_normal * hit_distance
			var local_hit := host.to_local(hit_position) - center_offset
			if absf(local_hit.x) > half_extents.x + 0.02:
				continue
			if absf(local_hit.z) > half_extents.y + 0.02:
				continue

			best_distance = hit_distance
			best_hit = {
				"valid": true,
				"surface_name": RoomConstants.MOUNT_SURFACE,
				"distance": hit_distance,
				"position": hit_position,
				"host": host,
				"surface_id": String(support_surface.get("id", DEFAULT_SUPPORT_SURFACE_ID)),
			}
	return best_hit

func _find_nearest_support_surface_hit() -> Dictionary:
	var camera := _get_active_camera()
	if camera == null or _preview_item == null:
		return {"valid": false}

	var best_hit := {"valid": false}
	var best_score := INF
	for host in _get_support_surface_hosts():
		for raw_surface in host.get_support_surfaces():
			if typeof(raw_surface) != TYPE_DICTIONARY:
				continue
			var support_surface := raw_surface as Dictionary
			var center_offset := support_surface.get("center_offset", Vector3.ZERO) as Vector3
			var half_extents := support_surface.get("half_extents", Vector2.ZERO) as Vector2
			if half_extents.x <= 0.001 or half_extents.y <= 0.001:
				continue

			var surface_center := host.global_transform * center_offset
			if camera.is_position_behind(surface_center):
				continue

			var snapped_local := _snap_support_surface_local_position(host, support_surface, surface_center)
			var snapped_world := host.to_global(snapped_local)
			var camera_distance := camera.global_position.distance_squared_to(snapped_world)
			if camera_distance >= best_score:
				continue

			best_score = camera_distance
			best_hit = {
				"valid": true,
				"surface_name": RoomConstants.MOUNT_SURFACE,
				"distance": sqrt(camera_distance),
				"position": snapped_world,
				"host": host,
				"surface_id": String(support_surface.get("id", DEFAULT_SUPPORT_SURFACE_ID)),
			}
	return best_hit

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
	constrained_position.y = _get_active_planar_y()
	return constrained_position

func _get_drag_axis_direction(axis_mode: String) -> Vector3:
	if _preview_item == null:
		return Vector3.ZERO

	var axis_direction := _drag_start_basis.x if axis_mode == "axis_x" else _drag_start_basis.z
	axis_direction.y = 0.0
	if axis_direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	return axis_direction.normalized()

func _snap_position_to_grid(target_position: Vector3) -> Vector3:
	return PlacementSurfaceQueries.snap_position_to_grid(_room_shell, target_position, GRID_SIZE)

func _snap_ceiling_position(target_position: Vector3) -> Vector3:
	return PlacementSurfaceQueries.snap_ceiling_position(_room_shell, target_position, GRID_SIZE)

func _snap_planar_position(target_position: Vector3, surface_name: String) -> Vector3:
	return _snap_ceiling_position(target_position) if surface_name == RoomConstants.CEILING_SURFACE else _snap_position_to_grid(target_position)

func _snap_wall_position(target_position: Vector3) -> Vector3:
	return PlacementSurfaceQueries.snap_wall_position(_room_shell, _active_surface_name, target_position, _get_wall_snap_size(), _preview_item)

func _try_get_active_surface_hit(mouse_position: Vector2) -> Dictionary:
	if _preview_item == null:
		return {"valid": false}
	if _active_preview_is_wall_placeable():
		var wall_hit := _try_get_best_supported_wall_hit(mouse_position)
		if wall_hit.get("valid", false):
			_active_surface_name = String(wall_hit.get("surface_name", _active_surface_name))
		return wall_hit
	if _active_preview_is_ceiling_placeable():
		var ceiling_hit := _try_get_ceiling_hit(mouse_position)
		if ceiling_hit.get("valid", false):
			ceiling_hit["surface_name"] = RoomConstants.CEILING_SURFACE
		return ceiling_hit
	if _active_preview_is_support_surface_placeable():
		return _try_get_support_surface_hit(mouse_position)

	var floor_hit := _try_get_floor_hit(mouse_position)
	if floor_hit.get("valid", false):
		floor_hit["surface_name"] = RoomConstants.FLOOR_SURFACE
	return floor_hit

func _get_wall_snap_size() -> float:
	return PlacementSurfaceQueries.get_wall_snap_size(_preview_item, GRID_SIZE, WALL_SNAP_SIZE)

func _try_get_best_supported_wall_hit(mouse_position: Vector2) -> Dictionary:
	var camera := _get_active_camera()
	return PlacementSurfaceQueries.try_get_best_supported_wall_hit(camera, _room_shell, _preview_item, mouse_position)

func _try_get_wall_plane_hit(mouse_position: Vector2, surface_name: String) -> Dictionary:
	var camera := _get_active_camera()
	return PlacementSurfaceQueries.try_get_wall_plane_hit(camera, _room_shell, mouse_position, surface_name)

func _try_get_floor_hit(mouse_position: Vector2) -> Dictionary:
	var camera := _get_active_camera()
	return PlacementSurfaceQueries.try_get_floor_hit(camera, _room_shell, mouse_position)

func _try_get_ceiling_hit(mouse_position: Vector2) -> Dictionary:
	var camera := _get_active_camera()
	return PlacementSurfaceQueries.try_get_ceiling_hit(camera, _room_shell, mouse_position)

func _try_get_active_planar_hit(mouse_position: Vector2) -> Dictionary:
	if _active_preview_is_support_surface_placeable():
		return _try_get_support_surface_hit(mouse_position)
	return _try_get_ceiling_hit(mouse_position) if _active_preview_is_ceiling_placeable() else _try_get_floor_hit(mouse_position)

func _raycast_from_mouse(mouse_position: Vector2, collision_mask: int) -> Dictionary:
	var camera := _get_active_camera()
	var space_state := get_world_3d().direct_space_state
	return PlacementSurfaceQueries.raycast_from_mouse(space_state, camera, mouse_position, collision_mask)

func _get_floor_angle_around_preview(mouse_position: Vector2) -> float:
	var camera := _get_active_camera()
	return PlacementSurfaceQueries.get_floor_angle_around_preview(camera, _room_shell, _preview_item, mouse_position)

func _get_active_plane_angle_around_preview(mouse_position: Vector2) -> float:
	if _active_preview_is_support_surface_placeable():
		var support_hit := _try_get_support_surface_hit(mouse_position)
		if not support_hit.get("valid", false):
			return 0.0
		var support_hit_position := support_hit["position"] as Vector3
		var support_offset := Vector2(
			support_hit_position.x - _preview_item.global_position.x,
			support_hit_position.z - _preview_item.global_position.z
		)
		return 0.0 if support_offset.length_squared() <= 0.0001 else support_offset.angle()
	var camera := _get_active_camera()
	var surface_name := RoomConstants.CEILING_SURFACE if _active_preview_is_ceiling_placeable() else RoomConstants.FLOOR_SURFACE
	return PlacementSurfaceQueries.get_planar_angle_around_preview(camera, _room_shell, _preview_item, mouse_position, surface_name)

func _get_active_planar_y() -> float:
	if _room_shell == null:
		return 0.0
	if _active_preview_is_support_surface_placeable():
		return _preview_item.global_position.y if _preview_item != null else 0.0
	return _room_shell.get_ceiling_y() if _active_preview_is_ceiling_placeable() else _room_shell.get_floor_y()

func _get_popup_anchor_offset_y() -> float:
	if _preview_item == null:
		return 0.0
	if _active_preview_is_wall_placeable():
		return _preview_item.get_collision_size().y * 0.5 + 0.38
	if _active_preview_is_ceiling_placeable():
		return _preview_item.get_collision_size().y * 0.5 + 0.34
	return _preview_item.get_collision_size().y + 0.72

func _get_popup_screen_gap() -> float:
	if _active_preview_is_ceiling_placeable():
		return 18.0
	if _active_preview_is_wall_placeable():
		return 16.0
	if _active_preview_is_support_surface_placeable():
		return 14.0
	return 12.0

func _get_gizmo_offset_y() -> float:
	if _preview_item == null:
		return 0.0
	var base_offset := clampf(_preview_item.get_collision_size().y * 0.5 + 0.12, 0.88, 1.24)
	return -base_offset if _active_preview_is_ceiling_placeable() else base_offset

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

	var duplicate_enabled := _is_edit_session() and _placement_valid and int(_item_stock.get(_active_item_id, 0)) > 0
	var delete_enabled := _is_edit_session()
	var panel_bg: Color
	var panel_border: Color
	var status_color: Color
	var popup_status_text := "Ready"
	var popup_hint_text := "LMB drag  |  Q/E rotate"
	if _placement_valid:
		panel_bg = PlacementUiStyles.COLOR_PANEL_SOFT
		panel_border = PlacementUiStyles.COLOR_SUCCESS_BORDER
		status_color = PlacementUiStyles.COLOR_TEXT
	else:
		panel_bg = PlacementUiStyles.COLOR_DANGER.lerp(PlacementUiStyles.COLOR_PANEL_SOFT, 0.42)
		panel_border = PlacementUiStyles.COLOR_DANGER_BORDER
		status_color = PlacementUiStyles.COLOR_TEXT
		popup_status_text = _placement_issue_text
		popup_hint_text = "Move to a clear cell"

	var confirm_text := "Move" if _is_edit_session() else "Place"
	var confirm_tooltip := "Confirm the current %s" % ("move" if _is_edit_session() else "placement")
	var cancel_tooltip := "Cancel the current action"

	if _placement_valid:
		if _active_preview_is_wall_placeable():
			popup_hint_text = "Drag on wall  |  Double-click to edit" if not _is_edit_session() else "Drag on wall  |  Duplicate/Delete"
		elif _active_preview_is_ceiling_placeable():
			popup_hint_text = "Drag on ceiling  |  Q/E rotate" if not _is_edit_session() else "Drag on ceiling  |  Q/E rotate  |  Duplicate/Delete"
		elif _active_preview_is_support_surface_placeable():
			popup_hint_text = "Drag on furniture top  |  Q/E rotate" if not _is_edit_session() else "Drag on furniture top  |  Q/E rotate  |  Duplicate/Delete"
		else:
			popup_hint_text = "LMB drag  |  Q/E rotate" if not _is_edit_session() else "LMB drag  |  Q/E rotate  |  Duplicate/Delete"

	var popup_visual_signature := JSON.stringify({
		"valid": _placement_valid,
		"status": popup_status_text,
		"hint": popup_hint_text,
		"confirm": confirm_text,
		"edit": _is_edit_session(),
		"duplicate_enabled": duplicate_enabled,
		"delete_enabled": delete_enabled,
		"wall": _active_preview_is_wall_placeable(),
		"ceiling": _active_preview_is_ceiling_placeable(),
		"support_surface": _active_preview_is_support_surface_placeable(),
	})
	if popup_visual_signature == _popup_visual_signature:
		return

	_popup_visual_signature = popup_visual_signature
	_popup_panel.add_theme_stylebox_override("panel", PlacementUiStyles.make_panel_style(panel_bg, panel_border))
	if _popup_status_label != null:
		_popup_status_label.text = popup_status_text
		_popup_status_label.add_theme_color_override("font_color", status_color)
	if _popup_hint_label != null:
		_popup_hint_label.text = popup_hint_text
		_popup_hint_label.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT_MUTED)
	if _confirm_button != null:
		_confirm_button.text = confirm_text
		_confirm_button.tooltip_text = confirm_tooltip
	if _cancel_button != null:
		_cancel_button.text = "Cancel"
		_cancel_button.tooltip_text = cancel_tooltip
	if _popup_edit_row != null:
		_popup_edit_row.visible = _is_edit_session()
	if _duplicate_button != null:
		_duplicate_button.disabled = not duplicate_enabled
		_duplicate_button.tooltip_text = "Create a second copy if stock remains"
	if _delete_button != null:
		_delete_button.disabled = not delete_enabled
		_delete_button.tooltip_text = "Delete this placed item and return its stock"

	PlacementUiStyles.apply_button_style(
		_confirm_button,
		PlacementUiStyles.COLOR_SUCCESS,
		PlacementUiStyles.COLOR_SUCCESS_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)
	PlacementUiStyles.apply_button_style(
		_cancel_button,
		PlacementUiStyles.COLOR_PANEL_ALT,
		PlacementUiStyles.COLOR_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)
	PlacementUiStyles.apply_button_style(
		_duplicate_button,
		PlacementUiStyles.COLOR_ACCENT_DARK,
		PlacementUiStyles.COLOR_ACCENT_BRIGHT,
		PlacementUiStyles.COLOR_TEXT
	)
	PlacementUiStyles.apply_button_style(
		_delete_button,
		PlacementUiStyles.COLOR_DANGER,
		PlacementUiStyles.COLOR_DANGER_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)

func _get_placeables_under_root() -> Array[SimpleWoodChair]:
	var placeables: Array[SimpleWoodChair] = []
	if _placed_items_root == null:
		return placeables
	_collect_placeables_recursive(_placed_items_root, placeables)
	return placeables

func _collect_placeables_recursive(node: Node, output: Array[SimpleWoodChair]) -> void:
	for child in node.get_children():
		var placeable := child as SimpleWoodChair
		if placeable != null:
			output.append(placeable)
			_collect_placeables_recursive(placeable, output)
			continue
		_collect_placeables_recursive(child, output)

func _collect_placeable_tree(root_placeable: SimpleWoodChair) -> Array[SimpleWoodChair]:
	var placeables: Array[SimpleWoodChair] = []
	if root_placeable == null:
		return placeables
	placeables.append(root_placeable)
	_collect_placeables_recursive(root_placeable, placeables)
	return placeables

func _refund_stock_for_placeable_tree(root_placeable: SimpleWoodChair) -> void:
	for placeable in _collect_placeable_tree(root_placeable):
		var item_id := _resolve_item_id_for_placeable(placeable)
		if item_id.is_empty():
			continue
		_item_stock[item_id] = int(_item_stock.get(item_id, 0)) + 1

func _is_placeable_effectively_cutaway(placeable: SimpleWoodChair) -> bool:
	var current: Node = placeable
	while current != null and current != _placed_items_root:
		var current_placeable := current as SimpleWoodChair
		if current_placeable != null:
			if _is_ceiling_placeable(current_placeable) and _ceiling_surface_cutaway:
				return true
			if _is_wall_placeable(current_placeable):
				var placement_surface := String(current_placeable.get_meta("placement_surface")) if current_placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
				if _placement_active and current_placeable == _preview_item and _active_preview_is_wall_placeable():
					placement_surface = _active_surface_name
				if bool(_wall_surface_cutaway_states.get(placement_surface, false)):
					return true
		current = current.get_parent()
	return false

func _build_wall_openings_signature(openings_by_surface: Dictionary) -> String:
	var normalized: Array = []
	for surface_name in RoomConstants.WALL_SURFACES:
		normalized.append(openings_by_surface.get(surface_name, []))
	return JSON.stringify(normalized)

func _notify_room_layout_visuals_changed() -> void:
	room_layout_visuals_changed.emit()

func _cleanup_stray_placeable_artifacts() -> void:
	var stray_placeables: Array[SimpleWoodChair] = []
	_collect_stray_placeables_recursive(self, stray_placeables)
	for placeable in stray_placeables:
		if placeable == null or not is_instance_valid(placeable):
			continue
		if placeable == _preview_item:
			continue
		if _placed_items_root != null and _placed_items_root.is_ancestor_of(placeable):
			continue
		if placeable.get_parent() != null:
			placeable.get_parent().remove_child(placeable)
		placeable.queue_free()

func _collect_stray_placeables_recursive(node: Node, output: Array[SimpleWoodChair]) -> void:
	for child in node.get_children():
		var placeable := child as SimpleWoodChair
		if placeable != null:
			output.append(placeable)
			continue
		_collect_stray_placeables_recursive(child, output)
