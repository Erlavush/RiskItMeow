class_name BuildToolbar
extends CanvasLayer

var _panel: PanelContainer
var _mode_label: Label
var _selection_label: Label
var _status_label: Label
var _controls_label: Label
var _crosshair: Label

func _ready() -> void:
	_build_ui()
	visible = false

func set_state(build_mode_enabled: bool, selected_text: String, status_text: String, helper_text: String) -> void:
	visible = build_mode_enabled
	if _panel == null:
		return

	_mode_label.text = "Build Mode: %s" % ("On" if build_mode_enabled else "Off")
	_selection_label.text = "Selection: %s" % selected_text
	_status_label.text = status_text
	_controls_label.text = helper_text
	_crosshair.visible = build_mode_enabled

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(12.0, 116.0)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	_mode_label = Label.new()
	layout.add_child(_mode_label)

	_selection_label = Label.new()
	layout.add_child(_selection_label)

	_status_label = Label.new()
	layout.add_child(_status_label)

	_controls_label = Label.new()
	_controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls_label.custom_minimum_size = Vector2(290.0, 0.0)
	layout.add_child(_controls_label)

	_crosshair = Label.new()
	_crosshair.text = "+"
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair.size = Vector2(24.0, 24.0)
	add_child(_crosshair)
	_update_crosshair_position()

func _process(_delta: float) -> void:
	if _crosshair != null:
		_update_crosshair_position()

func _update_crosshair_position() -> void:
	_crosshair.position = get_viewport().get_visible_rect().size * 0.5 - _crosshair.size * 0.5
