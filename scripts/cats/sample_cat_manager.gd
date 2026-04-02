class_name SampleCatManager
extends Node

const SAMPLE_CAT_SCENE := preload("res://scenes/cats/sample_cat.tscn")

const SPAWN_OFFSETS := [
	Vector2(1.1, 0.0),
	Vector2(-1.1, 0.0),
	Vector2(0.0, 1.1),
	Vector2(0.0, -1.1),
	Vector2(1.6, 1.2),
	Vector2(-1.6, 1.2),
	Vector2(1.6, -1.2),
	Vector2(-1.6, -1.2),
]

const CAT_PALETTES := [
	{
		"fur_color": Color(0.89, 0.63, 0.34, 1.0),
		"stripe_color": Color(0.39, 0.24, 0.14, 1.0),
		"accent_color": Color(0.97, 0.88, 0.8, 1.0),
	},
	{
		"fur_color": Color(0.42, 0.44, 0.52, 1.0),
		"stripe_color": Color(0.17, 0.18, 0.23, 1.0),
		"accent_color": Color(0.87, 0.88, 0.94, 1.0),
	},
	{
		"fur_color": Color(0.83, 0.79, 0.72, 1.0),
		"stripe_color": Color(0.54, 0.47, 0.38, 1.0),
		"accent_color": Color(0.95, 0.91, 0.86, 1.0),
	},
]

@export var player_path: NodePath
@export var room_shell_path: NodePath
@export var build_mode_controller_path: NodePath
@export var cats_root_path: NodePath
@export_range(1, 4, 1) var initial_cat_count: int = 2
@export var player_clearance: float = 0.95
@export var obstacle_clearance: float = 0.48
@export var cat_clearance: float = 0.82
@export var min_idle_duration: float = 1.1
@export var max_idle_duration: float = 3.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cats: Array = []

@onready var player: Node3D = get_node_or_null(player_path) as Node3D
@onready var room_shell: Node = get_node_or_null(room_shell_path)
@onready var build_mode_controller: Node = get_node_or_null(build_mode_controller_path)
@onready var cats_root: Node3D = get_node_or_null(cats_root_path) as Node3D

func _ready() -> void:
	_rng.randomize()
	_ensure_cats_root()
	_spawn_initial_cats()

func _physics_process(_delta: float) -> void:
	var room_bounds: Vector2 = _get_room_bounds()
	var floor_y: float = _get_floor_y()
	var room_origin: Vector3 = _get_room_origin()
	var obstacles: Array = _get_floor_obstacles()

	for cat in _cats:
		if not is_instance_valid(cat):
			continue

		cat.set_room_context(room_bounds, floor_y, room_origin)
		var cat_position: Vector3 = cat.get_floor_position()
		if _point_blocked(cat_position, obstacles, 0.12) and (cat.is_idle() or cat_position.distance_to(cat.get_target_position()) < 0.35):
			cat.set_wander_target(_pick_spawn_position(cat))

func _spawn_initial_cats() -> void:
	for index in range(initial_cat_count):
		var cat = SAMPLE_CAT_SCENE.instantiate()
		if cat == null:
			continue

		cat.name = "SampleCat%s" % str(index + 1)
		_apply_palette(cat, index)
		cats_root.add_child(cat)
		cat.set_room_context(_get_room_bounds(), _get_floor_y(), _get_room_origin())
		cat.global_position = _pick_spawn_position(cat)
		cat.idle_finished.connect(_on_cat_idle_finished)
		cat.wander_finished.connect(_on_cat_wander_finished)
		_cats.append(cat)
		cat.set_idle(_rng.randf_range(min_idle_duration, max_idle_duration))

func _on_cat_idle_finished(cat) -> void:
	if cat == null or not is_instance_valid(cat):
		return

	cat.set_wander_target(_pick_wander_target(cat))

func _on_cat_wander_finished(cat) -> void:
	if cat == null or not is_instance_valid(cat):
		return

	cat.set_idle(_rng.randf_range(min_idle_duration, max_idle_duration))

func _ensure_cats_root() -> void:
	if cats_root != null:
		return

	cats_root = Node3D.new()
	cats_root.name = "Cats"
	if get_parent() != null:
		get_parent().call_deferred("add_child", cats_root)

func _pick_spawn_position(ignore_cat = null) -> Vector3:
	var base_position: Vector3 = _get_player_floor_position()
	var obstacles: Array = _get_floor_obstacles()
	for offset in SPAWN_OFFSETS:
		var candidate: Vector3 = _clamp_to_room(Vector3(
			base_position.x + offset.x,
			_get_floor_y(),
			base_position.z + offset.y
		))
		if _is_candidate_clear(candidate, obstacles, ignore_cat):
			return candidate

	for _attempt in range(24):
		var room_bounds: Vector2 = _get_room_bounds()
		var room_origin: Vector3 = _get_room_origin()
		var candidate: Vector3 = _clamp_to_room(Vector3(
			room_origin.x + _rng.randf_range(-room_bounds.x, room_bounds.x),
			_get_floor_y(),
			room_origin.z + _rng.randf_range(-room_bounds.y, room_bounds.y)
		))
		if _is_candidate_clear(candidate, obstacles, ignore_cat):
			return candidate

	return _clamp_to_room(Vector3(_get_room_origin().x, _get_floor_y(), _get_room_origin().z))

func _pick_wander_target(ignore_cat) -> Vector3:
	var current_position: Vector3 = ignore_cat.get_floor_position()
	var player_position: Vector3 = _get_player_floor_position()
	var obstacles: Array = _get_floor_obstacles()
	var bias_to_player: bool = current_position.distance_to(player_position) > 3.4 or _rng.randf() < 0.35
	var center: Vector3 = player_position if bias_to_player else current_position
	var min_radius: float = 1.1 if bias_to_player else 0.85
	var max_radius: float = 2.2 if bias_to_player else 2.9

	for _attempt in range(28):
		var angle: float = _rng.randf_range(-PI, PI)
		var radius: float = _rng.randf_range(min_radius, max_radius)
		var candidate: Vector3 = _clamp_to_room(Vector3(
			center.x + cos(angle) * radius,
			_get_floor_y(),
			center.z + sin(angle) * radius
		))
		if _is_candidate_clear(candidate, obstacles, ignore_cat):
			return candidate

	return _pick_spawn_position(ignore_cat)

func _is_candidate_clear(candidate: Vector3, obstacles: Array, ignore_cat = null) -> bool:
	if _point_blocked(candidate, obstacles, obstacle_clearance):
		return false
	if _too_close_to_player(candidate):
		return false
	if _too_close_to_other_cats(candidate, ignore_cat):
		return false
	return true

func _point_blocked(candidate: Vector3, obstacles: Array, padding: float) -> bool:
	for obstacle in obstacles:
		var center: Vector3 = obstacle.get("center", Vector3.ZERO)
		var half: Vector2 = obstacle.get("half", Vector2.ZERO)
		if abs(candidate.x - center.x) <= half.x + padding and abs(candidate.z - center.z) <= half.y + padding:
			return true
	return false

func _too_close_to_player(candidate: Vector3) -> bool:
	if player == null:
		return false

	var player_position: Vector3 = _get_player_floor_position()
	return candidate.distance_to(player_position) < player_clearance

func _too_close_to_other_cats(candidate: Vector3, ignore_cat = null) -> bool:
	for cat in _cats:
		if cat == ignore_cat or not is_instance_valid(cat):
			continue
		if candidate.distance_to(cat.get_floor_position()) < cat_clearance:
			return true
	return false

func _apply_palette(cat, index: int) -> void:
	var palette: Dictionary = CAT_PALETTES[index % CAT_PALETTES.size()]
	cat.fur_color = palette.get("fur_color", cat.fur_color)
	cat.stripe_color = palette.get("stripe_color", cat.stripe_color)
	cat.accent_color = palette.get("accent_color", cat.accent_color)

func _get_floor_obstacles() -> Array:
	if build_mode_controller == null or not build_mode_controller.has_method("get_floor_obstacles"):
		return []
	return build_mode_controller.get_floor_obstacles()

func _get_room_bounds() -> Vector2:
	if room_shell != null and room_shell.has_method("get_inner_half_extents"):
		return room_shell.get_inner_half_extents()
	return Vector2(5.4, 5.4)

func _get_room_origin() -> Vector3:
	if room_shell is Node3D:
		return (room_shell as Node3D).global_position
	return Vector3.ZERO

func _get_floor_y() -> float:
	if room_shell != null and room_shell.has_method("get_floor_y"):
		return float(room_shell.get_floor_y())
	return 0.0

func _get_player_floor_position() -> Vector3:
	if player == null:
		return Vector3(_get_room_origin().x, _get_floor_y(), _get_room_origin().z)
	return Vector3(player.global_position.x, _get_floor_y(), player.global_position.z)

func _clamp_to_room(candidate: Vector3) -> Vector3:
	var room_bounds: Vector2 = _get_room_bounds()
	var room_origin: Vector3 = _get_room_origin()
	return Vector3(
		clampf(candidate.x, room_origin.x - room_bounds.x + 0.78, room_origin.x + room_bounds.x - 0.78),
		_get_floor_y(),
		clampf(candidate.z, room_origin.z - room_bounds.y + 0.78, room_origin.z + room_bounds.y - 0.78)
	)
