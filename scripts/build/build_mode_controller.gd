class_name BuildModeController
extends Node

const BuildItemRegistry := preload("res://scripts/build/build_item_registry.gd")
const PlacementResolver := preload("res://scripts/build/placement_resolver.gd")
const PlacementTypes := preload("res://scripts/build/placement_types.gd")

@export var player_path: NodePath
@export var room_shell_path: NodePath
@export var toolbar_path: NodePath

var build_mode_enabled: bool = false
var selected_index: int = 0
var rotation_step: int = 0
var placed_items: Array[Dictionary] = []
var _preview_placement: Dictionary = {}
var _placement_valid: bool = false
var _placement_counter: int = 0

var _resolver: PlacementResolver
var _item_nodes: Dictionary = {}
var _preview_root: Node3D
var _placed_root: Node3D
var _preview_node: Node3D

@onready var player: Node = get_node_or_null(player_path)
@onready var room_shell: Node = get_node_or_null(room_shell_path)
@onready var toolbar: CanvasLayer = get_node_or_null(toolbar_path) as CanvasLayer

func _ready() -> void:
	_resolver = PlacementResolver.new()
	if player != null and player.has_method("set_build_mode_controller"):
		player.call("set_build_mode_controller", self)
	_ensure_world_nodes()
	_refresh_toolbar()

func _process(_delta: float) -> void:
	if not build_mode_enabled:
		if _preview_root != null:
			_preview_root.visible = false
		return

	_update_preview()
	_refresh_toolbar()

func handle_player_input_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_B:
				_set_build_mode_enabled(not build_mode_enabled)
				return true
			KEY_R:
				if build_mode_enabled:
					rotation_step = (rotation_step + 1) % 4
					_update_preview()
					return true
			KEY_ESCAPE:
				if build_mode_enabled:
					_set_build_mode_enabled(false)
					return true
			KEY_1, KEY_2, KEY_3, KEY_4:
				if build_mode_enabled:
					selected_index = clampi(key_event.keycode - KEY_1, 0, BuildItemRegistry.get_catalog_order().size() - 1)
					rotation_step = 0
					_rebuild_preview_node()
					_update_preview()
					return true

	if not build_mode_enabled:
		return false

	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_commit_preview_placement()
			return true
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_set_build_mode_enabled(false)
			return true

	return false

func get_placed_items() -> Array[Dictionary]:
	return placed_items.duplicate(true)

func get_floor_obstacles() -> Array[Dictionary]:
	return _resolver.get_floor_obstacles(placed_items)

func is_build_mode_active() -> bool:
	return build_mode_enabled

func _set_build_mode_enabled(enabled: bool) -> void:
	build_mode_enabled = enabled
	if build_mode_enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_rebuild_preview_node()
		_update_preview()
	else:
		_preview_placement.clear()
		_placement_valid = false
		if _preview_root != null:
			_preview_root.visible = false
	_refresh_toolbar()

func _ensure_world_nodes() -> void:
	if get_parent() == null:
		return

	_placed_root = get_parent().get_node_or_null("PlacedItems") as Node3D
	if _placed_root == null:
		_placed_root = Node3D.new()
		_placed_root.name = "PlacedItems"
		get_parent().call_deferred("add_child", _placed_root)

	_preview_root = get_parent().get_node_or_null("PlacementPreview") as Node3D
	if _preview_root == null:
		_preview_root = Node3D.new()
		_preview_root.name = "PlacementPreview"
		get_parent().call_deferred("add_child", _preview_root)

func _update_preview() -> void:
	if player == null or room_shell == null or _preview_root == null:
		return

	var camera := _get_active_camera()
	if camera == null:
		return

	if _preview_node == null:
		_rebuild_preview_node()
	if _preview_node == null:
		return

	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var ray_origin := camera.project_ray_origin(viewport_center)
	var ray_direction := camera.project_ray_normal(viewport_center)
	var definition := _get_selected_definition()
	var rotation_y := rotation_step * PI * 0.5
	_preview_placement = _resolver.resolve_from_view_ray(
		ray_origin,
		ray_direction,
		definition,
		room_shell,
		placed_items,
		rotation_y
	)
	_placement_valid = not _preview_placement.is_empty()

	_preview_root.visible = true
	if _placement_valid:
		_apply_placement_to_node(_preview_node, _preview_placement)
		BuildItemRegistry.set_preview_validity(_preview_node, true)
	else:
		BuildItemRegistry.set_preview_validity(_preview_node, false)
		_preview_node.position = ray_origin + ray_direction * 2.5
		_preview_node.rotation = Vector3.ZERO
		_preview_node.rotation.y = rotation_y

func _commit_preview_placement() -> void:
	if not _placement_valid or _preview_placement.is_empty():
		return

	var definition := _get_selected_definition()
	var item_id := str(definition.get("id", ""))
	var instance_id := "placed_%02d" % _placement_counter
	_placement_counter += 1

	var placement := _preview_placement.duplicate(true)
	placement["instance_id"] = instance_id
	placement["item_id"] = item_id
	placed_items.append(placement)

	var node := BuildItemRegistry.create_item_node(item_id)
	node.name = instance_id
	_apply_placement_to_node(node, placement)
	_item_nodes[instance_id] = node
	if _placed_root != null:
		_placed_root.add_child(node)

	_update_preview()

func _rebuild_preview_node() -> void:
	if _preview_root == null:
		return
	for child in _preview_root.get_children():
		child.queue_free()

	_preview_node = BuildItemRegistry.create_item_node(str(_get_selected_definition().get("id", "")), true)
	_preview_root.add_child(_preview_node)

func _apply_placement_to_node(node: Node3D, placement: Dictionary) -> void:
	node.position = placement.get("position", Vector3.ZERO)
	node.rotation = Vector3.ZERO
	node.rotation.y = float(placement.get("rotation_y", 0.0))

func _get_selected_definition() -> Dictionary:
	var order := BuildItemRegistry.get_catalog_order()
	var item_id := order[clampi(selected_index, 0, order.size() - 1)]
	return BuildItemRegistry.get_definition(item_id)

func _refresh_toolbar() -> void:
	if toolbar == null or not toolbar.has_method("set_state"):
		return

	var definition := _get_selected_definition()
	var selected_text := "%s [%s]" % [
		str(definition.get("label", "")),
		str(definition.get("family", ""))
	]
	var status_text := "Target valid" if _placement_valid else "Target invalid"
	var helper_text := "B toggle, 1-4 swap items, R rotate, Left click place, Right click or Esc cancel."
	if build_mode_enabled and str(definition.get("family", "")) == PlacementTypes.FAMILY_SURFACE and not _placement_valid:
		helper_text = "Place or aim at a coffee table before placing the flower vase."
	toolbar.call("set_state", build_mode_enabled, selected_text, status_text, helper_text)

func _get_active_camera() -> Camera3D:
	if player == null or not player.has_method("get_active_camera"):
		return null
	return player.call("get_active_camera") as Camera3D
