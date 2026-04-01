class_name SkinPicker
extends CanvasLayer

var rig_node: MinecraftRig
var player_node: CharacterBody3D

var file_dialog: FileDialog
var status_label: Label
var choose_button: Button
var model_button: Button
var view_button: Button

func _ready() -> void:
	if rig_node == null:
		return

	_setup_ui()
	_refresh_ui()

func _setup_ui() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(12, 12)
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	vbox.add_child(toolbar)

	choose_button = Button.new()
	choose_button.text = "Skin"
	choose_button.pressed.connect(_on_choose_skin_button_pressed)
	toolbar.add_child(choose_button)

	model_button = Button.new()
	model_button.pressed.connect(_on_model_button_pressed)
	toolbar.add_child(model_button)

	view_button = Button.new()
	view_button.pressed.connect(_on_view_button_pressed)
	toolbar.add_child(view_button)

	status_label = Label.new()
	status_label.text = "ESC toggles mouse"
	vbox.add_child(status_label)

	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.use_native_dialog = true
	file_dialog.filters = PackedStringArray(["*.png ; PNG Image"])
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.canceled.connect(_on_file_dialog_closed)
	add_child(file_dialog)

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
	if player_node != null and player_node.has_method("get_camera_mode_name"):
		var mode_name: String = str(player_node.call("get_camera_mode_name"))
		view_button.text = "View: %s" % mode_name
	else:
		view_button.text = "View"

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
	if player_node != null and player_node.has_method("cycle_camera_mode"):
		player_node.call("cycle_camera_mode")
		_update_view_button()
		status_label.text = "Camera: %s" % view_button.text.replace("View: ", "")
