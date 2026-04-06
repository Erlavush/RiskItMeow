@tool
class_name PlacementBrowserCard
extends PanelContainer

signal place_requested(item_id: String)
signal buy_requested(item_id: String)

const PlacementPreviewCache := preload("res://scripts/placement/placement_preview_cache.gd")
const PlacementUiStyles := preload("res://scripts/placement/placement_ui_styles.gd")

var _item_id := ""
var _mode := "inventory"
var _available_count := 0
var _owned_total := 0
var _pending_item_def: Dictionary = {}
var _action_button: Button
var _count_label: Label
var _title_label: Label
var _surface_label: Label
var _preview_image: TextureRect
var _preview_placeholder: Label

func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()
	if not _pending_item_def.is_empty():
		_apply_config(_pending_item_def)

func configure(item_def: Dictionary, mode: String, available_count: int, owned_total: int, item_factory: Callable) -> void:
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
	_action_button.text = "Buy" if _mode == "shop" else "Place"
	_action_button.disabled = _is_action_disabled()
	PlacementUiStyles.apply_button_style(
		_action_button,
		Color(0.58, 0.38, 0.18, 0.98) if _mode == "shop" else Color(0.22, 0.52, 0.34, 0.98),
		Color(0.96, 0.74, 0.34, 0.98) if _mode == "shop" else Color(0.42, 0.98, 0.62, 0.98),
		Color(0.99, 0.98, 0.95, 1.0)
	)
	_apply_preview_media(item_def)

func _build_ui() -> void:
	custom_minimum_size = Vector2(172.0, 232.0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(156.0, 118.0)
	preview_frame.add_theme_stylebox_override(
		"panel",
		PlacementUiStyles.make_panel_style(Color(0.06, 0.08, 0.1, 1.0), Color(0.2, 0.28, 0.36, 0.98), 1, 10)
	)
	layout.add_child(preview_frame)

	var preview_root := Control.new()
	preview_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_root.custom_minimum_size = Vector2(156.0, 118.0)
	preview_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_frame.add_child(preview_root)

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

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(_title_label)

	_surface_label = Label.new()
	_surface_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_surface_label.add_theme_font_size_override("font_size", 11)
	_surface_label.modulate = Color(0.88, 0.92, 1.0, 0.78)
	layout.add_child(_surface_label)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 11)
	layout.add_child(_count_label)

	_action_button = Button.new()
	_action_button.custom_minimum_size = Vector2(0.0, 34.0)
	_action_button.pressed.connect(_on_action_button_pressed)
	layout.add_child(_action_button)

func _build_surface_badge(item_def: Dictionary) -> String:
	var surface_kind := String(item_def.get("placement_surface_kind", "floor"))
	if surface_kind == "surface":
		return "Wall Item"
	return "Floor Item"

func _build_count_text() -> String:
	if _mode == "shop":
		return "Owned: %d | Available: %d" % [_owned_total, _available_count]
	return "Available: %d | Owned: %d" % [_available_count, _owned_total]

func _is_action_disabled() -> bool:
	if _mode == "shop":
		return false
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
