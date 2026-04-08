@tool
class_name PlacementBrowserCard
extends PanelContainer

signal place_requested(item_id: String)
signal buy_requested(item_id: String)

var _item_id := ""
var _mode := "inventory"
var _available_count := 0
var _owned_total := 0
var _pending_item_def: Dictionary = {}
var _action_button: Button
var _count_label: Label
var _title_label: Label
var _surface_label: Label
var _surface_badge: PanelContainer
var _preview_image: TextureRect
var _preview_placeholder: Label
var _preview_frame: PanelContainer
var _card_hovered := false
var _hover_tween: Tween

func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()
	mouse_entered.connect(_on_card_mouse_entered)
	mouse_exited.connect(_on_card_mouse_exited)
	if not _pending_item_def.is_empty():
		_apply_config(_pending_item_def)
	_refresh_visual_state()

func configure(item_def: Dictionary, mode: String, available_count: int, owned_total: int, _item_factory: Callable) -> void:
	_item_id = String(item_def.get("id", ""))
	_mode = mode
	_available_count = available_count
	_owned_total = owned_total
	_pending_item_def = item_def.duplicate(true)
	if not is_node_ready():
		return
	_apply_config(_pending_item_def)

func _apply_config(item_def: Dictionary) -> void:
	_title_label.text = String(item_def.get("display_name", _item_id))
	_surface_label.text = _build_surface_badge(item_def)
	_count_label.text = _build_count_text()
	_action_button.text = "Buy" if _mode == "shop" else ("Place" if PlacementInventoryCatalog.supports_runtime_placement(item_def) else "Planned")
	_action_button.disabled = _is_action_disabled()
	PlacementUiStyles.apply_button_style(
		_action_button,
		PlacementUiStyles.COLOR_ACCENT if _mode == "shop" else PlacementUiStyles.COLOR_SUCCESS,
		PlacementUiStyles.COLOR_ACCENT_BRIGHT if _mode == "shop" else PlacementUiStyles.COLOR_SUCCESS_BORDER,
		PlacementUiStyles.COLOR_TEXT
	)
	_apply_preview_media(item_def)
	_refresh_visual_state()

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(126.0, 198.0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	_preview_frame = PanelContainer.new()
	_preview_frame.custom_minimum_size = Vector2(0.0, 82.0)
	_preview_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_preview_frame)

	var preview_root := Control.new()
	preview_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_root.custom_minimum_size = Vector2(0.0, 82.0)
	preview_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_frame.add_child(preview_root)

	_preview_image = TextureRect.new()
	_preview_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_image.visible = false
	preview_root.add_child(_preview_image)

	_preview_placeholder = Label.new()
	_preview_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_placeholder.add_theme_font_size_override("font_size", 12)
	_preview_placeholder.visible = false
	preview_root.add_child(_preview_placeholder)

	_surface_badge = PanelContainer.new()
	_surface_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	layout.add_child(_surface_badge)

	var badge_margin := MarginContainer.new()
	badge_margin.add_theme_constant_override("margin_left", 8)
	badge_margin.add_theme_constant_override("margin_top", 3)
	badge_margin.add_theme_constant_override("margin_right", 8)
	badge_margin.add_theme_constant_override("margin_bottom", 3)
	_surface_badge.add_child(badge_margin)

	_surface_label = Label.new()
	_surface_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_surface_label.add_theme_font_size_override("font_size", 10)
	badge_margin.add_child(_surface_label)

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(_title_label)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_count_label.add_theme_font_size_override("font_size", 10)
	layout.add_child(_count_label)

	_action_button = Button.new()
	_action_button.custom_minimum_size = Vector2(0.0, 32.0)
	_action_button.pressed.connect(_on_action_button_pressed)
	layout.add_child(_action_button)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5

func _build_surface_badge(item_def: Dictionary) -> String:
	return PlacementInventoryCatalog.get_mount_badge_text(item_def)

func _build_count_text() -> String:
	if _mode == "shop":
		return "Own %d | Avail %d" % [_owned_total, _available_count]
	return "Avail %d | Own %d" % [_available_count, _owned_total]

func _is_action_disabled() -> bool:
	if _mode == "shop":
		return false
	if not PlacementInventoryCatalog.supports_runtime_placement(_pending_item_def):
		return true
	return _available_count <= 0

func _on_action_button_pressed() -> void:
	if _item_id.is_empty():
		return
	if _mode == "shop":
		buy_requested.emit(_item_id)
		return
	place_requested.emit(_item_id)

func _apply_preview_media(item_def: Dictionary) -> void:
	var preview_texture := PlacementPreviewCache.load_preview_texture(item_def)
	if preview_texture != null:
		_preview_image.texture = preview_texture
		_preview_image.visible = true
		_preview_placeholder.visible = false
		return

	_preview_image.texture = null
	_preview_image.visible = false
	_preview_placeholder.text = "No\nPreview"
	_preview_placeholder.visible = true

func _refresh_visual_state() -> void:
	var card_bg := PlacementUiStyles.COLOR_CARD_HOVER if _card_hovered else PlacementUiStyles.COLOR_CARD
	var card_border := PlacementUiStyles.COLOR_BORDER_STRONG if _card_hovered else PlacementUiStyles.COLOR_BORDER_SOFT
	PlacementUiStyles.apply_panel_style(self, card_bg, card_border, 1, 14, 8, 0.22)
	PlacementUiStyles.apply_panel_style(
		_preview_frame,
		PlacementUiStyles.COLOR_INPUT.lerp(PlacementUiStyles.COLOR_BG_DEEP, 0.2),
		PlacementUiStyles.COLOR_BORDER if _card_hovered else PlacementUiStyles.COLOR_BORDER_SOFT,
		1,
		12,
		3,
		0.1
	)
	PlacementUiStyles.apply_panel_style(
		_surface_badge,
		PlacementUiStyles.COLOR_PANEL_ALT if _card_hovered else PlacementUiStyles.COLOR_PANEL_SOFT,
		PlacementUiStyles.COLOR_BORDER_STRONG if _card_hovered else PlacementUiStyles.COLOR_BORDER,
		1,
		16,
		2,
		0.08
	)
	PlacementUiStyles.apply_label_color(_title_label, PlacementUiStyles.COLOR_TEXT)
	PlacementUiStyles.apply_label_color(_surface_label, PlacementUiStyles.COLOR_TEXT_MUTED)
	PlacementUiStyles.apply_label_color(_count_label, PlacementUiStyles.COLOR_TEXT_SUBTLE)
	_preview_placeholder.add_theme_color_override("font_color", PlacementUiStyles.COLOR_TEXT_SUBTLE)

func _on_card_mouse_entered() -> void:
	_card_hovered = true
	_refresh_visual_state()
	_animate_hover_scale(Vector2.ONE * 1.02)

func _on_card_mouse_exited() -> void:
	_card_hovered = false
	_refresh_visual_state()
	_animate_hover_scale(Vector2.ONE)

func _animate_hover_scale(target_scale: Vector2) -> void:
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, 0.12)
