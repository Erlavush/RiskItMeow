extends CharacterBody3D

enum CameraMode {
	FREECAM,
	THIRDPERSON,
	FIRSTPERSON,
}

const SPEED: float = 5.0
const FAST_SPEED: float = 15.0
const CAMERA_HEIGHT: float = 1.5
const THIRD_PERSON_DISTANCE: float = 4.0
const FIRST_PERSON_DISTANCE: float = 0.0
const MIN_PITCH: float = -1.55
const MAX_PITCH: float = 1.55
const PLATFORM_HALF_SIZE: float = 5.0
const PLATFORM_MARGIN: float = 0.45

var sensitivity: float = 0.005
var camera_mode: CameraMode = CameraMode.FREECAM

@onready var rig: MinecraftRig = $MinecraftRig
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_spawn_ui()
	set_camera_mode(CameraMode.FREECAM)

func _spawn_ui() -> void:
	var skin_ui = preload("res://scripts/skin_picker.gd").new()
	skin_ui.rig_node = rig
	skin_ui.player_node = self
	# Delaying UI spawn slightly ensures rig_node is fully ready to be accessed
	add_child(skin_ui)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion

		if camera_mode == CameraMode.FREECAM:
			camera_pivot.rotate_y(-motion.relative.x * sensitivity)
			var next_pitch: float = camera_pivot.rotation.x - motion.relative.y * sensitivity
			camera_pivot.rotation.x = clamp(next_pitch, MIN_PITCH, MAX_PITCH)
			camera_pivot.rotation.z = 0.0
		else:
			# In follow modes, rotate the player body for Y, and pivot for X (pitch)
			rotate_y(-motion.relative.x * sensitivity)
			var next_pitch: float = camera_pivot.rotation.x - motion.relative.y * sensitivity
			camera_pivot.rotation.x = clamp(next_pitch, MIN_PITCH, MAX_PITCH)
			camera_pivot.rotation.y = 0.0
			camera_pivot.rotation.z = 0.0

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	var input_dir: Vector3 = _get_input_direction()
	var speed: float = FAST_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED

	if camera_mode == CameraMode.FREECAM:
		# In freecam, move independent of player orientation
		var move_dir: Vector3 = (
			camera_pivot.global_transform.basis.x * input_dir.x
			+ camera_pivot.global_transform.basis.y * input_dir.y
			+ camera_pivot.global_transform.basis.z * input_dir.z
		)

		if move_dir.length() > 0.01:
			move_dir = move_dir.normalized()

		camera_pivot.global_position += move_dir * speed * delta
		velocity = Vector3.ZERO
		return

	# In Third/First person, move relative to player's current ground-plane orientation
	var follow_move_dir: Vector3 = (
		global_transform.basis.x * input_dir.x
		+ Vector3.UP * input_dir.y
		+ global_transform.basis.z * input_dir.z
	)

	if follow_move_dir.length() > 0.01:
		follow_move_dir = follow_move_dir.normalized()

	velocity = follow_move_dir * speed
	move_and_slide()
	_clamp_player_to_platform()

func _get_input_direction() -> Vector3:
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.z += 1.0
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_E): input_dir.y += 1.0
	if Input.is_key_pressed(KEY_Q): input_dir.y -= 1.0
	return input_dir

func _clamp_player_to_platform() -> void:
	var min_x: float = -PLATFORM_HALF_SIZE + PLATFORM_MARGIN
	var max_x: float = PLATFORM_HALF_SIZE - PLATFORM_MARGIN
	var min_z: float = -PLATFORM_HALF_SIZE + PLATFORM_MARGIN
	var max_z: float = PLATFORM_HALF_SIZE - PLATFORM_MARGIN
	
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.z = clamp(global_position.z, min_z, max_z)

func cycle_camera_mode() -> void:
	var next_mode: int = (int(camera_mode) + 1) % 3
	set_camera_mode(next_mode as CameraMode)

func set_camera_mode(mode: CameraMode) -> void:
	if mode == camera_mode:
		return

	if mode == CameraMode.FREECAM:
		var current_camera_transform: Transform3D = camera.global_transform
		camera_mode = mode
		camera_pivot.top_level = true
		camera_pivot.global_transform = current_camera_transform
		spring_arm.spring_length = 0.0
		rig.visible = true
		return

	var pitch: float = camera.global_rotation.x - global_rotation.y
	var yaw: float = global_rotation.y

	if camera_mode == CameraMode.FREECAM:
		yaw = camera.global_rotation.y
	else:
		yaw = global_rotation.y

	camera_mode = mode
	rotation.y = yaw

	camera_pivot.top_level = false
	camera_pivot.position = Vector3(0.0, CAMERA_HEIGHT, 0.0)
	camera_pivot.rotation = Vector3(clamp(pitch, MIN_PITCH, MAX_PITCH), 0.0, 0.0)

	if camera_mode == CameraMode.THIRDPERSON:
		spring_arm.spring_length = THIRD_PERSON_DISTANCE
		rig.visible = true
	else:
		spring_arm.spring_length = FIRST_PERSON_DISTANCE
		rig.visible = false
	
	_clamp_player_to_platform()

func get_camera_mode_name() -> String:
	match camera_mode:
		CameraMode.FREECAM: return "Freecam"
		CameraMode.THIRDPERSON: return "Thirdperson"
		CameraMode.FIRSTPERSON: return "Firstperson"
		_: return "Unknown"
