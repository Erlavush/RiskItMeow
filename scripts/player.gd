extends CharacterBody3D

enum CameraMode {
	FREECAM,
	THIRDPERSON,
	FIRSTPERSON,
}

const SPEED: float = 5.0
const FAST_SPEED: float = 15.0
const CAMERA_HEIGHT: float = 1.5
const FREECAM_START_OFFSET := Vector3(0.0, 1.5, 3.0)

const THIRD_PERSON_DISTANCE: float = 3.6
const FIRST_PERSON_DISTANCE: float = 0.0
const THIRD_PERSON_OFFSET := Vector2(0.65, 0.18)

const MIN_PITCH: float = -1.55
const MAX_PITCH: float = 1.55
const ROOM_MARGIN: float = 0.7

const CAMERA_DISTANCE_SMOOTH: float = 10.0
const CAMERA_OFFSET_SMOOTH: float = 10.0
const BODY_TURN_SMOOTH: float = 10.0

const CAMERA_COLLISION_MARGIN: float = 0.12
const CAMERA_COLLISION_SAMPLE_RADIUS: float = 0.18
const CAMERA_PITCH_SQUEEZE_THRESHOLD: float = 0.9599311 # 55 degrees in radians

const CAMERA_COLLISION_SAMPLES := [
	Vector3.ZERO,
	Vector3(1, 0, 0),
	Vector3(-1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, -1, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, -1),
]

var sensitivity: float = 0.005
var camera_mode: int = -1

var camera_yaw: float = 0.0
var camera_pitch: float = 0.0

var smoothed_camera_distance: float = THIRD_PERSON_DISTANCE
var smoothed_camera_offset: Vector2 = Vector2.ZERO

var skin_ui: SkinPicker
var room_bounds_half_extents: Vector2 = Vector2(5.3, 5.3)
var build_mode_controller: Node

@onready var rig: MinecraftRig = $MinecraftRig
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_spawn_ui()

	camera_yaw = rotation.y
	camera_pitch = 0.0

	spring_arm.add_excluded_object(get_rid())
	spring_arm.margin = CAMERA_COLLISION_MARGIN
	camera.h_offset = 0.0
	camera.v_offset = 0.0

	camera_pivot.top_level = true
	camera_pivot.global_position = global_position + FREECAM_START_OFFSET
	camera_pivot.global_rotation = Vector3(camera_pitch, camera_yaw, 0.0)

	spring_arm.spring_length = 0.0
	camera.transform = Transform3D.IDENTITY
	camera_mode = CameraMode.FREECAM
	rig.visible = true

	_refresh_camera_ui()

func _spawn_ui() -> void:
	skin_ui = preload("res://scripts/skin_picker.gd").new()
	skin_ui.rig_node = rig
	skin_ui.player_node = self
	add_child(skin_ui)

func _refresh_camera_ui() -> void:
	if skin_ui != null:
		skin_ui.call("_refresh_ui")

func _unhandled_input(event: InputEvent) -> void:
	if build_mode_controller != null and build_mode_controller.has_method("handle_player_input_event"):
		var handled: bool = bool(build_mode_controller.call("handle_player_input_event", event))
		if handled:
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion

		camera_yaw = wrapf(camera_yaw - motion.relative.x * sensitivity, -PI, PI)
		camera_pitch = clamp(camera_pitch - motion.relative.y * sensitivity, MIN_PITCH, MAX_PITCH)

		if camera_mode == CameraMode.FREECAM:
			camera_pivot.global_rotation = Vector3(camera_pitch, camera_yaw, 0.0)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			cycle_camera_mode()
		elif event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	var input_dir: Vector3 = _get_input_direction()
	var speed: float = FAST_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED

	if camera_mode == CameraMode.FREECAM:
		_update_freecam(delta, input_dir, speed)
		return

	_update_follow_movement(delta, input_dir, speed)
	_update_follow_camera(delta)

func _update_freecam(delta: float, input_dir: Vector3, speed: float) -> void:
	var camera_basis := Basis.from_euler(Vector3(camera_pitch, camera_yaw, 0.0))
	var move_dir := (
		camera_basis.x * input_dir.x
		+ camera_basis.y * input_dir.y
		+ camera_basis.z * input_dir.z
	)

	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	camera_pivot.global_position += move_dir * speed * delta
	camera_pivot.global_rotation = Vector3(camera_pitch, camera_yaw, 0.0)
	velocity = Vector3.ZERO

func _update_follow_movement(delta: float, input_dir: Vector3, speed: float) -> void:
	var flat_camera_basis := Basis.from_euler(Vector3(0.0, camera_yaw, 0.0))
	var move_dir := (
		flat_camera_basis.x * input_dir.x
		+ Vector3.UP * input_dir.y
		+ flat_camera_basis.z * input_dir.z
	)

	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	velocity = move_dir * speed
	move_and_slide()
	_clamp_player_to_room_bounds()

	if camera_mode == CameraMode.FIRSTPERSON:
		rotation.y = lerp_angle(rotation.y, camera_yaw, min(1.0, delta * BODY_TURN_SMOOTH))
	elif Vector2(velocity.x, velocity.z).length() > 0.05:
		var target_body_yaw := atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, target_body_yaw, min(1.0, delta * BODY_TURN_SMOOTH))

func _update_follow_camera(delta: float) -> void:
	var target_distance: float = THIRD_PERSON_DISTANCE if camera_mode == CameraMode.THIRDPERSON else FIRST_PERSON_DISTANCE
	var target_offset: Vector2 = THIRD_PERSON_OFFSET * _get_pitch_squeeze(camera_pitch) if camera_mode == CameraMode.THIRDPERSON else Vector2.ZERO

	var distance_blend: float = min(1.0, delta * CAMERA_DISTANCE_SMOOTH)
	var offset_blend: float = min(1.0, delta * CAMERA_OFFSET_SMOOTH)

	smoothed_camera_distance = lerpf(smoothed_camera_distance, target_distance, distance_blend)
	smoothed_camera_offset = smoothed_camera_offset.lerp(target_offset, offset_blend)

	_sync_follow_camera_rig()

func _sync_follow_camera_rig() -> void:
	camera_pivot.top_level = false
	camera_pivot.position = Vector3(0.0, CAMERA_HEIGHT, 0.0)
	camera_pivot.rotation = Vector3(camera_pitch, wrapf(camera_yaw - rotation.y, -PI, PI), 0.0)

	spring_arm.spring_length = smoothed_camera_distance
	camera.transform = Transform3D.IDENTITY
	camera.h_offset = smoothed_camera_offset.x
	camera.v_offset = smoothed_camera_offset.y

func _get_pitch_squeeze(pitch: float) -> float:
	var abs_pitch: float = abs(pitch)
	if abs_pitch <= CAMERA_PITCH_SQUEEZE_THRESHOLD:
		return 1.0

	return clamp(
		(PI * 0.5 - abs_pitch) / (PI * 0.5 - CAMERA_PITCH_SQUEEZE_THRESHOLD),
		0.0,
		1.0
	)

func _get_input_direction() -> Vector3:
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.z += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_E):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_Q):
		input_dir.y -= 1.0
	return input_dir

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
	return camera

func cycle_camera_mode() -> void:
	var next_mode: int = (camera_mode + 1) % 3
	set_camera_mode(next_mode)

func set_camera_mode(mode: int) -> void:
	if mode == camera_mode:
		return

	if mode == CameraMode.FREECAM:
		var current_camera_transform: Transform3D = camera.get_camera_transform()

		camera_mode = CameraMode.FREECAM
		rig.visible = true

		camera.h_offset = 0.0
		camera.v_offset = 0.0
		spring_arm.spring_length = 0.0
		camera.transform = Transform3D.IDENTITY

		camera_pivot.top_level = true
		camera_pivot.global_transform = current_camera_transform

		camera_yaw = wrapf(camera_pivot.global_rotation.y, -PI, PI)
		camera_pitch = clamp(camera_pivot.global_rotation.x, MIN_PITCH, MAX_PITCH)

		_refresh_camera_ui()
		return

	if camera_mode == CameraMode.FREECAM:
		camera_yaw = wrapf(camera_pivot.global_rotation.y, -PI, PI)
		camera_pitch = clamp(camera_pivot.global_rotation.x, MIN_PITCH, MAX_PITCH)

	camera_mode = mode
	camera_pivot.top_level = false

	if camera_mode == CameraMode.FIRSTPERSON:
		rotation.y = camera_yaw
		rig.visible = false
		smoothed_camera_distance = FIRST_PERSON_DISTANCE
		smoothed_camera_offset = Vector2.ZERO
	else:
		rig.visible = true
		smoothed_camera_distance = THIRD_PERSON_DISTANCE
		smoothed_camera_offset = THIRD_PERSON_OFFSET * _get_pitch_squeeze(camera_pitch)

	_sync_follow_camera_rig()
	_clamp_player_to_room_bounds()
	_refresh_camera_ui()

func get_camera_mode_name() -> String:
	match camera_mode:
		CameraMode.FREECAM:
			return "Freecam"
		CameraMode.THIRDPERSON:
			return "Thirdperson"
		CameraMode.FIRSTPERSON:
			return "Firstperson"
		_:
			return "Unknown"
