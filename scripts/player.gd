extends CharacterBody3D

const SPEED: float = 5.0
const FAST_SPEED: float = 15.0
const ROOM_MARGIN: float = 0.7
const BODY_TURN_SMOOTH: float = 10.0

@export var room_camera_controller_path: NodePath

var skin_ui: SkinPicker
var room_bounds_half_extents: Vector2 = Vector2(5.3, 5.3)
var build_mode_controller: Node

@onready var rig: MinecraftRig = $MinecraftRig
@onready var legacy_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var room_camera_controller: RoomViewCameraController = get_node_or_null(room_camera_controller_path) as RoomViewCameraController

func _ready() -> void:
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
	if build_mode_controller != null and build_mode_controller.has_method("handle_player_input_event"):
		var handled: bool = bool(build_mode_controller.call("handle_player_input_event", event))
		if handled:
			get_viewport().set_input_as_handled()
			return

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
	var min_x: float = -room_bounds_half_extents.x + ROOM_MARGIN
	var max_x: float = room_bounds_half_extents.x - ROOM_MARGIN
	var min_z: float = -room_bounds_half_extents.y + ROOM_MARGIN
	var max_z: float = room_bounds_half_extents.y - ROOM_MARGIN

	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.z = clamp(global_position.z, min_z, max_z)

func set_room_bounds_half_extents(next_bounds: Vector2) -> void:
	room_bounds_half_extents = Vector2(
		max(1.0, next_bounds.x),
		max(1.0, next_bounds.y)
	)
	_clamp_player_to_room_bounds()

func set_build_mode_controller(controller: Node) -> void:
	build_mode_controller = controller

func get_active_camera() -> Camera3D:
	if room_camera_controller != null:
		return room_camera_controller.get_camera()
	return legacy_camera

func reset_room_camera() -> void:
	if room_camera_controller != null:
		room_camera_controller.reset_camera()
