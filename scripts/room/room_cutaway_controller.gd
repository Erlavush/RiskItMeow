class_name RoomCutawayController
extends Node

const RoomConstants := preload("res://scripts/room/room_constants.gd")

@export var room_shell_path: NodePath
@export var room_camera_controller_path: NodePath
@export var placement_manager_path: NodePath
@export_range(0.2, 0.98, 0.01) var roof_show_dot_threshold: float = 0.86
@export var enable_cutaway := true

var _room_shell: RoomShell
var _room_camera_controller: Node
var _placement_manager: PlacementManager
var _last_wall_cutaways: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
}
var _last_roof_cutaway := false

func _ready() -> void:
	_room_shell = get_node_or_null(room_shell_path) as RoomShell
	_room_camera_controller = get_node_or_null(room_camera_controller_path)
	_placement_manager = get_node_or_null(placement_manager_path) as PlacementManager
	_apply_cutaway_state(true)

func _process(_delta: float) -> void:
	_apply_cutaway_state()

func _apply_cutaway_state(force: bool = false) -> void:
	if _room_shell == null:
		return

	if not enable_cutaway:
		if force:
			_room_shell.clear_surface_cutaways()
			if _placement_manager != null:
				_placement_manager.clear_wall_surface_cutaways()
		return

	var camera := _get_active_camera()
	if camera == null:
		return

	var local_camera := _room_shell.to_local(camera.global_position)
	var next_wall_cutaways := {
		RoomConstants.WALL_BACK: local_camera.z < 0.0,
		RoomConstants.WALL_LEFT: local_camera.x < 0.0,
		RoomConstants.WALL_FRONT: local_camera.z > 0.0,
		RoomConstants.WALL_RIGHT: local_camera.x > 0.0,
	}

	for surface_name in RoomConstants.WALL_SURFACES:
		var surface_key := String(surface_name)
		var next_value := bool(next_wall_cutaways.get(surface_key, false))
		if force or bool(_last_wall_cutaways.get(surface_key, false)) != next_value:
			_last_wall_cutaways[surface_key] = next_value
			_room_shell.set_surface_cutaway(surface_key, next_value)
			if _placement_manager != null:
				_placement_manager.set_wall_surface_cutaway(surface_key, next_value)

	var room_center := _room_shell.get_room_center()
	var to_room := (room_center - camera.global_position).normalized()
	var next_roof_cutaway := absf(to_room.y) < roof_show_dot_threshold
	if force or _last_roof_cutaway != next_roof_cutaway:
		_last_roof_cutaway = next_roof_cutaway
		_room_shell.set_surface_cutaway(RoomConstants.CEILING_SURFACE, next_roof_cutaway)

func _get_active_camera() -> Camera3D:
	if _room_camera_controller != null and _room_camera_controller.has_method("get_camera"):
		return _room_camera_controller.call("get_camera") as Camera3D
	return get_viewport().get_camera_3d()
