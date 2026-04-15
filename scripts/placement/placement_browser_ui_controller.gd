extends CanvasLayer
class_name PlacementBrowserUiController

signal inventory_item_pressed(item_id: String)
signal shop_buy_requested(item_id: String)
signal browser_mode_pressed(next_mode: String)
signal mode_pressed(next_mode: String)
signal grid_toggle_pressed(enabled: bool)
signal rotation_toggle_pressed(enabled: bool)
signal floor_style_pressed(style_id: int)
signal save_pressed
signal load_pressed
signal clear_room_pressed
signal confirm_pressed
signal cancel_pressed
signal duplicate_pressed
signal delete_pressed

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
const FLOOR_STYLE_COZY_BROWN := 0
const FLOOR_STYLE_CHECKERBOARD := 1
const BROWSER_MODE_INVENTORY := "inventory"
const BROWSER_MODE_SHOP := "shop"
const EDITOR_MODE_BUILD := "build"
const EDITOR_MODE_EDIT := "edit"
const PLACEMENT_SESSION_EDIT := "edit"
const PLACEMENT_SESSION_DUPLICATE := "duplicate"

var placement_manager

func build_ui() -> void:
	if placement_manager == null or placement_manager._ui_root != null:
		return

	name = "PlacementUi"
	placement_manager._ui_layer = self

	placement_manager._ui_root = Control.new()
	placement_manager._ui_root.name = "Root"
	placement_manager._ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placement_manager._ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(placement_manager._ui_root)

	placement_manager._browser_toggle_button = Button.new()
	placement_manager._browser_toggle_button.name = "BuildBrowserToggle"
	placement_manager._browser_toggle_button.toggle_mode = true
	placement_manager._browser_toggle_button.anchor_left = 0.0
	placement_manager._browser_toggle_button.anchor_right = 0.0
	placement_manager._browser_toggle_button.offset_left = UI_SIDE_MARGIN
	placement_manager._browser_toggle_button.offset_right = UI_SIDE_MARGIN + BROWSER_TOGGLE_BUTTON_SIZE.x
	placement_manager._browser_toggle_button.offset_top = 60.0
	placement_manager._browser_toggle_button.offset_bottom = 60.0 + BROWSER_TOGGLE_BUTTON_SIZE.y
	placement_manager._browser_toggle_button.pressed.connect(_on_browser_toggle_button_pressed)
	placement_manager._ui_root.add_child(placement_manager._browser_toggle_button)

	placement_manager._inventory_panel = PanelContainer.new()
	placement_manager._inventory_panel.name = "InventoryPanel"
	placement_manager._inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	placement_manager._ui_root.add_child(placement_manager._inventory_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	placement_manager._inventory_panel.add_child(margin)

	placement_manager._browser_layout = VBoxContainer.new()
	placement_manager._browser_layout.add_theme_constant_override("separation", 8)
	margin.add_child(placement_manager._browser_layout)

	placement_manager._panel_title_label = Label.new()
	placement_manager._panel_title_label.text = "Build Browser"
	placement_manager._panel_title_label.add_theme_font_size_override("font_size", 18)
	PlacementUiStyles.apply_label_color(placement_manager._panel_title_label, PlacementUiStyles.COLOR_TEXT)
	placement_manager._browser_layout.add_child(placement_manager._panel_title_label)
	placement_manager._mode_label = null

	var mode_button_row := HBoxContainer.new()
	mode_button_row.add_theme_constant_override("separation", 6)
	placement_manager._browser_layout.add_child(mode_button_row)
	_add_mode_button(mode_button_row, "Build", EDITOR_MODE_BUILD)
	_add_mode_button(mode_button_row, "Edit", EDITOR_MODE_EDIT)

	var browser_mode_row := HBoxContainer.new()
	browser_mode_row.add_theme_constant_override("separation", 6)
	placement_manager._browser_layout.add_child(browser_mode_row)
	_add_browser_mode_button(browser_mode_row, "Inventory", BROWSER_MODE_INVENTORY)
	_add_browser_mode_button(browser_mode_row, "Shop", BROWSER_MODE_SHOP)

	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 6)
	placement_manager._browser_layout.add_child(search_row)

	placement_manager._browser_search_input = LineEdit.new()
	placement_manager._browser_search_input.placeholder_text = "Search items..."
	placement_manager._browser_search_input.clear_button_enabled = true
	placement_manager._browser_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._browser_search_input.text_changed.connect(_on_browser_search_text_changed)
	PlacementUiStyles.apply_line_edit_style(placement_manager._browser_search_input)
	search_row.add_child(placement_manager._browser_search_input)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	placement_manager._browser_layout.add_child(filter_row)

	placement_manager._mount_filter_option = OptionButton.new()
	placement_manager._mount_filter_option.custom_minimum_size = Vector2(0.0, 34.0)
	placement_manager._mount_filter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._mount_filter_option.item_selected.connect(_on_mount_filter_option_selected)
	filter_row.add_child(placement_manager._mount_filter_option)

	placement_manager._browser_section_label = Label.new()
	placement_manager._browser_section_label.text = "Browse Items"
	placement_manager._browser_section_label.add_theme_font_size_override("font_size", 11)
	PlacementUiStyles.apply_label_color(placement_manager._browser_section_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	placement_manager._browser_layout.add_child(placement_manager._browser_section_label)

	placement_manager._category_filter_option = OptionButton.new()
	placement_manager._category_filter_option.custom_minimum_size = Vector2(0.0, 34.0)
	placement_manager._category_filter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._category_filter_option.item_selected.connect(_on_category_filter_option_selected)
	filter_row.add_child(placement_manager._category_filter_option)

	placement_manager._browser_scroll = ScrollContainer.new()
	placement_manager._browser_scroll.custom_minimum_size = Vector2(0.0, 140.0)
	placement_manager._browser_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._browser_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placement_manager._browser_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	placement_manager._browser_scroll.mouse_force_pass_scroll_events = true
	placement_manager._browser_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	placement_manager._browser_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	placement_manager._browser_scroll.gui_input.connect(_on_browser_scroll_gui_input)
	placement_manager._browser_layout.add_child(placement_manager._browser_scroll)

	placement_manager._browser_grid = GridContainer.new()
	placement_manager._browser_grid.columns = 2
	placement_manager._browser_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._browser_grid.add_theme_constant_override("h_separation", BROWSER_GRID_H_SEPARATION)
	placement_manager._browser_grid.add_theme_constant_override("v_separation", 12)
	placement_manager._browser_scroll.add_child(placement_manager._browser_grid)
	var browser_scroll_bar: VScrollBar = placement_manager._browser_scroll.get_v_scroll_bar()
	if browser_scroll_bar != null:
		browser_scroll_bar.custom_minimum_size = Vector2(8.0, 0.0)
		browser_scroll_bar.mouse_filter = Control.MOUSE_FILTER_STOP

	placement_manager._status_shell = PanelContainer.new()
	PlacementUiStyles.apply_panel_style(placement_manager._status_shell, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, 1, 14, 4, 0.12)
	placement_manager._status_shell.visible = false
	placement_manager._browser_layout.add_child(placement_manager._status_shell)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 10)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_right", 10)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	placement_manager._status_shell.add_child(status_margin)

	placement_manager._status_label = Label.new()
	placement_manager._status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placement_manager._status_label.custom_minimum_size = Vector2(0.0, 40.0)
	placement_manager._status_label.add_theme_font_size_override("font_size", 10)
	PlacementUiStyles.apply_label_color(placement_manager._status_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	status_margin.add_child(placement_manager._status_label)

	placement_manager._tools_toggle_button = Button.new()
	placement_manager._tools_toggle_button.toggle_mode = true
	placement_manager._tools_toggle_button.text = "More Tools"
	placement_manager._tools_toggle_button.pressed.connect(_on_tools_toggle_pressed)
	placement_manager._browser_layout.add_child(placement_manager._tools_toggle_button)

	placement_manager._tools_section = VBoxContainer.new()
	placement_manager._tools_section.visible = false
	placement_manager._tools_section.add_theme_constant_override("separation", 8)
	placement_manager._browser_layout.add_child(placement_manager._tools_section)

	placement_manager._floor_style_label = Label.new()
	placement_manager._floor_style_label.text = "Floor Finish"
	placement_manager._floor_style_label.add_theme_font_size_override("font_size", 11)
	PlacementUiStyles.apply_label_color(placement_manager._floor_style_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	placement_manager._tools_section.add_child(placement_manager._floor_style_label)

	var floor_button_row := HBoxContainer.new()
	floor_button_row.add_theme_constant_override("separation", 8)
	placement_manager._tools_section.add_child(floor_button_row)
	_add_floor_style_button(floor_button_row, "Brown Mat", FLOOR_STYLE_COZY_BROWN)
	_add_floor_style_button(floor_button_row, "Checkerboard", FLOOR_STYLE_CHECKERBOARD)

	placement_manager._grid_toggle_button = Button.new()
	placement_manager._grid_toggle_button.custom_minimum_size = Vector2(0.0, 36.0)
	placement_manager._grid_toggle_button.pressed.connect(_on_grid_toggle_button_pressed)
	placement_manager._tools_section.add_child(placement_manager._grid_toggle_button)

	placement_manager._rotation_toggle_button = Button.new()
	placement_manager._rotation_toggle_button.custom_minimum_size = Vector2(0.0, 36.0)
	placement_manager._rotation_toggle_button.pressed.connect(_on_rotation_toggle_button_pressed)
	placement_manager._tools_section.add_child(placement_manager._rotation_toggle_button)

	var persistence_row := HBoxContainer.new()
	persistence_row.add_theme_constant_override("separation", 8)
	placement_manager._tools_section.add_child(persistence_row)

	placement_manager._save_button = Button.new()
	placement_manager._save_button.text = "Save"
	placement_manager._save_button.custom_minimum_size = Vector2(80.0, 34.0)
	placement_manager._save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._save_button.pressed.connect(func() -> void: save_pressed.emit())
	persistence_row.add_child(placement_manager._save_button)

	placement_manager._load_button = Button.new()
	placement_manager._load_button.text = "Load"
	placement_manager._load_button.custom_minimum_size = Vector2(80.0, 34.0)
	placement_manager._load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._load_button.pressed.connect(func() -> void: load_pressed.emit())
	persistence_row.add_child(placement_manager._load_button)

	placement_manager._clear_room_button = Button.new()
	placement_manager._clear_room_button.text = "Clear Room"
	placement_manager._clear_room_button.custom_minimum_size = Vector2(96.0, 34.0)
	placement_manager._clear_room_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_manager._clear_room_button.pressed.connect(func() -> void: clear_room_pressed.emit())
	persistence_row.add_child(placement_manager._clear_room_button)

	placement_manager._popup_panel = PanelContainer.new()
	placement_manager._popup_panel.name = "PlacementPopup"
	placement_manager._popup_panel.visible = false
	placement_manager._popup_panel.custom_minimum_size = Vector2(156.0, 82.0)
	placement_manager._popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	placement_manager._ui_root.add_child(placement_manager._popup_panel)

	var popup_margin := MarginContainer.new()
	popup_margin.add_theme_constant_override("margin_left", 8)
	popup_margin.add_theme_constant_override("margin_top", 8)
	popup_margin.add_theme_constant_override("margin_right", 8)
	popup_margin.add_theme_constant_override("margin_bottom", 8)
	placement_manager._popup_panel.add_child(popup_margin)

	var popup_layout := VBoxContainer.new()
	popup_layout.add_theme_constant_override("separation", 6)
	popup_margin.add_child(popup_layout)

	placement_manager._popup_status_label = Label.new()
	placement_manager._popup_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placement_manager._popup_status_label.add_theme_font_size_override("font_size", 13)
	popup_layout.add_child(placement_manager._popup_status_label)

	var popup_row := HBoxContainer.new()
	popup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_row.add_theme_constant_override("separation", 6)
	popup_margin.add_child(popup_row)

	placement_manager._confirm_button = Button.new()
	placement_manager._confirm_button.tooltip_text = "Place chair"
	placement_manager._confirm_button.text = "Place"
	placement_manager._confirm_button.custom_minimum_size = Vector2(68.0, 32.0)
	placement_manager._confirm_button.add_theme_font_size_override("font_size", 14)
	placement_manager._confirm_button.pressed.connect(func() -> void: confirm_pressed.emit())
	popup_row.add_child(placement_manager._confirm_button)

	placement_manager._cancel_button = Button.new()
	placement_manager._cancel_button.text = "X"
	placement_manager._cancel_button.tooltip_text = "Cancel placement"
	placement_manager._cancel_button.custom_minimum_size = Vector2(62.0, 32.0)
	placement_manager._cancel_button.add_theme_font_size_override("font_size", 14)
	placement_manager._cancel_button.pressed.connect(func() -> void: cancel_pressed.emit())
	popup_row.add_child(placement_manager._cancel_button)
	popup_row.reparent(popup_layout)

	placement_manager._popup_edit_row = HBoxContainer.new()
	placement_manager._popup_edit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	placement_manager._popup_edit_row.add_theme_constant_override("separation", 6)
	popup_layout.add_child(placement_manager._popup_edit_row)

	placement_manager._duplicate_button = Button.new()
	placement_manager._duplicate_button.text = "Duplicate"
	placement_manager._duplicate_button.custom_minimum_size = Vector2(86.0, 32.0)
	placement_manager._duplicate_button.add_theme_font_size_override("font_size", 14)
	placement_manager._duplicate_button.pressed.connect(func() -> void: duplicate_pressed.emit())
	placement_manager._popup_edit_row.add_child(placement_manager._duplicate_button)

	placement_manager._delete_button = Button.new()
	placement_manager._delete_button.text = "Delete"
	placement_manager._delete_button.custom_minimum_size = Vector2(72.0, 32.0)
	placement_manager._delete_button.add_theme_font_size_override("font_size", 14)
	placement_manager._delete_button.pressed.connect(func() -> void: delete_pressed.emit())
	placement_manager._popup_edit_row.add_child(placement_manager._delete_button)

	placement_manager._popup_hint_label = Label.new()
	placement_manager._popup_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placement_manager._popup_hint_label.add_theme_font_size_override("font_size", 11)
	popup_layout.add_child(placement_manager._popup_hint_label)

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	rebuild_shop_category_tabs()
	rebuild_item_browser()
	update_mode_ui()
	update_browser_mode_ui()
	update_browser_toggle_button_visual()
	update_popup_visuals()
	update_floor_style_ui()
	update_browser_layout_metrics(false)
	set_browser_open(false, false)

func refresh_inventory_ui() -> void:
	if placement_manager == null:
		return

	update_browser_mode_ui()
	rebuild_item_browser()
	update_section_toggle_ui()
	if placement_manager._browser_search_input != null:
		placement_manager._browser_search_input.editable = not placement_manager._placement_active
	if placement_manager._grid_toggle_button != null:
		placement_manager._grid_toggle_button.text = "Grid Placement: %s" % ("On" if placement_manager._grid_placement_enabled else "Off")
		placement_manager._grid_toggle_button.disabled = false
		PlacementUiStyles.apply_button_style(
			placement_manager._grid_toggle_button,
			PlacementUiStyles.COLOR_ACCENT_DARK if placement_manager._grid_placement_enabled else PlacementUiStyles.COLOR_PANEL_ALT,
			PlacementUiStyles.COLOR_ACCENT_BRIGHT if placement_manager._grid_placement_enabled else PlacementUiStyles.COLOR_BORDER,
			PlacementUiStyles.COLOR_TEXT
		)
	if placement_manager._rotation_toggle_button != null:
		placement_manager._rotation_toggle_button.text = "Rotation Snap: %s" % ("On" if placement_manager._rotation_snap_enabled else "Off")
		placement_manager._rotation_toggle_button.disabled = false
		PlacementUiStyles.apply_button_style(
			placement_manager._rotation_toggle_button,
			PlacementUiStyles.COLOR_ACCENT_DARK if placement_manager._rotation_snap_enabled else PlacementUiStyles.COLOR_PANEL_ALT,
			PlacementUiStyles.COLOR_ACCENT_BRIGHT if placement_manager._rotation_snap_enabled else PlacementUiStyles.COLOR_BORDER,
			PlacementUiStyles.COLOR_TEXT
		)
	if placement_manager._save_button != null:
		placement_manager._save_button.disabled = placement_manager._placement_active
		PlacementUiStyles.apply_button_style(placement_manager._save_button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	if placement_manager._load_button != null:
		placement_manager._load_button.disabled = placement_manager._placement_active
		PlacementUiStyles.apply_button_style(placement_manager._load_button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	if placement_manager._clear_room_button != null:
		placement_manager._clear_room_button.disabled = placement_manager._placement_active
		PlacementUiStyles.apply_button_style(placement_manager._clear_room_button, PlacementUiStyles.COLOR_DANGER, PlacementUiStyles.COLOR_DANGER_BORDER, PlacementUiStyles.COLOR_TEXT)
	if placement_manager._browser_section_label != null:
		var result_count := get_visible_browser_item_defs().size()
		var category_name := get_selected_browser_category()
		var category_suffix := ": %s" % category_name if not category_name.is_empty() else ""
		if placement_manager._browser_mode == BROWSER_MODE_SHOP:
			placement_manager._browser_section_label.text = "Shop Catalog%s  |  %d results" % [category_suffix, result_count]
		else:
			placement_manager._browser_section_label.text = "Inventory%s  |  %d results" % [category_suffix, result_count]
	if placement_manager._status_shell != null:
		placement_manager._status_shell.visible = placement_manager._placement_active or placement_manager._is_edit_mode() or not placement_manager._has_any_stock()
	if placement_manager._inventory_panel != null:
		PlacementUiStyles.apply_panel_style(placement_manager._inventory_panel, PlacementUiStyles.COLOR_PANEL, PlacementUiStyles.COLOR_BORDER, 1, 18, 10, 0.24)
	queue_browser_layout_refresh()

func update_mode_ui() -> void:
	if placement_manager == null:
		return

	for mode_id in placement_manager._mode_buttons.keys():
		var button := placement_manager._mode_buttons.get(mode_id) as Button
		if button == null:
			continue
		var is_selected: bool = String(mode_id) == placement_manager._editor_mode
		button.button_pressed = is_selected
		button.disabled = is_selected or placement_manager._placement_active
		PlacementUiStyles.apply_button_style(
			button,
			PlacementUiStyles.COLOR_PANEL_ALT if not is_selected else PlacementUiStyles.COLOR_ACCENT,
			PlacementUiStyles.COLOR_BORDER if not is_selected else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
			PlacementUiStyles.COLOR_TEXT
		)

func update_browser_mode_ui() -> void:
	if placement_manager == null:
		return

	for mode_id in placement_manager._browser_mode_buttons.keys():
		var button := placement_manager._browser_mode_buttons.get(mode_id) as Button
		if button == null:
			continue
		var is_selected: bool = String(mode_id) == placement_manager._browser_mode
		button.button_pressed = is_selected
		button.disabled = is_selected or placement_manager._placement_active
		PlacementUiStyles.apply_button_style(
			button,
			PlacementUiStyles.COLOR_PANEL_SOFT if not is_selected else PlacementUiStyles.COLOR_ACCENT_DARK,
			PlacementUiStyles.COLOR_BORDER if not is_selected else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
			PlacementUiStyles.COLOR_TEXT
		)

	if placement_manager._mount_filter_option != null:
		placement_manager._mount_filter_option.disabled = placement_manager._placement_active
		PlacementUiStyles.apply_button_style(placement_manager._mount_filter_option, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, PlacementUiStyles.COLOR_TEXT)
		_select_option_button_value(placement_manager._mount_filter_option, placement_manager._selected_mount_filter)

	if placement_manager._category_filter_option != null:
		placement_manager._category_filter_option.disabled = placement_manager._placement_active
		PlacementUiStyles.apply_button_style(placement_manager._category_filter_option, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, PlacementUiStyles.COLOR_TEXT)
		_select_option_button_value(placement_manager._category_filter_option, get_selected_browser_category())

func update_floor_style_ui() -> void:
	if placement_manager == null:
		return

	var current_style := FLOOR_STYLE_COZY_BROWN
	if placement_manager._room_shell != null and placement_manager._room_shell.has_method("get_floor_style"):
		current_style = int(placement_manager._room_shell.call("get_floor_style"))

	for style_id in placement_manager._floor_style_buttons.keys():
		var button := placement_manager._floor_style_buttons.get(style_id) as Button
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

	if placement_manager._floor_style_label != null:
		placement_manager._floor_style_label.text = "Floor Finish: %s" % ("Brown Mat" if current_style == FLOOR_STYLE_COZY_BROWN else "Checkerboard")

func update_status_text() -> void:
	if placement_manager == null:
		return
	placement_manager._update_status_text()

func update_popup_visuals() -> void:
	if placement_manager == null:
		return
	placement_manager._update_popup_visuals()

func update_popup_position() -> void:
	if placement_manager == null:
		return
	placement_manager._update_popup_position()

func set_browser_open(_is_open: bool, _animate: bool = true) -> void:
	if placement_manager == null or placement_manager._inventory_panel == null:
		return

	placement_manager._browser_open = _is_open
	update_browser_toggle_button_visual()

	var top_margin := _get_browser_top_margin(get_viewport().get_visible_rect().size)
	var target_position := Vector2(UI_SIDE_MARGIN, top_margin + BROWSER_TOGGLE_BUTTON_SIZE.y + BROWSER_PANEL_TOP_GAP)
	if not placement_manager._browser_open:
		target_position.x = -placement_manager._inventory_panel.size.x - 24.0

	if placement_manager._browser_panel_tween != null and placement_manager._browser_panel_tween.is_running():
		placement_manager._browser_panel_tween.kill()

	if not _animate:
		placement_manager._inventory_panel.position = target_position
		placement_manager._inventory_panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if placement_manager._browser_open else 0.0)
		if placement_manager._browser_open:
			queue_browser_layout_refresh()
		return

	placement_manager._browser_panel_tween = create_tween()
	placement_manager._browser_panel_tween.set_trans(Tween.TRANS_QUAD)
	placement_manager._browser_panel_tween.set_ease(Tween.EASE_OUT)
	placement_manager._browser_panel_tween.parallel().tween_property(placement_manager._inventory_panel, "position", target_position, BROWSER_ANIMATION_DURATION)
	placement_manager._browser_panel_tween.parallel().tween_property(placement_manager._inventory_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0 if placement_manager._browser_open else 0.0), BROWSER_ANIMATION_DURATION * 0.9)
	if placement_manager._browser_open:
		placement_manager._browser_panel_tween.finished.connect(queue_browser_layout_refresh, CONNECT_ONE_SHOT)

func update_browser_layout_metrics(_animate: bool = false) -> void:
	if placement_manager == null or placement_manager._inventory_panel == null or placement_manager._browser_toggle_button == null or placement_manager._ui_root == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var top_margin := _get_browser_top_margin(viewport_size)
	placement_manager._browser_toggle_button.offset_left = UI_SIDE_MARGIN
	placement_manager._browser_toggle_button.offset_right = UI_SIDE_MARGIN + BROWSER_TOGGLE_BUTTON_SIZE.x
	placement_manager._browser_toggle_button.offset_top = top_margin
	placement_manager._browser_toggle_button.offset_bottom = top_margin + BROWSER_TOGGLE_BUTTON_SIZE.y
	var available_width := maxf(252.0, viewport_size.x - (UI_SIDE_MARGIN * 2.0) - 24.0)
	var panel_width := minf(clampf(viewport_size.x * 0.29, BROWSER_PANEL_WIDTH_MIN, BROWSER_PANEL_WIDTH_MAX), available_width)
	var available_height := maxf(260.0, viewport_size.y - top_margin - BROWSER_TOGGLE_BUTTON_SIZE.y - 22.0)
	var panel_height := minf(maxf(viewport_size.y * BROWSER_PANEL_HEIGHT_RATIO, BROWSER_PANEL_HEIGHT_MIN), available_height)
	placement_manager._inventory_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	placement_manager._inventory_panel.size = Vector2(panel_width, panel_height)
	if placement_manager._browser_scroll != null:
		placement_manager._browser_scroll.custom_minimum_size = Vector2(0.0, clampf(panel_height * 0.34, 120.0, 220.0))
	var browser_content_width := panel_width - 24.0
	var two_column_width := (BROWSER_CARD_MIN_WIDTH * 2.0) + BROWSER_GRID_H_SEPARATION + 8.0
	var panel_position := Vector2(UI_SIDE_MARGIN, top_margin + BROWSER_TOGGLE_BUTTON_SIZE.y + BROWSER_PANEL_TOP_GAP)
	if not placement_manager._browser_open:
		panel_position.x = -panel_width - 24.0
	placement_manager._inventory_panel.position = panel_position
	placement_manager._browser_grid.columns = 2 if browser_content_width >= two_column_width else 1
	if _animate:
		set_browser_open(placement_manager._browser_open, true)

func queue_browser_layout_refresh() -> void:
	call_deferred("refresh_browser_layout")

func refresh_browser_layout() -> void:
	if placement_manager == null or placement_manager._inventory_panel == null or placement_manager._browser_layout == null or placement_manager._browser_scroll == null or placement_manager._browser_grid == null:
		return

	placement_manager._browser_grid.queue_sort()
	placement_manager._browser_grid.update_minimum_size()
	placement_manager._browser_scroll.update_minimum_size()
	placement_manager._browser_layout.queue_sort()
	placement_manager._browser_layout.update_minimum_size()
	placement_manager._inventory_panel.update_minimum_size()
	update_browser_layout_metrics(false)
	var browser_scroll_bar: VScrollBar = placement_manager._browser_scroll.get_v_scroll_bar()
	if browser_scroll_bar != null:
		browser_scroll_bar.update_minimum_size()

func update_browser_toggle_button_visual() -> void:
	if placement_manager == null or placement_manager._browser_toggle_button == null:
		return

	placement_manager._browser_toggle_button.button_pressed = placement_manager._browser_open
	placement_manager._browser_toggle_button.text = "Hide Build Browser" if placement_manager._browser_open else "Open Build Browser"
	placement_manager._browser_toggle_button.tooltip_text = "Show or hide the build browser"
	PlacementUiStyles.apply_button_style(
		placement_manager._browser_toggle_button,
		PlacementUiStyles.COLOR_ACCENT_DARK if not placement_manager._browser_open else PlacementUiStyles.COLOR_ACCENT,
		PlacementUiStyles.COLOR_BORDER if not placement_manager._browser_open else PlacementUiStyles.COLOR_ACCENT_BRIGHT,
		PlacementUiStyles.COLOR_TEXT
	)

func update_section_toggle_ui() -> void:
	if placement_manager != null and placement_manager._tools_toggle_button != null:
		placement_manager._tools_toggle_button.text = "More Tools %s" % ("[-]" if placement_manager._tools_toggle_button.button_pressed else "[+]")
		PlacementUiStyles.apply_button_style(
			placement_manager._tools_toggle_button,
			PlacementUiStyles.COLOR_PANEL_ALT if placement_manager._tools_toggle_button.button_pressed else PlacementUiStyles.COLOR_PANEL_SOFT,
			PlacementUiStyles.COLOR_BORDER_STRONG if placement_manager._tools_toggle_button.button_pressed else PlacementUiStyles.COLOR_BORDER_SOFT,
			PlacementUiStyles.COLOR_TEXT
		)

func get_selected_browser_category() -> String:
	if placement_manager == null:
		return ""
	return placement_manager._selected_shop_category if placement_manager._browser_mode == BROWSER_MODE_SHOP else placement_manager._selected_inventory_category

func _add_mode_button(_parent: HBoxContainer, _title_text: String, _mode_id: String) -> void:
	var button := Button.new()
	button.text = _title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(116.0, 32.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: mode_pressed.emit(_mode_id))
	_parent.add_child(button)
	placement_manager._mode_buttons[_mode_id] = button

func _add_browser_mode_button(_parent: HBoxContainer, _title_text: String, _mode_id: String) -> void:
	var button := Button.new()
	button.text = _title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(116.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: browser_mode_pressed.emit(_mode_id))
	_parent.add_child(button)
	placement_manager._browser_mode_buttons[_mode_id] = button

func _add_floor_style_button(_parent: HBoxContainer, _title_text: String, _style_id: int) -> void:
	var button := Button.new()
	button.text = _title_text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(126.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: floor_style_pressed.emit(_style_id))
	_parent.add_child(button)
	placement_manager._floor_style_buttons[_style_id] = button

func _rebuild_filter_options() -> void:
	if placement_manager._mount_filter_option != null:
		placement_manager._mount_filter_option.clear()
		_add_option_button_item(placement_manager._mount_filter_option, "Type: All", "")
		_add_option_button_item(placement_manager._mount_filter_option, "Type: Floor", RoomConstants.MOUNT_FLOOR)
		_add_option_button_item(placement_manager._mount_filter_option, "Type: Wall", RoomConstants.MOUNT_WALL)
		_add_option_button_item(placement_manager._mount_filter_option, "Type: Ceiling", RoomConstants.MOUNT_CEILING)
		_add_option_button_item(placement_manager._mount_filter_option, "Type: Surface", RoomConstants.MOUNT_SURFACE)

	if placement_manager._category_filter_option != null:
		placement_manager._category_filter_option.clear()
		_add_option_button_item(placement_manager._category_filter_option, "Category: All", "")
		for category_name in placement_manager._shop_categories:
			_add_option_button_item(placement_manager._category_filter_option, category_name, category_name)

func _add_option_button_item(_option_button: OptionButton, _text_value: String, _metadata: Variant) -> void:
	if _option_button == null:
		return
	_option_button.add_item(_text_value)
	_option_button.set_item_metadata(_option_button.item_count - 1, _metadata)

func _select_option_button_value(_option_button: OptionButton, _metadata_value: String) -> void:
	if _option_button == null:
		return
	for option_index in range(_option_button.item_count):
		if String(_option_button.get_item_metadata(option_index)) == _metadata_value:
			_option_button.select(option_index)
			return
	if _option_button.item_count > 0:
		_option_button.select(0)

func rebuild_shop_category_tabs() -> void:
	_rebuild_filter_options()

func rebuild_item_browser() -> void:
	if placement_manager == null or placement_manager._browser_grid == null:
		return

	for child in placement_manager._browser_grid.get_children():
		placement_manager._browser_grid.remove_child(child)
		child.queue_free()

	var visible_item_defs := get_visible_browser_item_defs()
	if visible_item_defs.is_empty():
		var empty_state := PanelContainer.new()
		PlacementUiStyles.apply_panel_style(empty_state, PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER_SOFT, 1, 14, 4, 0.12)
		empty_state.custom_minimum_size = Vector2(0.0, 108.0)
		placement_manager._browser_grid.add_child(empty_state)

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

	var item_factory := Callable(placement_manager, "_create_item_instance_from_definition")
	for item_def in visible_item_defs:
		var item_id := String(item_def.get("id", ""))
		var card := PlacementBrowserCard.new()
		card.configure(
			item_def,
			placement_manager._browser_mode,
			int(placement_manager._item_stock.get(item_id, 0)),
			int(placement_manager._item_owned_totals.get(item_id, 0)),
			item_factory
		)
		card.place_requested.connect(func(next_item_id: String) -> void: inventory_item_pressed.emit(next_item_id))
		card.buy_requested.connect(func(next_item_id: String) -> void: shop_buy_requested.emit(next_item_id))
		placement_manager._browser_grid.add_child(card)

func get_visible_browser_item_defs() -> Array[Dictionary]:
	var visible_items: Array[Dictionary] = []
	if placement_manager == null:
		return visible_items

	var selected_category := get_selected_browser_category()
	var search_filter: String = placement_manager._browser_search_text.to_lower()
	for item_def in placement_manager._inventory_item_defs:
		var item_id := String(item_def.get("id", ""))
		if placement_manager._browser_mode == BROWSER_MODE_INVENTORY and int(placement_manager._item_owned_totals.get(item_id, 0)) <= 0:
			continue
		if not selected_category.is_empty() and String(item_def.get("category", "")) != selected_category:
			continue
		if not placement_manager._selected_mount_filter.is_empty() and PlacementInventoryCatalog.get_primary_mount_kind(item_def) != placement_manager._selected_mount_filter:
			continue
		if not search_filter.is_empty():
			var display_name := String(item_def.get("display_name", item_id)).to_lower()
			var category_name := String(item_def.get("category", "")).to_lower()
			var badge_text := PlacementInventoryCatalog.get_mount_badge_text(item_def).to_lower()
			if not display_name.contains(search_filter) and not category_name.contains(search_filter) and not badge_text.contains(search_filter):
				continue
		visible_items.append(item_def)
	return visible_items

func _get_browser_top_margin(_viewport_size: Vector2) -> float:
	return clampf(_viewport_size.y * 0.09, 56.0, 72.0)

func _on_viewport_size_changed() -> void:
	update_browser_layout_metrics(false)

func _on_browser_toggle_button_pressed() -> void:
	set_browser_open(placement_manager._browser_toggle_button.button_pressed)

func _on_browser_search_text_changed(_new_text: String) -> void:
	placement_manager._browser_search_text = _new_text.strip_edges()
	refresh_inventory_ui()

func _on_mount_filter_option_selected(_index: int) -> void:
	if placement_manager._placement_active or placement_manager._mount_filter_option == null:
		return
	placement_manager._selected_mount_filter = String(placement_manager._mount_filter_option.get_item_metadata(_index))
	refresh_inventory_ui()

func _on_category_filter_option_selected(_index: int) -> void:
	if placement_manager._placement_active or placement_manager._category_filter_option == null:
		return
	var selected_category := String(placement_manager._category_filter_option.get_item_metadata(_index))
	if placement_manager._browser_mode == BROWSER_MODE_SHOP:
		placement_manager._selected_shop_category = selected_category
	else:
		placement_manager._selected_inventory_category = selected_category
	refresh_inventory_ui()

func _on_tools_toggle_pressed() -> void:
	if placement_manager._tools_section != null:
		placement_manager._tools_section.visible = placement_manager._tools_toggle_button.button_pressed
	update_section_toggle_ui()

func _on_browser_scroll_gui_input(_event: InputEvent) -> void:
	if placement_manager._browser_scroll == null or _event == null:
		return
	if _event is InputEventMouseButton:
		var mouse_button := _event as InputEventMouseButton
		if not mouse_button.pressed:
			return
		var scroll_bar: VScrollBar = placement_manager._browser_scroll.get_v_scroll_bar()
		if scroll_bar == null:
			return
		var step_size := maxf(scroll_bar.page * 0.28, 56.0)
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				scroll_bar.value = maxf(scroll_bar.min_value, scroll_bar.value - step_size)
				placement_manager._browser_scroll.accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				scroll_bar.value = minf(scroll_bar.max_value - scroll_bar.page, scroll_bar.value + step_size)
				placement_manager._browser_scroll.accept_event()

func _on_grid_toggle_button_pressed() -> void:
	grid_toggle_pressed.emit(not placement_manager._grid_placement_enabled)

func _on_rotation_toggle_button_pressed() -> void:
	rotation_toggle_pressed.emit(not placement_manager._rotation_snap_enabled)
