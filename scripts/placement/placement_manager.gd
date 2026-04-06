@tool
class_name PlacementManager
extends Node3D

signal room_layout_visuals_changed

const RoomConstants := preload("res://scripts/room/room_constants.gd")
const PlacementInventoryCatalog := preload("res://scripts/placement/placement_inventory_catalog.gd")
const PlacementGizmoFactory := preload("res://scripts/placement/placement_gizmo_factory.gd")
const PlacementBrowserCard := preload("res://scripts/placement/placement_browser_card.gd")
const PlacementRoomLayoutStore := preload("res://scripts/placement/placement_room_layout_store.gd")
const PlacementSurfaceQueries := preload("res://scripts/placement/placement_surface_queries.gd")
const PlacementUiStyles := preload("res://scripts/placement/placement_ui_styles.gd")
const PlacementValidator := preload("res://scripts/placement/placement_validator.gd")
const GRID_SIZE := 1.0
const UI_MARGIN := Vector2(16.0, 140.0)
const POPUP_MARGIN := 10.0
const GIZMO_RING_RADIUS := 0.6
const ROTATION_SNAP_STEP := PI * 0.5
const GIZMO_COLLISION_LAYER := 1 << 4
const GIZMO_DISTANCE_SCALE := 0.08
const GIZMO_MIN_SCALE := 0.92
const GIZMO_MAX_SCALE := 1.34
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
var _selected_shop_category := ""
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

var _room_shell: RoomShell
var _room_camera_controller: Node
var _player: Node
var _placed_items_root: Node3D
var _grid_overlay: MeshInstance3D
var _gizmo_root: Node3D
var _preview_item: SimpleWoodChair
var _placement_query_shape := BoxShape3D.new()
var _gizmo_handle_nodes := {}
var _gizmo_handle_materials := {}
var _gizmo_handle_base_colors := {}

var _ui_layer: CanvasLayer
var _ui_root: Control
var _inventory_panel: PanelContainer
var _mode_buttons: Dictionary = {}
var _browser_mode_buttons: Dictionary = {}
var _shop_category_buttons: Dictionary = {}
var _floor_style_buttons: Dictionary = {}
var _panel_title_label: Label
var _mode_label: Label
var _browser_section_label: Label
var _status_label: Label
var _floor_style_label: Label
var _browser_scroll: ScrollContainer
var _browser_grid: GridContainer
var _shop_category_scroll: ScrollContainer
var _shop_category_flow: HFlowContainer
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
var _wall_surface_cutaway_states: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
}

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
	_selected_shop_category = _shop_categories[0] if not _shop_categories.is_empty() else ""
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
				"floor", "surface":
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
	if event == null:
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

	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.position = UI_MARGIN
	_inventory_panel.custom_minimum_size = Vector2(388.0, 0.0)
	_inventory_panel.add_theme_stylebox_override(
		"panel",
		PlacementUiStyles.make_panel_style(Color(0.14, 0.18, 0.21, 0.9), Color(0.28, 0.34, 0.4, 0.96))
	)
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

	_panel_title_label = Label.new()
	_panel_title_label.text = "Build Browser"
	layout.add_child(_panel_title_label)

	_mode_label = Label.new()
	_mode_label.text = "Mode"
	layout.add_child(_mode_label)

	var mode_button_row := HBoxContainer.new()
	mode_button_row.add_theme_constant_override("separation", 8)
	layout.add_child(mode_button_row)

	_add_mode_button(mode_button_row, "Build", EDITOR_MODE_BUILD)
	_add_mode_button(mode_button_row, "Edit", EDITOR_MODE_EDIT)

	var mode_separator := HSeparator.new()
	layout.add_child(mode_separator)

	_browser_section_label = Label.new()
	_browser_section_label.text = "Browser"
	layout.add_child(_browser_section_label)

	var browser_mode_row := HBoxContainer.new()
	browser_mode_row.add_theme_constant_override("separation", 8)
	layout.add_child(browser_mode_row)

	_add_browser_mode_button(browser_mode_row, "Inventory", BROWSER_MODE_INVENTORY)
	_add_browser_mode_button(browser_mode_row, "Shop", BROWSER_MODE_SHOP)

	_shop_category_scroll = ScrollContainer.new()
	_shop_category_scroll.custom_minimum_size = Vector2(0.0, 42.0)
	_shop_category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_shop_category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(_shop_category_scroll)

	_shop_category_flow = HFlowContainer.new()
	_shop_category_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_category_flow.add_theme_constant_override("h_separation", 6)
	_shop_category_flow.add_theme_constant_override("v_separation", 6)
	_shop_category_scroll.add_child(_shop_category_flow)

	_browser_scroll = ScrollContainer.new()
	_browser_scroll.custom_minimum_size = Vector2(0.0, 420.0)
	_browser_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browser_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_browser_scroll)

	_browser_grid = GridContainer.new()
	_browser_grid.columns = 2
	_browser_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browser_grid.add_theme_constant_override("h_separation", 10)
	_browser_grid.add_theme_constant_override("v_separation", 10)
	_browser_scroll.add_child(_browser_grid)

	var floor_separator := HSeparator.new()
	layout.add_child(floor_separator)

	_floor_style_label = Label.new()
	_floor_style_label.text = "Floor Finish"
	layout.add_child(_floor_style_label)

	var floor_button_row := HBoxContainer.new()
	floor_button_row.add_theme_constant_override("separation", 8)
	layout.add_child(floor_button_row)

	_add_floor_style_button(floor_button_row, "Brown Mat", FLOOR_STYLE_COZY_BROWN)
	_add_floor_style_button(floor_button_row, "Checkerboard", FLOOR_STYLE_CHECKERBOARD)

	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(260.0, 84.0)
	layout.add_child(_status_label)

	_grid_toggle_button = Button.new()
	_grid_toggle_button.custom_minimum_size = Vector2(260.0, 36.0)
	_grid_toggle_button.pressed.connect(_on_grid_toggle_button_pressed)
	layout.add_child(_grid_toggle_button)

	var persistence_separator := HSeparator.new()
	layout.add_child(persistence_separator)

	var persistence_label := Label.new()
	persistence_label.text = "Room Layout"
	layout.add_child(persistence_label)

	var persistence_row := HBoxContainer.new()
	persistence_row.add_theme_constant_override("separation", 8)
	layout.add_child(persistence_row)

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

	_rebuild_shop_category_tabs()
	_rebuild_item_browser()
	_update_mode_ui()
	_update_browser_mode_ui()
	_update_popup_visuals()
	_update_floor_style_ui()

func _add_mode_button(parent: HBoxContainer, title_text: String, mode_id: String) -> void:
	var button := Button.new()
	button.text = title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(126.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_mode_button_pressed.bind(mode_id))
	parent.add_child(button)
	_mode_buttons[mode_id] = button

func _add_browser_mode_button(parent: HBoxContainer, title_text: String, mode_id: String) -> void:
	var button := Button.new()
	button.text = title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(126.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_browser_mode_button_pressed.bind(mode_id))
	parent.add_child(button)
	_browser_mode_buttons[mode_id] = button

func _rebuild_shop_category_tabs() -> void:
	if _shop_category_flow == null:
		return
	for child in _shop_category_flow.get_children():
		_shop_category_flow.remove_child(child)
		child.queue_free()
	_shop_category_buttons.clear()

	for category_name in _shop_categories:
		var button := Button.new()
		button.text = category_name
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(84.0, 30.0)
		button.pressed.connect(_on_shop_category_button_pressed.bind(category_name))
		_shop_category_flow.add_child(button)
		_shop_category_buttons[category_name] = button

func _rebuild_item_browser() -> void:
	if _browser_grid == null:
		return

	for child in _browser_grid.get_children():
		_browser_grid.remove_child(child)
		child.queue_free()

	var item_factory := Callable(self, "_create_item_instance_from_definition")
	for item_def in _get_visible_browser_item_defs():
		var item_id := String(item_def.get("id", ""))
		var card := PlacementBrowserCard.new()
		card.add_theme_stylebox_override(
			"panel",
			PlacementUiStyles.make_panel_style(Color(0.1, 0.13, 0.16, 0.92), Color(0.24, 0.34, 0.43, 0.96), 1, 12)
		)
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
	for item_def in _inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		if _browser_mode == BROWSER_MODE_INVENTORY:
			if int(_item_owned_totals.get(item_id, 0)) <= 0:
				continue
			visible_items.append(item_def)
			continue

		if not _selected_shop_category.is_empty() and String(item_def.get("category", "")) != _selected_shop_category:
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
	return item != null and item.get_placement_surface_kind() == RoomConstants.SURFACE_DECOR

func _active_preview_is_wall_placeable() -> bool:
	return _is_wall_placeable(_preview_item)

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
		for raw_item in raw_items:
			if typeof(raw_item) != TYPE_DICTIONARY:
				continue
			var item_entry: Dictionary = raw_item
			_instantiate_saved_item(item_entry)

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

func _instantiate_saved_item(item_entry: Dictionary) -> void:
	var item_id := String(item_entry.get("item_id", ""))
	if item_id.is_empty():
		return

	var placeable := _create_item_instance(item_id)
	if placeable == null:
		return

	var position := PlacementRoomLayoutStore.deserialize_vector3(item_entry.get("position", {}))
	var placement_surface := String(item_entry.get("placement_surface", RoomConstants.FLOOR_SURFACE))
	var rotation_y := float(item_entry.get("rotation_y", 0.0))
	if _is_wall_placeable(placeable) and RoomConstants.is_wall_surface(placement_surface):
		rotation_y = RoomConstants.get_wall_rotation(placement_surface) + placeable.get_wall_rotation_offset()
	var placement_transform := Transform3D(Basis.IDENTITY.rotated(Vector3.UP, rotation_y), position)

	var placed_count: int = int(_placed_item_counts.get(item_id, 0)) + 1
	_placed_item_counts[item_id] = placed_count
	_ensure_placeable_metadata(placeable, item_id)
	placeable.set_meta("placement_surface", placement_surface)
	placeable.name = "%s %d" % [_get_item_display_name(item_id), placed_count]
	_placed_items_root.add_child(placeable)
	placeable.global_transform = placement_transform
	placeable.set_preview_mode(false)
	_apply_cutaway_to_placeable(placeable)
	_item_stock[item_id] = maxi(0, int(_item_stock.get(item_id, 0)) - 1)

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

func _sync_room_wall_openings() -> bool:
	if _room_shell == null:
		return false

	var openings_by_surface: Dictionary = {
		RoomConstants.WALL_BACK: [],
		RoomConstants.WALL_LEFT: [],
		RoomConstants.WALL_FRONT: [],
		RoomConstants.WALL_RIGHT: [],
	}
	for child in _placed_items_root.get_children():
		var placeable := child as SimpleWoodChair
		if placeable == null:
			continue
		if not placeable.requires_wall_opening():
			continue

		var surface_name := String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
		if _placement_active and child == _preview_item and _active_preview_is_wall_placeable():
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

func clear_wall_surface_cutaways() -> void:
	for surface_name in _wall_surface_cutaway_states.keys():
		_wall_surface_cutaway_states[surface_name] = false
		_apply_cutaway_to_surface(String(surface_name))

func _apply_cutaway_to_surface(surface_name: String) -> void:
	if _placed_items_root == null:
		return

	for child in _placed_items_root.get_children():
		var placeable := child as SimpleWoodChair
		if placeable == null:
			continue
		if _placement_active and child == _preview_item:
			placeable.set_camera_cutaway(false)
			continue
		_apply_cutaway_to_placeable(placeable)

func _apply_cutaway_to_placeable(placeable: SimpleWoodChair) -> void:
	if placeable == null:
		return

	if placeable.get_placement_surface_kind() != RoomConstants.SURFACE_DECOR:
		placeable.set_camera_cutaway(false)
		return

	var placement_surface := String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
	placeable.set_camera_cutaway(bool(_wall_surface_cutaway_states.get(placement_surface, false)))

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
	if PlacementInventoryCatalog.uses_imported_scene_factory(item_def):
		return PlacementInventoryCatalog.create_imported_scene_instance(item_def)
	var item_script: Script = _get_item_script(item_def)
	if item_script == null:
		return null
	return item_script.new() as SimpleWoodChair

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
	if _is_wall_placeable(_preview_item):
		_active_surface_name = _preview_item.get_default_wall_surface()
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

func _ensure_placeable_metadata(placeable: SimpleWoodChair, item_id: String) -> void:
	if placeable == null or item_id.is_empty():
		return
	placeable.set_meta("item_id", item_id)
	placeable.set_meta("display_name", _get_item_display_name(item_id))

func _begin_edit_session(placeable: SimpleWoodChair) -> void:
	if placeable == null:
		return

	var item_id := _resolve_item_id_for_placeable(placeable)
	if item_id.is_empty():
		return

	_ensure_placeable_metadata(placeable, item_id)
	_editing_original_transform = placeable.global_transform
	_activate_preview_session(placeable, item_id, PLACEMENT_SESSION_EDIT, false)
	_active_surface_name = String(placeable.get_meta("placement_surface")) if placeable.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
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
	_preview_item.set_meta("placement_surface", _active_surface_name)
	_preview_item.name = "%s %d" % [_get_item_display_name(_active_item_id), placed_count]
	if _preview_item.get_parent() != _placed_items_root:
		_preview_item.reparent(_placed_items_root, true)
	_preview_item.set_preview_mode(false)
	_apply_cutaway_to_placeable(_preview_item)

func _commit_edit_preview_item() -> void:
	if _preview_item == null:
		return

	_ensure_placeable_metadata(_preview_item, _active_item_id)
	_preview_item.set_meta("placement_surface", _active_surface_name)
	_preview_item.set_preview_mode(false)
	_apply_cutaway_to_placeable(_preview_item)

func _restore_or_discard_active_preview(refund_stock: bool) -> void:
	if _preview_item == null:
		return

	match _placement_session:
		PLACEMENT_SESSION_EDIT:
			_preview_item.global_transform = _editing_original_transform
			_preview_item.set_preview_mode(false)
			_apply_cutaway_to_placeable(_preview_item)
		PLACEMENT_SESSION_NEW, PLACEMENT_SESSION_DUPLICATE:
			if refund_stock and not _active_item_id.is_empty():
				_item_stock[_active_item_id] = int(_item_stock.get(_active_item_id, 0)) + 1
			_preview_item.queue_free()

func _clear_active_session() -> void:
	_preview_item = null
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
		_preview_item.global_position = _snap_position_to_grid(candidate)
		_refresh_preview_validity()
		if _placement_valid:
			return _preview_item.global_position

	return _snap_position_to_grid(base_position)

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
	if _placement_active or _is_edit_mode() or item_def.is_empty():
		return
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
	if category_name == _selected_shop_category:
		return
	_selected_shop_category = category_name
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
	_commit_edit_preview_item()
	_item_stock[_active_item_id] = current_stock - 1
	add_child(duplicate_preview)
	_activate_preview_session(duplicate_preview, _active_item_id, PLACEMENT_SESSION_DUPLICATE, true)
	_active_surface_name = original_surface_name
	_sync_room_wall_openings()
	_preview_item.rotation.y = seed_rotation
	_preview_item.global_position = _find_duplicate_seed_position(seed_transform.origin)
	_refresh_preview_validity()

func _on_delete_button_pressed() -> void:
	if not _is_edit_session() or _preview_item == null:
		return

	if not _active_item_id.is_empty():
		_item_stock[_active_item_id] = int(_item_stock.get(_active_item_id, 0)) + 1
	_preview_item.free()
	_sync_room_wall_openings()
	_clear_active_session()
	_autosave_room_layout()
	_notify_room_layout_visuals_changed()

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
			_active_surface_name = String(hit.get("surface_name", _active_surface_name))
			target_position = hit["position"] as Vector3

	_set_preview_position(target_position)

func _rotate_preview(direction: int) -> void:
	if _preview_item == null or not _preview_item.supports_rotation():
		return

	_preview_item.rotate_y(deg_to_rad(90.0 * float(direction)))
	_refresh_preview_validity()

func _evaluate_preview_transform() -> Dictionary:
	return PlacementValidator.evaluate_preview_transform(
		get_world_3d(),
		_room_shell,
		_preview_item,
		_active_surface_name,
		_placement_query_shape
	)

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
	if _grid_toggle_button != null:
		if _is_edit_mode():
			_grid_toggle_button.text = "Grid Overlay: On (Edit Mode)"
			_grid_toggle_button.disabled = true
		else:
			_grid_toggle_button.text = "Grid Overlay: %s" % ("On" if grid_visible else "Off")
			_grid_toggle_button.disabled = false
	if _save_button != null:
		_save_button.disabled = _placement_active
	if _load_button != null:
		_load_button.disabled = _placement_active
	if _clear_room_button != null:
		_clear_room_button.disabled = _placement_active
	if _browser_section_label != null:
		if _browser_mode == BROWSER_MODE_SHOP:
			_browser_section_label.text = "Shop Catalog: %s" % (_selected_shop_category if not _selected_shop_category.is_empty() else "All")
		else:
			_browser_section_label.text = "Inventory (%d owned)" % _get_owned_item_type_count()

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
			Color(0.21, 0.27, 0.32, 0.98) if not is_selected else Color(0.22, 0.48, 0.34, 0.98),
			Color(0.38, 0.46, 0.54, 0.98) if not is_selected else Color(0.42, 0.98, 0.62, 0.98),
			Color(0.96, 0.98, 1.0, 1.0)
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
			Color(0.2, 0.28, 0.34, 0.98) if not is_selected else Color(0.24, 0.48, 0.62, 0.98),
			Color(0.4, 0.52, 0.62, 0.98) if not is_selected else Color(0.58, 0.86, 1.0, 0.98),
			Color(0.96, 0.98, 1.0, 1.0)
		)

	if _shop_category_scroll != null:
		_shop_category_scroll.visible = _browser_mode == BROWSER_MODE_SHOP

	for category_name in _shop_category_buttons.keys():
		var category_button := _shop_category_buttons.get(category_name) as Button
		if category_button == null:
			continue
		var is_selected_category := String(category_name) == _selected_shop_category
		category_button.button_pressed = is_selected_category
		category_button.disabled = _placement_active or (is_selected_category and _browser_mode == BROWSER_MODE_SHOP)
		PlacementUiStyles.apply_button_style(
			category_button,
			Color(0.19, 0.24, 0.28, 0.98) if not is_selected_category else Color(0.44, 0.34, 0.16, 0.98),
			Color(0.34, 0.42, 0.48, 0.98) if not is_selected_category else Color(0.96, 0.72, 0.38, 0.98),
			Color(0.95, 0.96, 0.98, 1.0)
		)

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
			Color(0.25, 0.21, 0.17, 0.98) if not is_selected else Color(0.52, 0.38, 0.18, 0.98),
			Color(0.42, 0.34, 0.26, 0.98) if not is_selected else Color(0.96, 0.76, 0.36, 0.98),
			Color(0.98, 0.97, 0.95, 1.0)
		)

	if _floor_style_label != null:
		_floor_style_label.text = "Floor Finish: %s" % ("Brown Mat" if current_style == FLOOR_STYLE_COZY_BROWN else "Checkerboard")

func _update_status_text() -> void:
	if _status_label == null:
		return

	if _placement_active:
		if _placement_valid:
			match _placement_session:
				PLACEMENT_SESSION_EDIT:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Editing %s on the wall.\nDrag across the wall to move it. Duplicate and Delete are available while editing." % _get_active_item_display_name()
					else:
						_status_label.text = "Editing %s.\nDrag, use the gizmo, or click another cell. Duplicate and Delete are available while editing." % _get_active_item_display_name()
				PLACEMENT_SESSION_DUPLICATE:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\nMove it to a new wall cell, then confirm to keep both copies." % _get_active_item_display_name()
					else:
						_status_label.text = "Ready to place a duplicate of %s.\nMove it to a new cell, then confirm to keep both copies." % _get_active_item_display_name()
				_:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Ready to place %s.\nClick or drag on a visible wall cell. This item cuts a window opening into the wall." % _get_active_item_display_name()
					else:
						_status_label.text = "Ready to place %s.\nLeft-drag the item, use the gizmo handles, or click a floor cell. Q/E still rotates." % _get_active_item_display_name()
		else:
			match _placement_issue_code:
				"bounds":
					if _active_preview_is_wall_placeable():
						_status_label.text = "Blocked by the wall edge.\nKeep %s fully inside the visible wall area before placing." % _get_active_item_display_name()
					else:
						_status_label.text = "Blocked by the room edge.\nKeep %s fully inside the floor before placing." % _get_active_item_display_name()
				"surface":
					_status_label.text = "Point at a visible wall.\nThis item can only be placed on an enabled wall surface."
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
	_grid_overlay.visible = _manual_grid_visible or _placement_active or _is_edit_mode()

func _refresh_grid_overlay_transform() -> void:
	if _grid_overlay == null or _room_shell == null:
		return

	_grid_overlay.global_position = _room_shell.global_position + Vector3(0.0, 0.03, 0.0)

func _update_popup_position() -> void:
	if _preview_item == null:
		return

	var camera := _get_active_camera()
	if camera == null:
		return

	var anchor_height: float = _preview_item.get_collision_size().y * (0.5 if _active_preview_is_wall_placeable() else 1.0)
	anchor_height += 0.38 if _active_preview_is_wall_placeable() else 0.72
	var anchor_world: Vector3 = _preview_item.global_position + Vector3(0.0, anchor_height, 0.0)
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
	if _preview_item == null:
		return

	var gizmo_height: float = clampf(_preview_item.get_collision_size().y * 0.5 + 0.12, 0.88, 1.24)
	_gizmo_root.global_position = _preview_item.global_position + Vector3(0.0, gizmo_height, 0.0)
	_gizmo_root.rotation.y = _preview_item.rotation.y
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
		return "surface" if _active_preview_is_wall_placeable() else "floor"
	if _active_preview_is_wall_placeable() and _try_get_wall_plane_hit(mouse_position, _active_surface_name).get("valid", false):
		return "surface"
	if _try_get_floor_hit(mouse_position).get("valid", false):
		return "floor"

	return ""

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
	_drag_rotation_start_angle = _get_floor_angle_around_preview(mouse_position)
	_hover_target = mode
	_update_gizmo_hover_state()

func _update_drag(mouse_position: Vector2) -> void:
	match _drag_mode:
		"move":
			var free_hit := _try_get_active_surface_hit(mouse_position)
			if free_hit.get("valid", false):
				_active_surface_name = String(free_hit.get("surface_name", _active_surface_name))
				_set_preview_position(free_hit["position"] as Vector3)
		"axis_x":
			if _active_preview_is_wall_placeable():
				return
			var x_hit := _try_get_floor_hit(mouse_position)
			if x_hit.get("valid", false):
				_set_preview_position(_project_point_onto_drag_axis(x_hit["position"] as Vector3, "axis_x"))
		"axis_z":
			if _active_preview_is_wall_placeable():
				return
			var z_hit := _try_get_floor_hit(mouse_position)
			if z_hit.get("valid", false):
				_set_preview_position(_project_point_onto_drag_axis(z_hit["position"] as Vector3, "axis_z"))
		"rotate":
			if _active_preview_is_wall_placeable():
				return
			var current_angle := _get_floor_angle_around_preview(mouse_position)
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
	else:
		_preview_item.global_position = _snap_position_to_grid(target_position)
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
	if _preview_item == null:
		return Vector3.ZERO

	var axis_basis := Basis(Vector3.UP, _drag_start_rotation_y)
	var axis_direction := axis_basis.x if axis_mode == "axis_x" else axis_basis.z
	axis_direction.y = 0.0
	if axis_direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	return axis_direction.normalized()

func _snap_position_to_grid(target_position: Vector3) -> Vector3:
	return PlacementSurfaceQueries.snap_position_to_grid(_room_shell, target_position, GRID_SIZE)

func _snap_wall_position(target_position: Vector3) -> Vector3:
	return PlacementSurfaceQueries.snap_wall_position(_room_shell, _active_surface_name, target_position, _get_wall_snap_size())

func _try_get_active_surface_hit(mouse_position: Vector2) -> Dictionary:
	if _preview_item == null:
		return {"valid": false}
	if _active_preview_is_wall_placeable():
		var wall_hit := _try_get_best_supported_wall_hit(mouse_position)
		if wall_hit.get("valid", false):
			_active_surface_name = String(wall_hit.get("surface_name", _active_surface_name))
		return wall_hit

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

func _raycast_from_mouse(mouse_position: Vector2, collision_mask: int) -> Dictionary:
	var camera := _get_active_camera()
	var space_state := get_world_3d().direct_space_state
	return PlacementSurfaceQueries.raycast_from_mouse(space_state, camera, mouse_position, collision_mask)

func _get_floor_angle_around_preview(mouse_position: Vector2) -> float:
	var camera := _get_active_camera()
	return PlacementSurfaceQueries.get_floor_angle_around_preview(camera, _room_shell, _preview_item, mouse_position)

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
		panel_bg = Color(0.08, 0.12, 0.1, 0.92)
		panel_border = Color(0.38, 0.92, 0.58, 0.96)
		status_color = Color(0.9, 1.0, 0.92, 1.0)
	else:
		panel_bg = Color(0.15, 0.09, 0.09, 0.94)
		panel_border = Color(0.98, 0.34, 0.34, 0.98)
		status_color = Color(1.0, 0.92, 0.92, 1.0)
		popup_status_text = _placement_issue_text
		popup_hint_text = "Move to a clear cell"

	var confirm_text := "Move" if _is_edit_session() else "Place"
	var confirm_tooltip := "Confirm the current %s" % ("move" if _is_edit_session() else "placement")
	var cancel_tooltip := "Cancel the current action"

	if _placement_valid:
		if _active_preview_is_wall_placeable():
			popup_hint_text = "Drag on wall  |  Double-click to edit" if not _is_edit_session() else "Drag on wall  |  Duplicate/Delete"
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
		_popup_hint_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.95, 0.84))
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
		Color(0.22, 0.58, 0.33, 0.98),
		Color(0.42, 0.98, 0.62, 0.98),
		Color(0.96, 1.0, 0.97, 1.0)
	)
	PlacementUiStyles.apply_button_style(
		_cancel_button,
		Color(0.24, 0.26, 0.31, 0.98),
		Color(0.54, 0.58, 0.68, 0.98),
		Color(0.97, 0.98, 1.0, 1.0)
	)
	PlacementUiStyles.apply_button_style(
		_duplicate_button,
		Color(0.24, 0.39, 0.62, 0.98),
		Color(0.48, 0.74, 1.0, 0.98),
		Color(0.96, 0.98, 1.0, 1.0)
	)
	PlacementUiStyles.apply_button_style(
		_delete_button,
		Color(0.55, 0.16, 0.16, 0.98),
		Color(0.96, 0.42, 0.42, 0.98),
		Color(1.0, 0.96, 0.96, 1.0)
	)

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
