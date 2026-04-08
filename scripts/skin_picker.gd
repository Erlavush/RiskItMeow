class_name SkinPicker
extends CanvasLayer

const EDGE_MARGIN := 12.0
const TOGGLE_BUTTON_WIDTH := 160.0
const TOGGLE_BUTTON_HEIGHT := 36.0
const PANEL_WIDTH := 332.0
const PANEL_TOP_GAP := 8.0
const PANEL_ANIMATION_DURATION := 0.16

var rig_node: MinecraftRig
var player_node: CharacterBody3D

var file_dialog: FileDialog
var status_label: Label
var choose_button: Button
var model_button: Button
var view_button: Button
var _ui_root: Control
var _toggle_button: Button
var _panel: PanelContainer
var _panel_tween: Tween
var _panel_open := false

func _ready() -> void:
	if rig_node == null:
		return

	layer = 15
	_setup_ui()
	_refresh_ui()

func _setup_ui() -> void:
	_ui_root = Control.new()
	_ui_root.name = "SkinUiRoot"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui_root)

	_toggle_button = Button.new()
	_toggle_button.name = "PlayerToolsToggle"
	_toggle_button.toggle_mode = true
	_toggle_button.anchor_left = 0.0
	_toggle_button.anchor_right = 0.0
	_toggle_button.offset_left = EDGE_MARGIN
	_toggle_button.offset_right = EDGE_MARGIN + TOGGLE_BUTTON_WIDTH
	_toggle_button.offset_top = EDGE_MARGIN
	_toggle_button.offset_bottom = EDGE_MARGIN + TOGGLE_BUTTON_HEIGHT
	_toggle_button.pressed.connect(_on_toggle_button_pressed)
	_ui_root.add_child(_toggle_button)

	_panel = PanelContainer.new()
	_panel.name = "PlayerToolsPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel",
		PlacementUiStyles.make_panel_style(PlacementUiStyles.COLOR_PANEL_SOFT, PlacementUiStyles.COLOR_BORDER, 1, 14, 6, 0.18)
	)
	_ui_root.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "Player Tools"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT)
	vbox.add_child(title_label)

	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	vbox.add_child(toolbar)

	choose_button = Button.new()
	choose_button.text = "Skin"
	choose_button.pressed.connect(_on_choose_skin_button_pressed)
	PlacementUiStyles.apply_button_style(choose_button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	toolbar.add_child(choose_button)

	model_button = Button.new()
	model_button.pressed.connect(_on_model_button_pressed)
	PlacementUiStyles.apply_button_style(model_button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	toolbar.add_child(model_button)

	view_button = Button.new()
	view_button.pressed.connect(_on_view_button_pressed)
	PlacementUiStyles.apply_button_style(view_button, PlacementUiStyles.COLOR_ACCENT_DARK, PlacementUiStyles.COLOR_ACCENT_BRIGHT, PlacementUiStyles.COLOR_TEXT)
	toolbar.add_child(view_button)

	status_label = Label.new()
	status_label.text = "Use the Camera button to switch views. Room view uses orbit controls; first person uses mouse look, Esc releases the cursor, and left-click recaptures it."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(PANEL_WIDTH - 32.0, 0.0)
	status_label.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT_MUTED)
	vbox.add_child(status_label)

	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.use_native_dialog = true
	file_dialog.filters = PackedStringArray(["*.png ; PNG Image"])
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.canceled.connect(_on_file_dialog_closed)
	add_child(file_dialog)

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_toggle_button_visual()
	_update_panel_layout(false)
	_set_panel_open(false, false)

func _refresh_ui() -> void:
	_update_model_button()
	_update_view_button()

func _update_model_button() -> void:
	if rig_node == null:
		model_button.text = "Model"
		return

	if rig_node.skin_model == MinecraftRig.SkinModel.SLIM:
		model_button.text = "Model: Slim"
	else:
		model_button.text = "Model: Classic"

func _update_view_button() -> void:
	if player_node != null and player_node.has_method("get_camera_mode_label"):
		view_button.text = "Camera: %s" % player_node.call("get_camera_mode_label")
	else:
		view_button.text = "Camera"

func refresh_camera_ui() -> void:
	_update_view_button()

func _on_viewport_size_changed() -> void:
	_update_panel_layout(false)

func _on_toggle_button_pressed() -> void:
	_set_panel_open(_toggle_button.button_pressed)

func _set_panel_open(is_open: bool, animate: bool = true) -> void:
	_panel_open = is_open
	_update_toggle_button_visual()
	if _panel == null:
		return

	var target_position := Vector2(EDGE_MARGIN, EDGE_MARGIN + TOGGLE_BUTTON_HEIGHT + PANEL_TOP_GAP)
	if not _panel_open:
		target_position.x = -PANEL_WIDTH - 20.0

	if _panel_tween != null and _panel_tween.is_running():
		_panel_tween.kill()

	if not animate:
		_panel.position = target_position
		_panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if _panel_open else 0.0)
		return

	_panel_tween = create_tween()
	_panel_tween.set_trans(Tween.TRANS_QUAD)
	_panel_tween.set_ease(Tween.EASE_OUT)
	_panel_tween.parallel().tween_property(_panel, "position", target_position, PANEL_ANIMATION_DURATION)
	_panel_tween.parallel().tween_property(_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0 if _panel_open else 0.0), PANEL_ANIMATION_DURATION * 0.9)

func _update_panel_layout(animate: bool = false) -> void:
	if _panel == null:
		return
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_panel.size = _panel.get_combined_minimum_size()
	if animate:
		_set_panel_open(_panel_open, true)
		return
	var panel_position := Vector2(EDGE_MARGIN, EDGE_MARGIN + TOGGLE_BUTTON_HEIGHT + PANEL_TOP_GAP)
	if not _panel_open:
		panel_position.x = -PANEL_WIDTH - 20.0
	_panel.position = panel_position

func _update_toggle_button_visual() -> void:
	if _toggle_button == null:
		return
	_toggle_button.button_pressed = _panel_open
	_toggle_button.text = "Player Tools [Hide]" if _panel_open else "Player Tools [Show]"
	PlacementUiStyles.apply_button_style(
		_toggle_button,
		PlacementUiStyles.COLOR_ACCENT_DARK if _panel_open else PlacementUiStyles.COLOR_PANEL_ALT,
		PlacementUiStyles.COLOR_ACCENT_BRIGHT if _panel_open else PlacementUiStyles.COLOR_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)

func _on_choose_skin_button_pressed() -> void:
	var downloads: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if downloads != "":
		file_dialog.current_dir = downloads

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	file_dialog.popup_centered_ratio(0.8)

func _on_file_selected(path: String) -> void:
	_on_file_dialog_closed()

	if rig_node == null:
		return

	var ok: bool = rig_node.load_skin_from_file(path)
	if ok:
		status_label.text = "Loaded: %s" % path.get_file()
	else:
		status_label.text = "Invalid skin. Use a 64x64 PNG."

func _on_file_dialog_closed() -> void:
	# No auto-capture here, letting player use ESC as they prefer
	pass

func _on_model_button_pressed() -> void:
	if rig_node == null:
		return

	if rig_node.skin_model == MinecraftRig.SkinModel.CLASSIC:
		rig_node.skin_model = MinecraftRig.SkinModel.SLIM
	else:
		rig_node.skin_model = MinecraftRig.SkinModel.CLASSIC

	_update_model_button()
	status_label.text = "Arm model changed."

func _on_view_button_pressed() -> void:
	if player_node != null and player_node.has_method("toggle_camera_mode"):
		player_node.call("toggle_camera_mode")
		_update_view_button()
		var mode_label := "Camera"
		if player_node.has_method("get_camera_mode_label"):
			mode_label = String(player_node.call("get_camera_mode_label"))
		if mode_label == "First Person":
			status_label.text = "First-person camera active. Move the mouse to look, press Esc to release the cursor, and left-click to recapture it."
		else:
			status_label.text = "Room-view camera active. Right-drag or middle-drag to orbit, wheel to zoom, and Home resets the room camera."
