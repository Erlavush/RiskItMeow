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
const SMOOTH_ROTATION_KEY_STEP := deg_to_rad(1.0)
const SMOOTH_ROTATION_PRECISION_STEP := deg_to_rad(0.01)
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
const PlacementPlaceablesRegistryScript := preload("res://scripts/placement/placement_placeables_registry.gd")
const PlacementRenderStateScript := preload("res://scripts/placement/placement_render_state.gd")
const PlacementWallOpeningSyncScript := preload("res://scripts/placement/placement_wall_opening_sync.gd")
const PlacementLayoutPersistenceScript := preload("res://scripts/placement/placement_layout_persistence.gd")
const PlacementBrowserUiControllerScript := preload("res://scripts/placement/placement_browser_ui_controller.gd")
const PlacementInteractionControllerScript := preload("res://scripts/placement/placement_interaction_controller.gd")

var _inventory_item_defs: Array[Dictionary] = PlacementInventoryCatalog.build_item_defs()

@export var room_shell_path: NodePath
@export var room_camera_controller_path: NodePath
@export var player_path: NodePath

var _item_stock: Dictionary = {}
var _item_owned_totals: Dictionary = {}
var _placed_item_counts: Dictionary = {}
var _shop_categories: Array[String] = []
var _grid_placement_enabled := true
var _rotation_snap_enabled := true
var _editor_mode := EDITOR_MODE_BUILD
var _browser_mode := BROWSER_MODE_INVENTORY
@warning_ignore("unused_private_class_variable")
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
var _preview_item: PlaceableItem
var _active_support_host: PlaceableItem
var _active_support_surface_id := DEFAULT_SUPPORT_SURFACE_ID
var _placement_query_shape := BoxShape3D.new()
var _gizmo_handle_nodes := {}
var _gizmo_handle_materials := {}
var _gizmo_handle_base_colors := {}

@warning_ignore("unused_private_class_variable")
var _ui_layer: CanvasLayer
@warning_ignore("unused_private_class_variable")
var _ui_root: Control
@warning_ignore("unused_private_class_variable")
var _browser_toggle_button: Button
@warning_ignore("unused_private_class_variable")
var _inventory_panel: PanelContainer
@warning_ignore("unused_private_class_variable")
var _browser_layout: VBoxContainer
var _mode_buttons: Dictionary = {}
var _browser_mode_buttons: Dictionary = {}
var _mount_filter_buttons: Dictionary = {}
var _floor_style_buttons: Dictionary = {}
@warning_ignore("unused_private_class_variable")
var _panel_title_label: Label
@warning_ignore("unused_private_class_variable")
var _mode_label: Label
@warning_ignore("unused_private_class_variable")
var _browser_section_label: Label
var _status_label: Label
@warning_ignore("unused_private_class_variable")
var _floor_style_label: Label
@warning_ignore("unused_private_class_variable")
var _browser_search_input: LineEdit
var _mount_filter_option: OptionButton
var _category_filter_option: OptionButton
var _browser_scroll: ScrollContainer
@warning_ignore("unused_private_class_variable")
var _browser_grid: GridContainer
var _tools_toggle_button: Button
var _tools_section: VBoxContainer
var _status_shell: PanelContainer
@warning_ignore("unused_private_class_variable")
var _grid_toggle_button: Button
@warning_ignore("unused_private_class_variable")
var _rotation_toggle_button: Button
@warning_ignore("unused_private_class_variable")
var _save_button: Button
@warning_ignore("unused_private_class_variable")
var _load_button: Button
@warning_ignore("unused_private_class_variable")
var _clear_room_button: Button
var _popup_panel: PanelContainer
var _popup_status_label: Label
var _popup_hint_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _duplicate_button: Button
var _delete_button: Button
var _popup_edit_row: HBoxContainer
@warning_ignore("unused_private_class_variable")
var _editor_preview_poll_time := 0.0
@warning_ignore("unused_private_class_variable")
var _editor_preview_layout_signature := ""
var _editor_default_floor_style := FLOOR_STYLE_COZY_BROWN
var _wall_openings_signature := ""
var _last_wall_preview_signature := ""
var _last_popup_signature := ""
var _last_gizmo_signature := ""
var _popup_visual_signature := ""
@warning_ignore("unused_private_class_variable")
var _browser_panel_tween: Tween
var _debug_world_active := false
var _wall_surface_cutaway_states: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
}
var _ceiling_surface_cutaway := false
var _placeables_registry = PlacementPlaceablesRegistryScript.new()
var _render_state = PlacementRenderStateScript.new()
var _wall_opening_sync = PlacementWallOpeningSyncScript.new()
var _layout_persistence = PlacementLayoutPersistenceScript.new()
var _browser_ui
var _interaction = PlacementInteractionControllerScript.new()
var _wall_openings_dirty := true

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

	_render_state.placement_manager = self
	_render_state.room_shell = _room_shell
	_render_state.placed_items_root = _placed_items_root
	_placeables_registry.placement_manager = self
	_placeables_registry.placed_items_root = _placed_items_root
	_wall_opening_sync.placement_manager = self
	_wall_opening_sync.room_shell = _room_shell
	_layout_persistence.placement_manager = self
	_layout_persistence.room_shell = _room_shell
	_layout_persistence.placed_items_root = _placed_items_root
	_interaction.placement_manager = self
	_interaction.room_shell = _room_shell
	_interaction.room_camera_controller = _room_camera_controller
	_interaction.player = _player
	_interaction.placed_items_root = _placed_items_root

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
	_interaction.process_frame(_delta)

func _input(event: InputEvent) -> void:
	_interaction.handle_input(event)

func _unhandled_input(event: InputEvent) -> void:
	_interaction.handle_unhandled_input(event)

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
	return _interaction.blocks_room_camera_input(event)

func _activate_browser_shortcut(next_editor_mode: String, next_browser_mode: String) -> void:
	_cancel_current_placement()
	_editor_mode = next_editor_mode
	_browser_mode = next_browser_mode
	_set_browser_open(true)
	_update_mode_ui()
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
	if _browser_ui == null:
		_browser_ui = PlacementBrowserUiControllerScript.new()
		_browser_ui.placement_manager = self
		_browser_ui.inventory_item_pressed.connect(_on_inventory_item_button_pressed)
		_browser_ui.shop_buy_requested.connect(_on_shop_buy_requested)
		_browser_ui.browser_mode_pressed.connect(_on_browser_mode_button_pressed)
		_browser_ui.mode_pressed.connect(_on_mode_button_pressed)
		_browser_ui.grid_toggle_pressed.connect(_set_grid_placement_enabled)
		_browser_ui.rotation_toggle_pressed.connect(_set_rotation_snap_enabled)
		_browser_ui.floor_style_pressed.connect(_on_floor_style_button_pressed)
		_browser_ui.save_pressed.connect(_on_save_button_pressed)
		_browser_ui.load_pressed.connect(_on_load_button_pressed)
		_browser_ui.clear_room_pressed.connect(_on_clear_room_button_pressed)
		_browser_ui.confirm_pressed.connect(_on_confirm_button_pressed)
		_browser_ui.cancel_pressed.connect(_on_cancel_button_pressed)
		_browser_ui.duplicate_pressed.connect(_on_duplicate_button_pressed)
		_browser_ui.delete_pressed.connect(_on_delete_button_pressed)
		add_child(_browser_ui)
	_browser_ui.build_ui()

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
	if _browser_ui != null:
		_browser_ui.update_browser_layout_metrics(false)

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

func _on_browser_scroll_gui_input(event: InputEvent) -> void:
	if _browser_scroll == null or event == null:
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if not mouse_button.pressed:
			return
		var scroll_bar := _browser_scroll.get_v_scroll_bar()
		if scroll_bar == null:
			return
		var step_size := maxf(scroll_bar.page * 0.28, 56.0)
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				scroll_bar.value = maxf(scroll_bar.min_value, scroll_bar.value - step_size)
				_browser_scroll.accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				scroll_bar.value = minf(scroll_bar.max_value - scroll_bar.page, scroll_bar.value + step_size)
				_browser_scroll.accept_event()

func _set_browser_open(is_open: bool, animate: bool = true) -> void:
	if _browser_ui != null:
		_browser_ui.set_browser_open(is_open, animate)

func _get_browser_top_margin(viewport_size: Vector2) -> float:
	return clampf(viewport_size.y * 0.09, 56.0, 72.0)

func _update_browser_layout_metrics(animate: bool = false) -> void:
	if _browser_ui != null:
		_browser_ui.update_browser_layout_metrics(animate)

func _queue_browser_layout_refresh() -> void:
	if _browser_ui != null:
		_browser_ui.queue_browser_layout_refresh()

func _refresh_browser_layout() -> void:
	if _browser_ui != null:
		_browser_ui.refresh_browser_layout()

func _update_browser_toggle_button_visual() -> void:
	if _browser_ui != null:
		_browser_ui.update_browser_toggle_button_visual()

func _update_section_toggle_ui() -> void:
	if _browser_ui != null:
		_browser_ui.update_section_toggle_ui()

func _get_selected_browser_category() -> String:
	return _browser_ui.get_selected_browser_category() if _browser_ui != null else (_selected_shop_category if _browser_mode == BROWSER_MODE_SHOP else _selected_inventory_category)

func _rebuild_shop_category_tabs() -> void:
	if _browser_ui != null:
		_browser_ui.rebuild_shop_category_tabs()

func _rebuild_item_browser() -> void:
	if _browser_ui != null:
		_browser_ui.rebuild_item_browser()

func _get_visible_browser_item_defs() -> Array[Dictionary]:
	return _browser_ui.get_visible_browser_item_defs() if _browser_ui != null else []

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

func _is_wall_placeable(item: PlaceableItem) -> bool:
	return PlacementSurfaceQueries.is_wall_placeable(item)

func _is_ceiling_placeable(item: PlaceableItem) -> bool:
	return PlacementSurfaceQueries.is_ceiling_placeable(item)

func _is_support_surface_placeable(item: PlaceableItem) -> bool:
	return PlacementSurfaceQueries.is_support_surface_placeable(item)

func _active_preview_is_wall_placeable() -> bool:
	return _is_wall_placeable(_preview_item)

func _active_preview_is_ceiling_placeable() -> bool:
	return _is_ceiling_placeable(_preview_item)

func _active_preview_is_support_surface_placeable() -> bool:
	return _is_support_surface_placeable(_preview_item)

func _can_rotate_preview() -> bool:
	return _preview_item != null and _preview_item.supports_rotation() and not _active_preview_is_wall_placeable()

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
	return _layout_persistence.save_layout()

func _load_room_layout_data() -> Dictionary:
	return _layout_persistence.load_layout_data()

func _build_default_owned_stock() -> Dictionary:
	return _layout_persistence.build_default_owned_stock()

func _build_owned_stock_from_layout(layout: Dictionary) -> Dictionary:
	return _layout_persistence.build_owned_stock_from_layout(layout)

func _apply_owned_stock_state(owned_stock: Dictionary) -> void:
	_layout_persistence.apply_owned_stock_state(owned_stock)

func _rebuild_room_from_layout(layout: Dictionary) -> void:
	_layout_persistence.rebuild_room_from_layout(layout)

func _load_room_layout() -> bool:
	return _layout_persistence.load_layout()

func _load_room_layout_on_startup() -> void:
	_layout_persistence.load_layout_on_startup()

func _process_editor_preview(delta: float) -> void:
	_layout_persistence.process_editor_preview(delta)

func _refresh_editor_preview_from_saved_layout(force: bool = false) -> void:
	_layout_persistence.refresh_editor_preview_from_saved_layout(force)

func _clear_editor_preview_layout() -> void:
	_layout_persistence.clear_editor_preview_layout()

func _instantiate_saved_item(item_entry: Dictionary, loaded_instances: Dictionary = {}) -> PlaceableItem:
	return _layout_persistence.instantiate_saved_item(item_entry, loaded_instances)

func _autosave_room_layout() -> void:
	_layout_persistence.autosave_room_layout()

func _clear_room(save_after_clear: bool = true) -> void:
	_layout_persistence.clear_room(save_after_clear)

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

func _invalidate_placeables_registry_structure() -> void:
	if _placeables_registry != null:
		_placeables_registry.invalidate_structure()
	_wall_openings_dirty = true

func _sync_room_wall_openings() -> bool:
	if not _wall_openings_dirty:
		return false
	var preview_item := _preview_item if is_instance_valid(_preview_item) else null
	var did_change: bool = _wall_opening_sync.sync(_placed_items_root, preview_item, _active_surface_name, _placement_active)
	_wall_openings_signature = _wall_opening_sync.wall_openings_signature
	_wall_openings_dirty = false
	return did_change

func _request_wall_openings_refresh() -> void:
	_wall_openings_dirty = true

func _on_placeable_structure_committed() -> void:
	_invalidate_placeables_registry_structure()
	_sync_room_wall_openings()
	_notify_room_layout_visuals_changed()

func _on_placeable_structure_removed() -> void:
	_invalidate_placeables_registry_structure()
	_sync_room_wall_openings()
	_notify_room_layout_visuals_changed()

func _on_placeable_batch_rebuilt() -> void:
	_invalidate_placeables_registry_structure()
	_sync_room_wall_openings()
	_update_floor_style_ui()
	_update_inventory_ui()
	_update_status_text()
	_notify_room_layout_visuals_changed()

func set_wall_surface_cutaway(surface_name: String, is_cutaway: bool) -> void:
	_render_state.set_wall_surface_cutaway(surface_name, is_cutaway)
	_wall_surface_cutaway_states = _render_state.wall_surface_cutaway_states.duplicate()

func set_ceiling_surface_cutaway(is_cutaway: bool) -> void:
	_render_state.set_ceiling_surface_cutaway(is_cutaway)
	_ceiling_surface_cutaway = _render_state.ceiling_surface_cutaway

func clear_wall_surface_cutaways() -> void:
	_render_state.clear_wall_surface_cutaways()
	_wall_surface_cutaway_states = _render_state.wall_surface_cutaway_states.duplicate()
	_ceiling_surface_cutaway = _render_state.ceiling_surface_cutaway

func _apply_cutaway_to_surface(_surface_name: String) -> void:
	_render_state.apply_cutaway_to_surface(_surface_name)

func _apply_cutaway_to_placeable(placeable: PlaceableItem) -> void:
	_render_state.apply_cutaway_to_placeable(placeable)

func _append_wall_opening_for_placeable(openings_by_surface: Dictionary, placeable: PlaceableItem, surface_name: String) -> void:
	_wall_opening_sync.append_wall_opening_for_placeable(openings_by_surface, placeable, surface_name)

func _create_item_instance(item_id: String) -> PlaceableItem:
	var item_def: Dictionary = _get_item_definition(item_id)
	if item_def.is_empty():
		return null
	return PlacementInventoryCatalog.create_item_instance(item_def) as PlaceableItem

func _create_item_instance_from_definition(item_def: Dictionary) -> PlaceableItem:
	if item_def.is_empty():
		return null
	return _create_item_instance(String(item_def.get("id", "")))

func _activate_preview_session(preview_item: PlaceableItem, item_id: String, session_kind: String, rename_preview: bool) -> void:
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
	_last_wall_preview_signature = ""
	_last_popup_signature = ""
	_last_gizmo_signature = ""
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

func _resolve_item_id_for_placeable(placeable: PlaceableItem) -> String:
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

func _get_placeable_instance_id(placeable: PlaceableItem) -> String:
	if placeable == null:
		return ""
	if placeable.has_meta("instance_id"):
		return String(placeable.get_meta("instance_id"))

	var instance_id := "placed_%d_%d" % [Time.get_ticks_usec(), _next_placeable_instance_serial]
	_next_placeable_instance_serial += 1
	placeable.set_meta("instance_id", instance_id)
	return instance_id

func _set_room_attachment_metadata(placeable: PlaceableItem, surface_name: String) -> void:
	if placeable == null:
		return
	placeable.set_meta("attachment_kind", RoomConstants.ATTACHMENT_ROOM)
	placeable.set_meta("placement_surface", surface_name)
	if placeable.has_meta("host_instance_id"):
		placeable.remove_meta("host_instance_id")
	if placeable.has_meta("host_surface_id"):
		placeable.remove_meta("host_surface_id")

func _set_support_attachment_metadata(placeable: PlaceableItem, host: PlaceableItem, surface_id: String) -> void:
	if placeable == null or host == null:
		return
	placeable.set_meta("attachment_kind", RoomConstants.ATTACHMENT_SUPPORT_SURFACE)
	placeable.set_meta("placement_surface", RoomConstants.MOUNT_SURFACE)
	placeable.set_meta("host_instance_id", _get_placeable_instance_id(host))
	placeable.set_meta("host_surface_id", surface_id if not surface_id.is_empty() else DEFAULT_SUPPORT_SURFACE_ID)

func _get_placeable_attachment_kind(placeable: PlaceableItem) -> String:
	if placeable == null:
		return RoomConstants.ATTACHMENT_ROOM
	if placeable.has_meta("attachment_kind"):
		return String(placeable.get_meta("attachment_kind"))
	return RoomConstants.ATTACHMENT_SUPPORT_SURFACE if placeable.get_parent() is PlaceableItem else RoomConstants.ATTACHMENT_ROOM

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

func _ensure_placeable_metadata(placeable: PlaceableItem, item_id: String, instance_id: String = "") -> void:
	if placeable == null or item_id.is_empty():
		return
	placeable.set_meta("item_id", item_id)
	placeable.set_meta("display_name", _get_item_display_name(item_id))
	if not instance_id.is_empty():
		placeable.set_meta("instance_id", instance_id)
	else:
		_get_placeable_instance_id(placeable)

func _begin_edit_session(placeable: PlaceableItem) -> void:
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
		_active_support_host = _editing_original_parent as PlaceableItem
		_active_support_surface_id = _editing_original_host_surface_id
	if _active_preview_is_wall_placeable() and RoomConstants.is_wall_surface(_active_surface_name):
		_preview_item.rotation.y = RoomConstants.get_wall_rotation(_active_surface_name) + _preview_item.get_wall_rotation_offset()
	_request_wall_openings_refresh()
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
	_on_placeable_structure_committed()

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
	_on_placeable_structure_committed()

func _restore_or_discard_active_preview(refund_stock: bool) -> void:
	if _preview_item == null:
		return

	match _placement_session:
		PLACEMENT_SESSION_EDIT:
			if _editing_original_parent != null and is_instance_valid(_editing_original_parent) and _preview_item.get_parent() != _editing_original_parent:
				_preview_item.reparent(_editing_original_parent, true)
			if _get_placeable_attachment_kind(_preview_item) == RoomConstants.ATTACHMENT_SUPPORT_SURFACE or _editing_original_parent is PlaceableItem:
				_preview_item.transform = _editing_original_local_transform
				var original_host := _editing_original_parent as PlaceableItem
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
			var preview_parent := _preview_item.get_parent()
			if preview_parent != null:
				preview_parent.remove_child(_preview_item)
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
	_last_wall_preview_signature = ""
	_last_popup_signature = ""
	_last_gizmo_signature = ""
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
	_set_grid_placement_enabled(not _grid_placement_enabled)

func _on_rotation_toggle_button_pressed() -> void:
	_set_rotation_snap_enabled(not _rotation_snap_enabled)

func _set_grid_placement_enabled(enabled: bool) -> void:
	if _grid_placement_enabled == enabled:
		return

	_grid_placement_enabled = enabled
	if _placement_active and _preview_item != null:
		_set_preview_position(_preview_item.global_position)
		if _drag_mode == "":
			_hover_target = _pick_interaction_target(get_viewport().get_mouse_position())
	_popup_visual_signature = ""
	_update_grid_visibility()
	_update_inventory_ui()
	_update_status_text()
	_update_popup_visuals()

func _set_rotation_snap_enabled(enabled: bool) -> void:
	if _rotation_snap_enabled == enabled:
		return

	_rotation_snap_enabled = enabled
	if _placement_active and _preview_item != null and _can_rotate_preview():
		_preview_item.rotation.y = _resolve_preview_rotation(_preview_item.rotation.y)
		if _grid_placement_enabled:
			_refresh_preview_validity()
		else:
			_set_preview_position(_preview_item.global_position)
	_popup_visual_signature = ""
	_update_inventory_ui()
	_update_status_text()
	_update_popup_visuals()

func _get_placement_mode_label() -> String:
	return "Grid placement" if _grid_placement_enabled else "Free placement"

func _get_placement_mode_sentence() -> String:
	return "%s is on." % _get_placement_mode_label()

func _get_clear_space_label() -> String:
	return "cell" if _grid_placement_enabled else "spot"

func _get_popup_mode_hint() -> String:
	return "Grid snap on" if _grid_placement_enabled else "Free placement"

func _get_rotation_mode_label() -> String:
	return "Rotation snap" if _rotation_snap_enabled else "Smooth rotation"

func _get_rotation_mode_sentence() -> String:
	return "%s is on." % _get_rotation_mode_label()

func _get_rotation_popup_hint() -> String:
	return "90deg rotate" if _rotation_snap_enabled else "Smooth rotate"

func _get_rotation_status_action() -> String:
	return "rotate with Q/E" if _rotation_snap_enabled else "fine-tune the angle with Q/E"

func _get_rotation_step() -> float:
	return ROTATION_SNAP_STEP if _rotation_snap_enabled else SMOOTH_ROTATION_KEY_STEP

func _resolve_preview_rotation(target_rotation_y: float) -> float:
	if _preview_item == null:
		return target_rotation_y
	if _active_preview_is_wall_placeable():
		return RoomConstants.get_wall_rotation(_active_surface_name) + _preview_item.get_wall_rotation_offset()
	if _rotation_snap_enabled:
		return round(target_rotation_y / ROTATION_SNAP_STEP) * ROTATION_SNAP_STEP
	return snappedf(target_rotation_y, SMOOTH_ROTATION_PRECISION_STEP)

func _apply_preview_rotation(target_rotation_y: float) -> void:
	if not _can_rotate_preview():
		return

	_preview_item.rotation.y = _resolve_preview_rotation(target_rotation_y)
	if _grid_placement_enabled:
		_refresh_preview_validity()
	else:
		_set_preview_position(_preview_item.global_position)

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

	_clear_active_session()
	_autosave_room_layout()

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
		_invalidate_placeables_registry_structure()
	_sync_room_wall_openings()
	_preview_item.rotation.y = seed_rotation
	_preview_item.global_position = _find_duplicate_seed_position(seed_transform.origin)
	_refresh_preview_validity()

func _on_delete_button_pressed() -> void:
	if not _is_edit_session() or _preview_item == null:
		return

	var deleted_preview_item := _preview_item
	_preview_item = null
	_refund_stock_for_placeable_tree(deleted_preview_item)
	deleted_preview_item.free()
	_on_placeable_structure_removed()
	_clear_active_session()
	_autosave_room_layout()

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
		_grid_overlay.visible = false
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
	_invalidate_placeables_registry_structure()
	_request_wall_openings_refresh()
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
	if not _can_rotate_preview():
		return

	_apply_preview_rotation(_preview_item.rotation.y + _get_rotation_step() * float(direction))

func _evaluate_preview_transform() -> Dictionary:
	if _active_preview_is_support_surface_placeable():
		return _evaluate_support_surface_preview_transform()
	return PlacementValidator.evaluate_preview_transform(
		get_world_3d(),
		_room_shell,
		_preview_item,
		_active_surface_name,
		_placement_query_shape,
		_get_preview_excluded_rids(),
		not _grid_placement_enabled or not _rotation_snap_enabled
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
	var item_half_extents := PlacementSurfaceQueries.get_rotated_planar_half_extents(_preview_item.get_footprint_half_extents(), _preview_item.rotation.y)
	if absf(local_offset.x) + item_half_extents.x > half_extents.x + 0.001:
		return {"valid": false, "code": "bounds", "reason": "Too close to surface edge"}
	if absf(local_offset.z) + item_half_extents.y > half_extents.y + 0.001:
		return {"valid": false, "code": "bounds", "reason": "Too close to surface edge"}

	var expected_y := center_offset.y + SUPPORT_SURFACE_CLEARANCE
	if absf(_preview_item.position.y - expected_y) > 0.02:
		return {"valid": false, "code": "surface", "reason": "Move onto the flat surface"}

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _placement_query_shape
	query.collision_mask = PlaceableItem.COLLISION_LAYER
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
	for placeable in collect_placeable_subtree(_preview_item):
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
	if _browser_ui != null:
		_browser_ui.refresh_inventory_ui()

func _update_mode_ui() -> void:
	if _browser_ui != null:
		_browser_ui.update_mode_ui()

func _update_browser_mode_ui() -> void:
	if _browser_ui != null:
		_browser_ui.update_browser_mode_ui()

func _get_owned_item_type_count() -> int:
	var count := 0
	for item_id in _item_owned_totals.keys():
		if int(_item_owned_totals.get(item_id, 0)) > 0:
			count += 1
	return count

func _update_floor_style_ui() -> void:
	if _browser_ui != null:
		_browser_ui.update_floor_style_ui()

func _update_status_text() -> void:
	if _status_label == null:
		return

	var mode_sentence := _get_placement_mode_sentence()
	var rotation_sentence := _get_rotation_mode_sentence()
	var rotation_action := _get_rotation_status_action()
	if _placement_active:
		var target_surface_name := "furniture surface" if _active_preview_is_support_surface_placeable() else ("ceiling" if _active_preview_is_ceiling_placeable() else ("wall" if _active_preview_is_wall_placeable() else "floor"))
		if _placement_valid:
			match _placement_session:
				PLACEMENT_SESSION_EDIT:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Editing %s on the wall.\n%s Drag the item itself to move it across the wall. Duplicate and Delete are available while editing." % [_get_active_item_display_name(), mode_sentence]
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Editing %s on the ceiling.\n%s %s Drag the item itself, use the gizmo, or %s." % [_get_active_item_display_name(), mode_sentence, rotation_sentence, rotation_action]
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Editing %s on a furniture surface.\n%s %s Drag the item itself across the surface, then %s if needed." % [_get_active_item_display_name(), mode_sentence, rotation_sentence, rotation_action]
					else:
						_status_label.text = "Editing %s.\n%s Drag the item itself, use the gizmo, or orbit with left-drag on empty space. Duplicate and Delete are available while editing." % [_get_active_item_display_name(), mode_sentence]
				PLACEMENT_SESSION_DUPLICATE:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\n%s Drag the item to a new wall spot, then confirm to keep both copies." % [_get_active_item_display_name(), mode_sentence]
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\n%s %s Drag the item to a new ceiling spot, then confirm to keep both copies." % [_get_active_item_display_name(), mode_sentence, rotation_sentence]
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Ready to place a duplicate of %s.\n%s %s Drag the item to a new spot on a table, shelf, or cabinet top, then confirm to keep both copies." % [_get_active_item_display_name(), mode_sentence, rotation_sentence]
					else:
						_status_label.text = "Ready to place a duplicate of %s.\n%s %s Drag the item to a new floor spot, then confirm to keep both copies." % [_get_active_item_display_name(), mode_sentence, rotation_sentence]
				_:
					if _active_preview_is_wall_placeable():
						_status_label.text = "Ready to place %s.\n%s Drag the item onto the wall, then confirm. This item cuts a window opening into the wall." % [_get_active_item_display_name(), mode_sentence]
					elif _active_preview_is_ceiling_placeable():
						_status_label.text = "Ready to place %s.\n%s %s Drag the item onto the ceiling, then %s if needed." % [_get_active_item_display_name(), mode_sentence, rotation_sentence, rotation_action]
					elif _active_preview_is_support_surface_placeable():
						_status_label.text = "Ready to place %s.\n%s %s Drag the item across a flat table, shelf, or cabinet top, then %s if needed." % [_get_active_item_display_name(), mode_sentence, rotation_sentence, rotation_action]
					else:
						_status_label.text = "Ready to place %s.\n%s %s Left-drag the item, use the gizmo handles, or orbit with left-drag on empty space. You can %s." % [_get_active_item_display_name(), mode_sentence, rotation_sentence, rotation_action]
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
					_status_label.text = "Blocked by another placed item.\nMove to a clear %s, or press X / Esc to cancel." % _get_clear_space_label()
				_:
					_status_label.text = "Blocked placement.\nMove away from walls or another item, or press X / Esc to cancel."
		return

	if _is_edit_mode():
		_status_label.text = "Edit mode is active.\nDouble-click any placed furniture to move it. %s and %s will be used for the next edit." % [_get_placement_mode_label(), _get_rotation_mode_label()]
		return

	if not _has_any_stock():
		_status_label.text = "No available inventory stock right now.\nOpen Shop to buy more items, or switch to Edit to move what is already placed."
		return

	_status_label.text = "Choose an owned item from Inventory to place it.\nOpen Shop to buy more furniture. %s and %s are ready for the next placement." % [_get_placement_mode_label(), _get_rotation_mode_label()]

func _update_grid_visibility() -> void:
	if _grid_overlay == null:
		return

	_refresh_grid_overlay_transform()
	_grid_overlay.visible = _grid_placement_enabled \
		and (_placement_active or _is_edit_mode()) \
		and not (_placement_active and _active_preview_is_support_surface_placeable())

func _refresh_grid_overlay_transform() -> void:
	if _grid_overlay == null or _room_shell == null:
		return

	var overlay_y := _room_shell.get_ceiling_y() - 0.03 if _placement_active and _active_preview_is_ceiling_placeable() else _room_shell.global_position.y + 0.03
	_grid_overlay.global_position = Vector3(_room_shell.global_position.x, overlay_y, _room_shell.global_position.z)

func _update_popup_position() -> void:
	if _preview_item == null or _popup_panel == null:
		return

	var camera := _get_active_camera()
	if camera == null:
		return
	var next_signature := _build_popup_signature(camera)
	if next_signature == _last_popup_signature:
		return
	_last_popup_signature = next_signature

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
	if _preview_item == null or _gizmo_root == null:
		return

	var camera := _get_active_camera()
	var next_signature := _build_gizmo_signature(camera)
	if next_signature == _last_gizmo_signature:
		return
	_last_gizmo_signature = next_signature
	_gizmo_root.global_position = _preview_item.global_position + Vector3(0.0, _get_gizmo_offset_y(), 0.0)
	_gizmo_root.global_basis = _preview_item.global_transform.basis.orthonormalized()
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
				var handle_id := String(gizmo_collider.get_meta("handle_id"))
				if handle_id == "rotate" and not _can_rotate_preview():
					return ""
				return handle_id

	var preview_hit := _raycast_from_mouse(mouse_position, PlaceableItem.PREVIEW_PICK_LAYER)
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

func _pick_placeable_item(mouse_position: Vector2) -> PlaceableItem:
	if _is_pointer_over_placement_ui():
		return null

	var hit := _raycast_from_mouse(mouse_position, PlaceableItem.COLLISION_LAYER)
	if hit.is_empty():
		return null

	return hit.get("collider") as PlaceableItem

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
			if _active_preview_is_wall_placeable() or not _can_rotate_preview():
				return
			var current_angle := _get_active_plane_angle_around_preview(mouse_position)
			var delta_angle := wrapf(current_angle - _drag_rotation_start_angle, -PI, PI)
			var next_rotation := _drag_start_rotation_y + delta_angle
			if _rotation_snap_enabled:
				var rotation_steps: float = round(delta_angle / ROTATION_SNAP_STEP)
				next_rotation = _drag_start_rotation_y + rotation_steps * ROTATION_SNAP_STEP
			_apply_preview_rotation(next_rotation)

func _end_drag() -> void:
	_drag_mode = ""
	_hover_target = _pick_interaction_target(get_viewport().get_mouse_position())
	_update_gizmo_hover_state()

func _set_preview_position(target_position: Vector3) -> void:
	if _preview_item == null:
		return

	if _active_preview_is_wall_placeable():
		_preview_item.global_position = _resolve_wall_preview_position(target_position)
		_preview_item.rotation.y = RoomConstants.get_wall_rotation(_active_surface_name) + _preview_item.get_wall_rotation_offset()
		var next_wall_signature := _build_live_wall_preview_signature()
		if next_wall_signature != _last_wall_preview_signature:
			_last_wall_preview_signature = next_wall_signature
			_request_wall_openings_refresh()
			_sync_room_wall_openings()
	elif _active_preview_is_ceiling_placeable():
		_preview_item.global_position = _resolve_planar_preview_position(target_position, RoomConstants.CEILING_SURFACE)
	elif _active_preview_is_support_surface_placeable():
		var support_surface := _get_active_support_surface_data()
		if _active_support_host != null and not support_surface.is_empty():
			if _preview_item.get_parent() != _active_support_host:
				_preview_item.reparent(_active_support_host, true)
				_invalidate_placeables_registry_structure()
			_preview_item.position = _resolve_support_surface_local_position(_active_support_host, support_surface, target_position)
	else:
		_preview_item.global_position = _resolve_planar_preview_position(target_position, RoomConstants.FLOOR_SURFACE)
	_refresh_preview_validity()

func _apply_preview_surface_hit(hit: Dictionary) -> void:
	if not hit.get("valid", false):
		return
	_active_surface_name = String(hit.get("surface_name", _active_surface_name))
	if _active_preview_is_support_surface_placeable():
		var host := hit.get("host") as PlaceableItem
		var surface_id := String(hit.get("surface_id", DEFAULT_SUPPORT_SURFACE_ID))
		if host == null:
			return
		_active_support_host = host
		_active_support_surface_id = surface_id
		if _preview_item.get_parent() != host:
			_preview_item.reparent(host, true)
			_invalidate_placeables_registry_structure()
		_set_preview_position(hit["position"] as Vector3)
		return
	_set_preview_position(hit["position"] as Vector3)

func _get_active_support_surface_data() -> Dictionary:
	return _get_support_surface_data(_active_support_host, _active_support_surface_id)

func _get_support_surface_data(host: PlaceableItem, surface_id: String) -> Dictionary:
	if host == null:
		return {}
	for raw_surface in host.get_support_surfaces():
		if typeof(raw_surface) != TYPE_DICTIONARY:
			continue
		var surface_data := raw_surface as Dictionary
		if String(surface_data.get("id", DEFAULT_SUPPORT_SURFACE_ID)) == surface_id:
			return surface_data
	return {}

func _get_support_surface_hosts() -> Array[PlaceableItem]:
	if _placeables_registry == null:
		return []
	return _placeables_registry.get_support_surface_hosts(_preview_item, _render_state)

func _resolve_planar_preview_position(target_position: Vector3, surface_name: String) -> Vector3:
	if _grid_placement_enabled:
		return _snap_planar_position(target_position, surface_name)
	if _preview_item == null:
		return target_position

	var item_half_extents := PlacementSurfaceQueries.get_rotated_planar_half_extents(_preview_item.get_footprint_half_extents(), _preview_item.rotation.y)
	return PlacementSurfaceQueries.clamp_planar_position(_room_shell, target_position, surface_name, item_half_extents)

func _resolve_wall_preview_position(target_position: Vector3) -> Vector3:
	if _grid_placement_enabled:
		return _snap_wall_position(target_position)
	return PlacementSurfaceQueries.clamp_wall_position(_room_shell, _active_surface_name, target_position, _preview_item)

func _resolve_support_surface_local_position(host: PlaceableItem, support_surface: Dictionary, target_world_position: Vector3) -> Vector3:
	if host == null or support_surface.is_empty() or _preview_item == null:
		return Vector3.ZERO

	var center_offset := support_surface.get("center_offset", Vector3.ZERO) as Vector3
	var half_extents := support_surface.get("half_extents", Vector2.ZERO) as Vector2
	var local_target := host.to_local(target_world_position)
	var local_offset := local_target - center_offset
	var item_half_extents := PlacementSurfaceQueries.get_rotated_planar_half_extents(_preview_item.get_footprint_half_extents(), _preview_item.rotation.y)
	var available_x := maxf(0.0, half_extents.x - item_half_extents.x)
	var available_z := maxf(0.0, half_extents.y - item_half_extents.y)
	var resolved_x := clampf(local_offset.x, -available_x, available_x)
	var resolved_z := clampf(local_offset.z, -available_z, available_z)
	if _grid_placement_enabled:
		resolved_x = clampf(round(resolved_x / SUPPORT_SURFACE_SNAP_SIZE) * SUPPORT_SURFACE_SNAP_SIZE, -available_x, available_x)
		resolved_z = clampf(round(resolved_z / SUPPORT_SURFACE_SNAP_SIZE) * SUPPORT_SURFACE_SNAP_SIZE, -available_z, available_z)
	return Vector3(
		center_offset.x + resolved_x,
		center_offset.y + SUPPORT_SURFACE_CLEARANCE,
		center_offset.z + resolved_z
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

			var resolved_local := _resolve_support_surface_local_position(host, support_surface, surface_center)
			var resolved_world := host.to_global(resolved_local)
			var camera_distance := camera.global_position.distance_squared_to(resolved_world)
			if camera_distance >= best_score:
				continue

			best_score = camera_distance
			best_hit = {
				"valid": true,
				"surface_name": RoomConstants.MOUNT_SURFACE,
				"distance": sqrt(camera_distance),
				"position": resolved_world,
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
	var popup_hint_text := "LMB drag  |  %s  |  %s" % [_get_popup_mode_hint(), _get_rotation_popup_hint()]
	if _placement_valid:
		panel_bg = PlacementUiStyles.COLOR_PANEL_SOFT
		panel_border = PlacementUiStyles.COLOR_SUCCESS_BORDER
		status_color = PlacementUiStyles.COLOR_TEXT
	else:
		panel_bg = PlacementUiStyles.COLOR_DANGER.lerp(PlacementUiStyles.COLOR_PANEL_SOFT, 0.42)
		panel_border = PlacementUiStyles.COLOR_DANGER_BORDER
		status_color = PlacementUiStyles.COLOR_TEXT
		popup_status_text = _placement_issue_text
		popup_hint_text = "Move to a clear %s" % _get_clear_space_label()

	var confirm_text := "Move" if _is_edit_session() else "Place"
	var confirm_tooltip := "Confirm the current %s" % ("move" if _is_edit_session() else "placement")
	var cancel_tooltip := "Cancel the current action"
	var popup_mode_hint := _get_popup_mode_hint()
	var rotation_popup_hint := _get_rotation_popup_hint()

	if _placement_valid:
		if _active_preview_is_wall_placeable():
			popup_hint_text = ("Drag on wall  |  %s" % popup_mode_hint) if not _is_edit_session() else ("Drag on wall  |  %s  |  Duplicate/Delete" % popup_mode_hint)
		elif _active_preview_is_ceiling_placeable():
			popup_hint_text = ("Drag on ceiling  |  %s  |  %s" % [popup_mode_hint, rotation_popup_hint]) if not _is_edit_session() else ("Drag on ceiling  |  %s  |  %s  |  Duplicate/Delete" % [popup_mode_hint, rotation_popup_hint])
		elif _active_preview_is_support_surface_placeable():
			popup_hint_text = ("Drag on furniture top  |  %s  |  %s" % [popup_mode_hint, rotation_popup_hint]) if not _is_edit_session() else ("Drag on furniture top  |  %s  |  %s  |  Duplicate/Delete" % [popup_mode_hint, rotation_popup_hint])
		else:
			popup_hint_text = ("LMB drag  |  %s  |  %s" % [popup_mode_hint, rotation_popup_hint]) if not _is_edit_session() else ("LMB drag  |  %s  |  %s  |  Duplicate/Delete" % [popup_mode_hint, rotation_popup_hint])

	var popup_visual_signature := JSON.stringify({
		"valid": _placement_valid,
		"status": popup_status_text,
		"hint": popup_hint_text,
		"confirm": confirm_text,
		"edit": _is_edit_session(),
		"duplicate_enabled": duplicate_enabled,
		"delete_enabled": delete_enabled,
		"grid_placement_enabled": _grid_placement_enabled,
		"rotation_snap_enabled": _rotation_snap_enabled,
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

func get_wall_opening_placeables_cached() -> Array[PlaceableItem]:
	if _placeables_registry == null:
		return []
	return _placeables_registry.get_wall_opening_placeables()

func get_window_placeables_cached() -> Array[PlaceableItem]:
	if _placeables_registry == null:
		return []
	return _placeables_registry.get_window_placeables()

func get_wall_placeables_for_surface(surface_name: String) -> Array[PlaceableItem]:
	if _placeables_registry == null:
		return []
	return _placeables_registry.get_wall_placeables_for_surface(surface_name)

func get_ceiling_placeables() -> Array[PlaceableItem]:
	if _placeables_registry == null:
		return []
	return _placeables_registry.get_ceiling_placeables()

func collect_placeable_subtree(root_placeable: PlaceableItem) -> Array[PlaceableItem]:
	if _placeables_registry == null:
		var subtree: Array[PlaceableItem] = []
		if root_placeable != null and is_instance_valid(root_placeable):
			subtree.append(root_placeable)
		return subtree
	return _placeables_registry.collect_placeable_subtree(root_placeable)

func _build_live_wall_preview_signature() -> String:
	if _preview_item == null:
		return ""

	var preview_position := _preview_item.global_position
	var opening := _preview_item.get_wall_opening_half_extents()
	return "%s|%.3f|%.3f|%.3f|%.3f|%.3f" % [
		_active_surface_name,
		preview_position.x,
		preview_position.y,
		preview_position.z,
		opening.x,
		opening.y,
	]

func _build_popup_signature(camera: Camera3D) -> String:
	if _preview_item == null or camera == null or _popup_panel == null:
		return ""

	var preview_position := _preview_item.global_position
	var anchor_offset_y := _get_popup_anchor_offset_y()
	var anchor_world := preview_position + Vector3(0.0, anchor_offset_y, 0.0)
	var popup_size := _popup_panel.get_combined_minimum_size()
	var viewport_size := get_viewport().get_visible_rect().size
	return "%s|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f" % [
		"1" if not camera.is_position_behind(anchor_world) else "0",
		preview_position.x,
		preview_position.y,
		preview_position.z,
		anchor_offset_y,
		camera.global_position.x,
		camera.global_position.y,
		camera.global_position.z,
		viewport_size.x,
		viewport_size.y,
		popup_size.x,
		popup_size.y,
	]

func _build_gizmo_signature(camera: Camera3D) -> String:
	if _preview_item == null:
		return ""

	var preview_position := _preview_item.global_position
	var rotation_y := _preview_item.rotation.y
	var camera_position := camera.global_position if camera != null else Vector3.ZERO
	return "%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f" % [
		preview_position.x,
		preview_position.y,
		preview_position.z,
		rotation_y,
		camera_position.x,
		camera_position.y,
		camera_position.z,
	]

func _refund_stock_for_placeable_tree(root_placeable: PlaceableItem) -> void:
	for placeable in collect_placeable_subtree(root_placeable):
		var item_id := _resolve_item_id_for_placeable(placeable)
		if item_id.is_empty():
			continue
		_item_stock[item_id] = int(_item_stock.get(item_id, 0)) + 1

func _is_placeable_effectively_cutaway(placeable: PlaceableItem) -> bool:
	return _render_state.is_placeable_effectively_cutaway(placeable)

func _build_wall_openings_signature(openings_by_surface: Dictionary) -> String:
	return _wall_opening_sync.build_wall_openings_signature(openings_by_surface)

func _notify_room_layout_visuals_changed() -> void:
	room_layout_visuals_changed.emit()

func _cleanup_stray_placeable_artifacts() -> void:
	var stray_placeables: Array[PlaceableItem] = []
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

func _collect_stray_placeables_recursive(node: Node, output: Array[PlaceableItem]) -> void:
	for child in node.get_children():
		var placeable := child as PlaceableItem
		if placeable != null:
			output.append(placeable)
			continue
		_collect_stray_placeables_recursive(child, output)
