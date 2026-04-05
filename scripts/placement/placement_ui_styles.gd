class_name PlacementUiStyles
extends RefCounted

static var _style_cache: Dictionary = {}

static func apply_button_style(button: Button, bg_color: Color, border_color: Color, font_color: Color) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", make_panel_style(bg_color, border_color, 1, 8))
	button.add_theme_stylebox_override("hover", make_panel_style(bg_color.lerp(Color.WHITE, 0.12), border_color.lerp(Color.WHITE, 0.22), 1, 8))
	button.add_theme_stylebox_override("pressed", make_panel_style(bg_color.lerp(Color.BLACK, 0.18), border_color, 1, 8))
	button.add_theme_stylebox_override("disabled", make_panel_style(bg_color.lerp(Color.BLACK, 0.45), border_color.lerp(Color.BLACK, 0.55), 1, 8))
	button.add_theme_stylebox_override("focus", make_panel_style(bg_color, border_color, 1, 8))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color.lerp(Color.DIM_GRAY, 0.35))

static func make_panel_style(background_color: Color, border_color: Color, border_width: int = 2, corner_radius: int = 10) -> StyleBoxFlat:
	var cache_key := "%s|%s|%d|%d" % [
		background_color.to_html(true),
		border_color.to_html(true),
		border_width,
		corner_radius,
	]
	var cached_style := _style_cache.get(cache_key) as StyleBoxFlat
	if cached_style != null:
		return cached_style

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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	style.shadow_size = 6
	_style_cache[cache_key] = style
	return style
