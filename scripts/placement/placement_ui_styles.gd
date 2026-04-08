class_name PlacementUiStyles
extends RefCounted

const FONT_REGULAR_PATH := "res://assets/ui/fonts/titillium_web/TitilliumWeb-Regular.ttf"
const FONT_SEMIBOLD_PATH := "res://assets/ui/fonts/titillium_web/TitilliumWeb-SemiBold.ttf"

static var _font_regular: Font
static var _font_semibold: Font

const COLOR_BG_DEEP := Color(0.1, 0.07, 0.05, 0.98)
const COLOR_PANEL := Color(0.18, 0.13, 0.1, 0.96)
const COLOR_PANEL_ALT := Color(0.24, 0.17, 0.12, 0.96)
const COLOR_PANEL_SOFT := Color(0.16, 0.12, 0.09, 0.92)
const COLOR_CARD := Color(0.2, 0.14, 0.1, 0.98)
const COLOR_CARD_HOVER := Color(0.24, 0.17, 0.12, 1.0)
const COLOR_INPUT := Color(0.12, 0.09, 0.07, 0.98)
const COLOR_BORDER := Color(0.48, 0.35, 0.24, 0.98)
const COLOR_BORDER_SOFT := Color(0.34, 0.25, 0.18, 0.92)
const COLOR_BORDER_STRONG := Color(0.76, 0.6, 0.41, 0.98)
const COLOR_TEXT := Color(0.97, 0.92, 0.85, 1.0)
const COLOR_TEXT_MUTED := Color(0.84, 0.76, 0.66, 0.88)
const COLOR_TEXT_SUBTLE := Color(0.72, 0.64, 0.56, 0.82)
const COLOR_ACCENT := Color(0.67, 0.5, 0.3, 0.98)
const COLOR_ACCENT_BRIGHT := Color(0.89, 0.73, 0.5, 1.0)
const COLOR_ACCENT_DARK := Color(0.4, 0.28, 0.17, 0.98)
const COLOR_SUCCESS := Color(0.35, 0.45, 0.28, 0.98)
const COLOR_SUCCESS_BORDER := Color(0.66, 0.79, 0.55, 1.0)
const COLOR_DANGER := Color(0.47, 0.2, 0.18, 0.98)
const COLOR_DANGER_BORDER := Color(0.89, 0.48, 0.4, 0.98)

static func apply_button_style(button: Button, bg_color: Color, border_color: Color, font_color: Color) -> void:
	if button == null:
		return

	button.add_theme_font_override("font", get_semibold_font())
	button.add_theme_stylebox_override("normal", make_panel_style(bg_color, border_color, 1, 12, 4, 0.18))
	button.add_theme_stylebox_override("hover", make_panel_style(bg_color.lerp(COLOR_ACCENT_BRIGHT, 0.12), border_color.lerp(COLOR_ACCENT_BRIGHT, 0.26), 1, 12, 5, 0.22))
	button.add_theme_stylebox_override("pressed", make_panel_style(bg_color.lerp(Color.BLACK, 0.18), border_color, 1, 12, 3, 0.14))
	button.add_theme_stylebox_override("disabled", make_panel_style(bg_color.lerp(Color.BLACK, 0.45), border_color.lerp(Color.BLACK, 0.5), 1, 12, 2, 0.08))
	button.add_theme_stylebox_override("focus", make_panel_style(bg_color.lerp(COLOR_ACCENT_BRIGHT, 0.06), border_color.lerp(COLOR_ACCENT_BRIGHT, 0.18), 1, 12, 5, 0.2))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color.lerp(COLOR_TEXT_SUBTLE, 0.45))
	button.add_theme_constant_override("h_separation", 6)
	button.add_theme_constant_override("outline_size", 0)

static func apply_panel_style(control: Control, bg_color: Color, border_color: Color, border_width: int = 1, corner_radius: int = 14, shadow_size: int = 8, shadow_opacity: float = 0.2) -> void:
	if control == null:
		return
	control.add_theme_stylebox_override("panel", make_panel_style(bg_color, border_color, border_width, corner_radius, shadow_size, shadow_opacity))

static func apply_line_edit_style(line_edit: LineEdit) -> void:
	if line_edit == null:
		return

	line_edit.add_theme_font_override("font", get_regular_font())
	line_edit.add_theme_stylebox_override("normal", make_panel_style(COLOR_INPUT, COLOR_BORDER_SOFT, 1, 12, 3, 0.12))
	line_edit.add_theme_stylebox_override("focus", make_panel_style(COLOR_INPUT.lerp(COLOR_PANEL_ALT, 0.18), COLOR_BORDER_STRONG, 1, 12, 5, 0.2))
	line_edit.add_theme_stylebox_override("read_only", make_panel_style(COLOR_INPUT.lerp(Color.BLACK, 0.18), COLOR_BORDER_SOFT, 1, 12, 2, 0.08))
	line_edit.add_theme_color_override("font_color", COLOR_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_TEXT_SUBTLE)
	line_edit.add_theme_color_override("font_selected_color", COLOR_TEXT)
	line_edit.add_theme_color_override("selection_color", COLOR_ACCENT_DARK.lerp(COLOR_ACCENT_BRIGHT, 0.32))
	line_edit.add_theme_color_override("caret_color", COLOR_ACCENT_BRIGHT)
	line_edit.add_theme_constant_override("minimum_character_width", 1)

static func apply_label_color(label: Label, font_color: Color) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", get_regular_font())
	label.add_theme_color_override("font_color", font_color)

static func apply_label_style(label: Label, font_color: Color, bold: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", get_semibold_font() if bold else get_regular_font())
	label.add_theme_color_override("font_color", font_color)

static func apply_option_button_style(option_button: OptionButton) -> void:
	if option_button == null:
		return
	option_button.add_theme_font_override("font", get_semibold_font())

static func apply_check_button_style(check_button: CheckButton) -> void:
	if check_button == null:
		return
	check_button.add_theme_font_override("font", get_regular_font())

static func get_regular_font() -> Font:
	if _font_regular == null:
		_font_regular = _load_font_from_path(FONT_REGULAR_PATH, false)
	return _font_regular

static func get_semibold_font() -> Font:
	if _font_semibold == null:
		_font_semibold = _load_font_from_path(FONT_SEMIBOLD_PATH, true)
	return _font_semibold

static func _load_font_from_path(font_path: String, bold: bool) -> Font:
	var font_file := FontFile.new()
	var absolute_path := ProjectSettings.globalize_path(font_path)
	if FileAccess.file_exists(absolute_path):
		var font_bytes := FileAccess.get_file_as_bytes(absolute_path)
		if not font_bytes.is_empty():
			font_file.data = font_bytes
			return font_file
	if font_file.load_dynamic_font(absolute_path) == OK:
		return font_file

	var fallback := SystemFont.new()
	fallback.font_names = PackedStringArray([
		"Titillium Web",
		"Segoe UI Semibold" if bold else "Segoe UI",
		"Arial",
	])
	fallback.font_weight = 600 if bold else 400
	return fallback

static func make_panel_style(background_color: Color, border_color: Color, border_width: int = 2, corner_radius: int = 10, shadow_size: int = 6, shadow_opacity: float = 0.18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(0.0, 0.0, 0.0, shadow_opacity)
	style.shadow_size = shadow_size
	style.content_margin_left = 2
	style.content_margin_top = 2
	style.content_margin_right = 2
	style.content_margin_bottom = 2
	return style
