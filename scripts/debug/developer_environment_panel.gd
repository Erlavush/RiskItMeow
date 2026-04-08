@tool
class_name DeveloperEnvironmentPanel
extends CanvasLayer

signal environment_state_changed

const PANEL_WIDTH := 344.0
const PANEL_HEIGHT := 620.0
const EDGE_MARGIN := 16.0
const BUTTON_WIDTH := 168.0
const BUTTON_HEIGHT := 36.0
const PERSISTENT_SETTINGS_PATH := DeveloperEnvironmentPersistence.SETTINGS_PATH
const PERSISTENT_SAVE_DELAY_SECONDS := 0.15
const EDITOR_PREVIEW_POLL_SECONDS := 0.6
const SUN_PRESET_MORNING := DeveloperEnvironmentPresets.SUN_PRESET_MORNING
const SUN_PRESET_NOON := DeveloperEnvironmentPresets.SUN_PRESET_NOON
const SUN_PRESET_SUNSET := DeveloperEnvironmentPresets.SUN_PRESET_SUNSET
const SUN_PRESET_AFTERNOON_COZY := DeveloperEnvironmentPresets.SUN_PRESET_AFTERNOON_COZY

@export var world_environment_path: NodePath
@export var directional_light_path: NodePath
@export var debug_world_controller_path: NodePath

var _world_environment: WorldEnvironment
var _directional_light: DirectionalLight3D
var _environment: Environment
var _debug_world_controller: DebugWorldController

var _default_values: Dictionary = {}
var _base_ambient_color := Color.WHITE
var _base_fog_color := Color.WHITE
var _base_light_color := Color.WHITE
var _warmth := 0.0
var _syncing_controls := false

var _ui_root: Control
var _toggle_button: Button
var _panel: PanelContainer
var _debug_world_button: Button
var _save_timer: Timer
var _status_label: Label
var _slider_bindings: Array[Dictionary] = []
var _toggle_bindings: Array[Dictionary] = []
var _editor_preview_poll_time := 0.0
var _editor_persistent_signature := ""
var _syncing_debug_world_button := false

func _ready() -> void:
	layer = 20
	_world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
	_directional_light = get_node_or_null(directional_light_path) as DirectionalLight3D
	_environment = _world_environment.environment if _world_environment != null else null
	_debug_world_controller = get_node_or_null(debug_world_controller_path) as DebugWorldController
	var debug_world_callback := Callable(self, "_on_debug_world_enabled_changed")
	if _debug_world_controller != null and not _debug_world_controller.is_connected("debug_world_enabled_changed", debug_world_callback):
		_debug_world_controller.connect("debug_world_enabled_changed", debug_world_callback)

	_capture_defaults()
	if Engine.is_editor_hint():
		_refresh_editor_preview_from_saved_state(true)
		set_process(true)
		return

	_build_ui()
	var loaded_saved_settings := _load_persistent_state()
	_sync_controls_from_state()
	_set_status("Loaded saved developer preset from user://" if loaded_saved_settings else "Using scene defaults. Changes auto-save to user://")

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	_editor_preview_poll_time -= delta
	if _editor_preview_poll_time > 0.0:
		return

	_editor_preview_poll_time = EDITOR_PREVIEW_POLL_SECONDS
	_refresh_editor_preview_from_saved_state()

func _capture_defaults() -> void:
	var captured := DeveloperEnvironmentState.capture_defaults(_environment, _directional_light)
	_default_values = captured.get("values", {}) as Dictionary
	_base_ambient_color = captured.get("base_ambient_color", Color.WHITE) as Color
	_base_fog_color = captured.get("base_fog_color", Color.WHITE) as Color
	_base_light_color = captured.get("base_light_color", Color.WHITE) as Color

func _build_ui() -> void:
	_ui_root = Control.new()
	_ui_root.name = "Root"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui_root)

	_toggle_button = Button.new()
	_toggle_button.name = "DeveloperToggle"
	_toggle_button.toggle_mode = true
	_toggle_button.text = "Developer [Show]"
	_toggle_button.tooltip_text = "Open or hide the developer environment panel"
	_toggle_button.anchor_left = 1.0
	_toggle_button.anchor_right = 1.0
	_toggle_button.offset_left = -BUTTON_WIDTH - EDGE_MARGIN
	_toggle_button.offset_right = -EDGE_MARGIN
	_toggle_button.offset_top = EDGE_MARGIN
	_toggle_button.offset_bottom = EDGE_MARGIN + BUTTON_HEIGHT
	_toggle_button.pressed.connect(_on_toggle_button_pressed)
	PlacementUiStyles.apply_button_style(_toggle_button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	_ui_root.add_child(_toggle_button)

	_panel = PanelContainer.new()
	_panel.name = "DeveloperPanel"
	_panel.visible = false
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -PANEL_WIDTH - EDGE_MARGIN
	_panel.offset_right = -EDGE_MARGIN
	_panel.offset_top = EDGE_MARGIN + BUTTON_HEIGHT + 8.0
	_panel.offset_bottom = EDGE_MARGIN + BUTTON_HEIGHT + 8.0 + PANEL_HEIGHT
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel",
		PlacementUiStyles.make_panel_style(PlacementUiStyles.COLOR_PANEL, PlacementUiStyles.COLOR_BORDER, 1, 16, 10, 0.22)
	)
	_ui_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Developer Environment"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Developer-only tuning for lighting, fog, glow, and post-processing. Changes auto-save locally."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT_MUTED)
	layout.add_child(subtitle)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)

	var reset_button := Button.new()
	reset_button.text = "Reset Defaults"
	reset_button.pressed.connect(_on_reset_defaults_pressed)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PlacementUiStyles.apply_button_style(reset_button, PlacementUiStyles.COLOR_PANEL_ALT, PlacementUiStyles.COLOR_BORDER, PlacementUiStyles.COLOR_TEXT)
	button_row.add_child(reset_button)

	var clear_button := Button.new()
	clear_button.text = "Clear Saved"
	clear_button.pressed.connect(_on_clear_saved_pressed)
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PlacementUiStyles.apply_button_style(clear_button, PlacementUiStyles.COLOR_DANGER, PlacementUiStyles.COLOR_DANGER_BORDER, PlacementUiStyles.COLOR_TEXT)
	button_row.add_child(clear_button)

	_debug_world_button = Button.new()
	_debug_world_button.toggle_mode = true
	_debug_world_button.pressed.connect(_on_debug_world_button_pressed)
	_debug_world_button.custom_minimum_size = Vector2(0.0, 34.0)
	layout.add_child(_debug_world_button)
	_update_debug_world_button_visual(_debug_world_controller != null and _debug_world_controller.is_debug_world_enabled())
	if _debug_world_controller == null:
		_debug_world_button.disabled = true

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT_MUTED)
	layout.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(PANEL_WIDTH - 20.0, PANEL_HEIGHT - 144.0)
	layout.add_child(scroll)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	scroll.add_child(controls)

	_add_section_label(controls, "Light")
	_add_sun_preset_controls(controls)
	_add_slider_control(controls, "Sun Energy", 0.0, 3.0, 0.01, Callable(self, "_get_light_energy"), Callable(self, "_set_light_energy"))
	_add_slider_control(controls, "Warmth", -1.0, 1.0, 0.01, Callable(self, "_get_warmth"), Callable(self, "_set_warmth"))
	_add_toggle_control(controls, "Shadows", Callable(self, "_get_shadow_enabled"), Callable(self, "_set_shadow_enabled"))
	_add_slider_control(controls, "Shadow Opacity", 0.0, 1.0, 0.01, Callable(self, "_get_shadow_opacity"), Callable(self, "_set_shadow_opacity"))
	_add_slider_control(controls, "Shadow Blur", 0.0, 4.0, 0.05, Callable(self, "_get_shadow_blur"), Callable(self, "_set_shadow_blur"))
	_add_slider_control(controls, "Shadow Distance", 5.0, 100.0, 1.0, Callable(self, "_get_shadow_distance"), Callable(self, "_set_shadow_distance"))

	_add_section_label(controls, "Ambient and Post")
	_add_slider_control(controls, "Ambient Energy", 0.0, 2.0, 0.01, Callable(self, "_get_ambient_energy"), Callable(self, "_set_ambient_energy"))
	_add_slider_control(controls, "Ambient Sky Mix", 0.0, 1.0, 0.01, Callable(self, "_get_ambient_sky_mix"), Callable(self, "_set_ambient_sky_mix"))
	_add_slider_control(controls, "Exposure", 0.2, 2.5, 0.01, Callable(self, "_get_exposure"), Callable(self, "_set_exposure"))
	_add_toggle_control(controls, "Post Adjust", Callable(self, "_get_post_adjust_enabled"), Callable(self, "_set_post_adjust_enabled"))
	_add_slider_control(controls, "Brightness", 0.5, 1.5, 0.01, Callable(self, "_get_brightness"), Callable(self, "_set_brightness"))
	_add_slider_control(controls, "Contrast", 0.5, 1.7, 0.01, Callable(self, "_get_contrast"), Callable(self, "_set_contrast"))
	_add_slider_control(controls, "Saturation", 0.0, 2.0, 0.01, Callable(self, "_get_saturation"), Callable(self, "_set_saturation"))

	_add_section_label(controls, "Fog and Glow")
	_add_toggle_control(controls, "Fog", Callable(self, "_get_fog_enabled"), Callable(self, "_set_fog_enabled"))
	_add_slider_control(controls, "Fog Density", 0.0, 0.5, 0.005, Callable(self, "_get_fog_density"), Callable(self, "_set_fog_density"))
	_add_slider_control(controls, "Fog Depth End", 5.0, 120.0, 1.0, Callable(self, "_get_fog_depth_end"), Callable(self, "_set_fog_depth_end"))
	_add_slider_control(controls, "Fog Energy", 0.0, 2.0, 0.01, Callable(self, "_get_fog_energy"), Callable(self, "_set_fog_energy"))
	_add_toggle_control(controls, "Glow", Callable(self, "_get_glow_enabled"), Callable(self, "_set_glow_enabled"))
	_add_slider_control(controls, "Glow Bloom", 0.0, 1.0, 0.01, Callable(self, "_get_glow_bloom"), Callable(self, "_set_glow_bloom"))
	_add_slider_control(controls, "Glow HDR", 0.0, 3.0, 0.01, Callable(self, "_get_glow_hdr"), Callable(self, "_set_glow_hdr"))

	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = PERSISTENT_SAVE_DELAY_SECONDS
	_save_timer.timeout.connect(_save_persistent_state)
	add_child(_save_timer)

func _add_section_label(parent: VBoxContainer, text_value: String) -> void:
	var separator := HSeparator.new()
	parent.add_child(separator)

	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)

func _add_sun_preset_controls(parent: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Sun Presets"
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)

	for preset_name in DeveloperEnvironmentPresets.get_preset_names():
		var button := Button.new()
		button.text = _get_sun_preset_label(preset_name)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_sun_preset_pressed.bind(preset_name))
		grid.add_child(button)

func _get_sun_preset_label(preset_name: String) -> String:
	return DeveloperEnvironmentPresets.get_label(preset_name)

func _add_slider_control(parent: VBoxContainer, title_text: String, min_value: float, max_value: float, step_value: float, getter: Callable, setter: Callable) -> void:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	parent.add_child(wrapper)

	var header := HBoxContainer.new()
	wrapper.add_child(header)

	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(56.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_value_changed.bind(setter, value_label, step_value))
	wrapper.add_child(slider)

	_slider_bindings.append({
		"slider": slider,
		"value_label": value_label,
		"getter": getter,
		"step": step_value,
	})

func _add_toggle_control(parent: VBoxContainer, title_text: String, getter: Callable, setter: Callable) -> void:
	var toggle := CheckButton.new()
	toggle.text = title_text
	toggle.toggled.connect(_on_toggle_value_changed.bind(setter))
	parent.add_child(toggle)

	_toggle_bindings.append({
		"toggle": toggle,
		"getter": getter,
	})

func _on_toggle_button_pressed() -> void:
	var is_open := _toggle_button.button_pressed
	_panel.visible = is_open
	_toggle_button.text = "Developer [Hide]" if is_open else "Developer [Show]"
	PlacementUiStyles.apply_button_style(
		_toggle_button,
		PlacementUiStyles.COLOR_ACCENT_DARK if is_open else PlacementUiStyles.COLOR_PANEL_ALT,
		PlacementUiStyles.COLOR_ACCENT_BRIGHT if is_open else PlacementUiStyles.COLOR_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)

func _on_debug_world_button_pressed() -> void:
	if _syncing_debug_world_button or _debug_world_controller == null or _debug_world_button == null:
		return
	_debug_world_controller.set_debug_world_enabled(_debug_world_button.button_pressed)

func _on_debug_world_enabled_changed(enabled: bool) -> void:
	if _toggle_button != null:
		_toggle_button.visible = not enabled
	if enabled and _panel != null and _panel.visible:
		_panel.visible = false
		if _toggle_button != null:
			_toggle_button.button_pressed = false
			_toggle_button.text = "Developer [Show]"
			PlacementUiStyles.apply_button_style(
				_toggle_button,
				PlacementUiStyles.COLOR_PANEL_ALT,
				PlacementUiStyles.COLOR_BORDER,
				PlacementUiStyles.COLOR_TEXT
			)
	_update_debug_world_button_visual(enabled)

func _update_debug_world_button_visual(enabled: bool) -> void:
	if _debug_world_button == null:
		return
	_syncing_debug_world_button = true
	_debug_world_button.button_pressed = enabled
	_debug_world_button.text = "Debug World [Hide]" if enabled else "Debug World [Show]"
	PlacementUiStyles.apply_button_style(
		_debug_world_button,
		PlacementUiStyles.COLOR_ACCENT_DARK if enabled else PlacementUiStyles.COLOR_PANEL_ALT,
		PlacementUiStyles.COLOR_ACCENT_BRIGHT if enabled else PlacementUiStyles.COLOR_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)
	_syncing_debug_world_button = false

func _on_sun_preset_pressed(preset_name: String) -> void:
	_apply_sun_preset(preset_name)
	_sync_controls_from_state()
	_queue_persistent_save()
	_set_status("Applied %s sun preset. Saving locally..." % _get_sun_preset_label(preset_name))

func _on_reset_defaults_pressed() -> void:
	_apply_state_values(_default_values)
	_sync_controls_from_state()
	_queue_persistent_save()
	_set_status("Reset to scene defaults. Saving locally...")

func _on_clear_saved_pressed() -> void:
	_apply_state_values(_default_values)
	_sync_controls_from_state()
	if _save_timer != null:
		_save_timer.stop()

	var absolute_path := ProjectSettings.globalize_path(PERSISTENT_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			_set_status("Could not remove saved preset (%s)." % error_string(remove_error))
			return

	_set_status("Cleared saved preset. Using scene defaults.")

func _on_slider_value_changed(value: float, setter: Callable, value_label: Label, step_value: float) -> void:
	value_label.text = _format_number(value, step_value)
	if _syncing_controls:
		return
	setter.call(value)

func _on_toggle_value_changed(value: bool, setter: Callable) -> void:
	if _syncing_controls:
		return
	setter.call(value)

func _sync_controls_from_state() -> void:
	_syncing_controls = true

	for binding in _slider_bindings:
		var getter: Callable = binding.get("getter", Callable())
		var slider: HSlider = binding.get("slider", null) as HSlider
		var value_label: Label = binding.get("value_label", null) as Label
		var step_value: float = float(binding.get("step", 0.01))
		if slider == null or value_label == null:
			continue

		var current_value: float = float(getter.call())
		slider.value = current_value
		value_label.text = _format_number(current_value, step_value)

	for binding in _toggle_bindings:
		var getter: Callable = binding.get("getter", Callable())
		var toggle: CheckButton = binding.get("toggle", null) as CheckButton
		if toggle == null:
			continue
		toggle.button_pressed = bool(getter.call())

	_syncing_controls = false

func _format_number(value: float, step_value: float) -> String:
	if step_value >= 1.0:
		return str(int(round(value)))
	if step_value >= 0.1:
		return "%.1f" % value
	if step_value >= 0.01:
		return "%.2f" % value
	return "%.3f" % value

func _get_light_energy() -> float:
	return _directional_light.light_energy if _directional_light != null else 0.0

func _set_light_energy(value: float) -> void:
	if _directional_light != null:
		_directional_light.light_energy = value
		_queue_persistent_save()

func _get_warmth() -> float:
	return _warmth

func _set_warmth(value: float) -> void:
	_warmth = value
	_apply_warmth()
	_queue_persistent_save()

func _get_shadow_enabled() -> bool:
	return _directional_light.shadow_enabled if _directional_light != null else false

func _set_shadow_enabled(value: bool) -> void:
	if _directional_light != null:
		_directional_light.shadow_enabled = value
		_queue_persistent_save()

func _get_shadow_opacity() -> float:
	return _directional_light.shadow_opacity if _directional_light != null else 0.0

func _set_shadow_opacity(value: float) -> void:
	if _directional_light != null:
		_directional_light.shadow_opacity = value
		_queue_persistent_save()

func _get_shadow_blur() -> float:
	return _directional_light.shadow_blur if _directional_light != null else 0.0

func _set_shadow_blur(value: float) -> void:
	if _directional_light != null:
		_directional_light.shadow_blur = value
		_queue_persistent_save()

func _get_shadow_distance() -> float:
	return _directional_light.directional_shadow_max_distance if _directional_light != null else 0.0

func _set_shadow_distance(value: float) -> void:
	if _directional_light != null:
		_directional_light.directional_shadow_max_distance = value
		_queue_persistent_save()

func _get_ambient_energy() -> float:
	return _environment.ambient_light_energy if _environment != null else 0.0

func _set_ambient_energy(value: float) -> void:
	if _environment != null:
		_environment.ambient_light_energy = value
		_queue_persistent_save()

func _get_ambient_sky_mix() -> float:
	return _environment.ambient_light_sky_contribution if _environment != null else 0.0

func _set_ambient_sky_mix(value: float) -> void:
	if _environment != null:
		_environment.ambient_light_sky_contribution = value
		_queue_persistent_save()

func _get_exposure() -> float:
	return _environment.tonemap_exposure if _environment != null else 0.0

func _set_exposure(value: float) -> void:
	if _environment != null:
		_environment.tonemap_exposure = value
		_queue_persistent_save()

func _get_post_adjust_enabled() -> bool:
	return _environment.adjustment_enabled if _environment != null else false

func _set_post_adjust_enabled(value: bool) -> void:
	if _environment != null:
		_environment.adjustment_enabled = value
		_queue_persistent_save()

func _get_brightness() -> float:
	return _environment.adjustment_brightness if _environment != null else 1.0

func _set_brightness(value: float) -> void:
	if _environment != null:
		_environment.adjustment_enabled = true
		_environment.adjustment_brightness = value
		_queue_persistent_save()

func _get_contrast() -> float:
	return _environment.adjustment_contrast if _environment != null else 1.0

func _set_contrast(value: float) -> void:
	if _environment != null:
		_environment.adjustment_enabled = true
		_environment.adjustment_contrast = value
		_queue_persistent_save()

func _get_saturation() -> float:
	return _environment.adjustment_saturation if _environment != null else 1.0

func _set_saturation(value: float) -> void:
	if _environment != null:
		_environment.adjustment_enabled = true
		_environment.adjustment_saturation = value
		_queue_persistent_save()

func _get_fog_enabled() -> bool:
	return _environment.fog_enabled if _environment != null else false

func _set_fog_enabled(value: bool) -> void:
	if _environment != null:
		_environment.fog_enabled = value
		_queue_persistent_save()

func _get_fog_density() -> float:
	return _environment.fog_density if _environment != null else 0.0

func _set_fog_density(value: float) -> void:
	if _environment != null:
		_environment.fog_enabled = true
		_environment.fog_density = value
		_queue_persistent_save()

func _get_fog_depth_end() -> float:
	return _environment.fog_depth_end if _environment != null else 0.0

func _set_fog_depth_end(value: float) -> void:
	if _environment != null:
		_environment.fog_depth_end = value
		_queue_persistent_save()

func _get_fog_energy() -> float:
	return _environment.fog_light_energy if _environment != null else 0.0

func _set_fog_energy(value: float) -> void:
	if _environment != null:
		_environment.fog_enabled = true
		_environment.fog_light_energy = value
		_queue_persistent_save()

func _get_glow_enabled() -> bool:
	return _environment.glow_enabled if _environment != null else false

func _set_glow_enabled(value: bool) -> void:
	if _environment != null:
		_environment.glow_enabled = value
		_queue_persistent_save()

func _get_glow_bloom() -> float:
	return _environment.glow_bloom if _environment != null else 0.0

func _set_glow_bloom(value: float) -> void:
	if _environment != null:
		_environment.glow_enabled = true
		_environment.glow_bloom = value
		_queue_persistent_save()

func _get_glow_hdr() -> float:
	return _environment.glow_hdr_scale if _environment != null else 0.0

func _set_glow_hdr(value: float) -> void:
	if _environment != null:
		_environment.glow_enabled = true
		_environment.glow_hdr_scale = value
		_queue_persistent_save()

func _apply_warmth() -> void:
	DeveloperEnvironmentState.apply_warmth(
		_environment,
		_directional_light,
		_base_ambient_color,
		_base_fog_color,
		_base_light_color,
		_warmth
	)

func _apply_sun_preset(preset_name: String) -> void:
	var values := DeveloperEnvironmentPresets.build_state(preset_name, _default_values)
	if values.is_empty():
		return

	_apply_state_values(values)

func _capture_current_values() -> Dictionary:
	return DeveloperEnvironmentState.capture_current_values(_environment, _directional_light, _warmth)

func _apply_state_values(values: Dictionary) -> void:
	_warmth = DeveloperEnvironmentState.apply_state_values(
		_environment,
		_directional_light,
		_default_values,
		_base_ambient_color,
		_base_fog_color,
		_base_light_color,
		values
	)
	environment_state_changed.emit()

func _queue_persistent_save() -> void:
	if _save_timer == null:
		return
	_save_timer.start()
	environment_state_changed.emit()
	_set_status("Saving developer preset...")

func _save_persistent_state() -> void:
	var values := _capture_current_values()
	var save_error := DeveloperEnvironmentPersistence.save_values(values)
	if save_error != OK:
		_set_status("Save failed: %s" % error_string(save_error))
		return

	_set_status("Saved developer preset to user://")

func _load_persistent_state() -> bool:
	var values := DeveloperEnvironmentPersistence.load_values(_default_values.keys())
	_apply_state_values(values)
	return values.size() > 0

func _refresh_editor_preview_from_saved_state(force: bool = false) -> void:
	var signature := DeveloperEnvironmentPersistence.get_file_signature()
	if not force and signature == _editor_persistent_signature:
		return

	_editor_persistent_signature = signature
	if signature.is_empty():
		_apply_state_values(_default_values)
		return

	var values := DeveloperEnvironmentPersistence.load_values(_default_values.keys())
	if values.is_empty():
		_apply_state_values(_default_values)
		return

	_apply_state_values(values)

func _set_status(text_value: String) -> void:
	if _status_label == null:
		return
	_status_label.text = text_value
