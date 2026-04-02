extends CharacterBody3D

const RoomConstants := preload("res://scripts/room/room_constants.gd")
const SPEED: float = 5.0
const FAST_SPEED: float = 15.0
const ROOM_MARGIN: float = RoomConstants.DEFAULT_PLAYER_MARGIN
const BODY_TURN_SMOOTH: float = 10.0

@export var room_camera_controller_path: NodePath

var skin_ui: SkinPicker
var room_bounds_half_extents: Vector2 = RoomConstants.DEFAULT_ROOM_HALF_EXTENTS - Vector2.ONE * ROOM_MARGIN
var room_floor_y: float = 0.0

@onready var rig: MinecraftRig = $MinecraftRig
@onready var legacy_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var room_camera_controller: Node = get_node_or_null(room_camera_controller_path)

func _ready() -> void:
	_normalize_player_pose()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_spawn_ui()
	if legacy_camera != null:
		legacy_camera.current = false

func _spawn_ui() -> void:
	skin_ui = preload("res://scripts/skin_picker.gd").new()
	skin_ui.rig_node = rig
	skin_ui.player_node = self
	add_child(skin_ui)

func _unhandled_input(event: InputEvent) -> void:
	if room_camera_controller != null:
		var camera_handled: bool = room_camera_controller.handle_input_event(event)
		if camera_handled:
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = _get_input_vector()
	var speed: float = FAST_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
	var move_dir: Vector3 = _get_move_direction(input_vector)

	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	velocity = move_dir * speed
	move_and_slide()
	_snap_to_floor()
	_clamp_player_to_room_bounds()

	if Vector2(velocity.x, velocity.z).length() > 0.05:
		var target_body_yaw := atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, target_body_yaw, min(1.0, delta * BODY_TURN_SMOOTH))

func _get_input_vector() -> Vector2:
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_vector.y += 1.0
	if Input.is_key_pressed(KEY_S):
		input_vector.y -= 1.0
	return input_vector

func _get_move_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() <= 0.0001:
		return Vector3.ZERO

	var active_camera := get_active_camera()
	if active_camera == null:
		return Vector3(input_vector.x, 0.0, -input_vector.y)

	var forward := -active_camera.global_basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()

	var right := active_camera.global_basis.x
	right.y = 0.0
	if right.length_squared() <= 0.0001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()

	return right * input_vector.x + forward * input_vector.y

func _clamp_player_to_room_bounds() -> void:
	var min_x: float = -room_bounds_half_extents.x
	var max_x: float = room_bounds_half_extents.x
	var min_z: float = -room_bounds_half_extents.y
	var max_z: float = room_bounds_half_extents.y

	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.z = clamp(global_position.z, min_z, max_z)

func set_room_bounds_half_extents(next_bounds: Vector2) -> void:
	room_bounds_half_extents = Vector2(
		max(1.0, next_bounds.x),
		max(1.0, next_bounds.y)
	)
	_clamp_player_to_room_bounds()

func set_floor_y(next_floor_y: float) -> void:
	room_floor_y = next_floor_y
	_snap_to_floor()

func get_active_camera() -> Camera3D:
	if room_camera_controller != null and room_camera_controller.has_method("get_camera"):
		return room_camera_controller.call("get_camera") as Camera3D
	return legacy_camera

func reset_room_camera() -> void:
	if room_camera_controller != null and room_camera_controller.has_method("reset_camera"):
		room_camera_controller.reset_camera()

func _normalize_player_pose() -> void:
	rotation = Vector3(0.0, rotation.y, 0.0)
	_snap_to_floor()

func _snap_to_floor() -> void:
	global_position.y = room_floor_y
