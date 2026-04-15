class_name RoomCutawayController
extends Node

@export var room_shell_path: NodePath
@export var room_camera_controller_path: NodePath
@export var placement_manager_path: NodePath
@export var player_path: NodePath
@export_range(0.2, 0.98, 0.01) var roof_show_dot_threshold: float = 0.26
@export var enable_cutaway := true

var _room_shell: RoomShell
var _room_camera_controller: Node
var _placement_manager: PlacementManager
var _player: Node
var _last_wall_cutaways: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
}
var _last_roof_cutaway := false
var _last_cutaway_token := ""

func _ready() -> void:
	_room_shell = get_node_or_null(room_shell_path) as RoomShell
	_room_camera_controller = get_node_or_null(room_camera_controller_path)
	_placement_manager = get_node_or_null(placement_manager_path) as PlacementManager
	_player = get_node_or_null(player_path)
	_apply_cutaway_state(true)

func _process(_delta: float) -> void:
	_apply_cutaway_state()

func _apply_cutaway_state(force: bool = false) -> void:
	if _room_shell == null:
		return

	if not enable_cutaway:
		if force:
			_clear_cutaway_state()
		return

	var camera_mode := ""
	if _player != null and _player.has_method("get_camera_mode"):
		camera_mode = String(_player.call("get_camera_mode"))
		if camera_mode == "first_person":
			_clear_cutaway_state()
			return

	var camera := _get_active_camera()
	if camera == null:
		return
	var next_token := _build_cutaway_token(camera, camera_mode)
	if not force and next_token == _last_cutaway_token:
		return
	_last_cutaway_token = next_token

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
	var next_roof_cutaway := absf(to_room.y) > roof_show_dot_threshold
	if force or _last_roof_cutaway != next_roof_cutaway:
		_last_roof_cutaway = next_roof_cutaway
		_room_shell.set_surface_cutaway(RoomConstants.CEILING_SURFACE, next_roof_cutaway)
		if _placement_manager != null:
			_placement_manager.set_ceiling_surface_cutaway(next_roof_cutaway)

func _clear_cutaway_state() -> void:
	_last_cutaway_token = ""
	var needs_clear := _last_roof_cutaway
	for surface_name in RoomConstants.WALL_SURFACES:
		if bool(_last_wall_cutaways.get(surface_name, false)):
			needs_clear = true
			break
	if not needs_clear:
		return

	for surface_name in RoomConstants.WALL_SURFACES:
		_last_wall_cutaways[surface_name] = false
		_room_shell.set_surface_cutaway(surface_name, false)
		if _placement_manager != null:
			_placement_manager.set_wall_surface_cutaway(surface_name, false)

	_last_roof_cutaway = false
	_room_shell.set_surface_cutaway(RoomConstants.CEILING_SURFACE, false)
	if _placement_manager != null:
		_placement_manager.set_ceiling_surface_cutaway(false)

func _build_cutaway_token(camera: Camera3D, camera_mode: String) -> String:
	if camera == null:
		return ""

	var camera_position := camera.global_position
	return "%s|%.3f|%.3f|%.3f" % [
		camera_mode,
		camera_position.x,
		camera_position.y,
		camera_position.z,
	]

func _get_active_camera() -> Camera3D:
	if _player != null and _player.has_method("get_active_camera"):
		var player_camera := _player.call("get_active_camera") as Camera3D
		if player_camera != null:
			return player_camera
	if _room_camera_controller != null and _room_camera_controller.has_method("get_camera"):
		return _room_camera_controller.call("get_camera") as Camera3D
	return get_viewport().get_camera_3d()
