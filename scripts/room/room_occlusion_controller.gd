class_name RoomOcclusionController
extends Node

const RoomConstants := preload("res://scripts/room/room_constants.gd")

@export var player_path: NodePath
@export var room_shell_path: NodePath
@export_range(0.1, 1.2, 0.01) var wall_occlusion_angle_threshold: float = 0.35
@export_range(0.2, 0.95, 0.01) var ceiling_occlusion_vertical_ratio: float = 0.52

var _last_visibility_key: String = ""

@onready var player: Node = get_node_or_null(player_path)
@onready var room_shell: Node = get_node_or_null(room_shell_path)

func _ready() -> void:
	if player != null and room_shell != null and player.has_method("set_room_bounds_half_extents"):
		player.call("set_room_bounds_half_extents", room_shell.get_inner_half_extents())

func _process(_delta: float) -> void:
	if player == null or room_shell == null:
		return

	if not player.has_method("get_active_camera"):
		return

	var active_camera: Camera3D = player.call("get_active_camera") as Camera3D
	if active_camera == null:
		return

	var room_center: Vector3 = room_shell.get_room_center()
	var offset: Vector3 = active_camera.global_position - room_center
	if offset.length_squared() <= 0.0001:
		return

	var angle := atan2(offset.x, offset.z)
	var threshold := wall_occlusion_angle_threshold

	var wall_front := not (angle > -PI * 0.5 + threshold and angle < PI * 0.5 - threshold)
	var wall_right := not (angle > threshold and angle < PI - threshold)
	var wall_back := not (angle > PI * 0.5 + threshold or angle < -PI * 0.5 - threshold)
	var wall_left := not (angle > -PI + threshold and angle < -threshold)

	var orbit_distance := offset.length()
	var vertical_ratio: float = abs(offset.y) / max(orbit_distance, 0.0001)
	var ceiling: bool = not (vertical_ratio > ceiling_occlusion_vertical_ratio)

	var visibility := {
		RoomConstants.WALL_FRONT: wall_front,
		RoomConstants.WALL_RIGHT: wall_right,
		RoomConstants.WALL_BACK: wall_back,
		RoomConstants.WALL_LEFT: wall_left,
		RoomConstants.CEILING_SURFACE: ceiling,
	}
	var visibility_key := JSON.stringify(visibility)
	if visibility_key == _last_visibility_key:
		return

	_last_visibility_key = visibility_key
	for surface_name in visibility.keys():
		room_shell.set_surface_visible(surface_name, visibility[surface_name])
