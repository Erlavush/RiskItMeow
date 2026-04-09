extends CharacterBody3D

const SPEED: float = 5.0
const FAST_SPEED: float = 15.0
const ROOM_MARGIN: float = RoomConstants.DEFAULT_PLAYER_MARGIN
const BODY_TURN_SMOOTH: float = 10.0
const CAMERA_MODE_ROOM := "room"
const CAMERA_MODE_FIRST_PERSON := "first_person"
const FIRST_PERSON_LOOK_SENSITIVITY: float = 0.0024
const FIRST_PERSON_MIN_PITCH: float = -1.35
const FIRST_PERSON_MAX_PITCH: float = 1.2
const FIRST_PERSON_EYE_FALLBACK_Y: float = 1.625

@export var room_camera_controller_path: NodePath
@export var placement_manager_path: NodePath

var skin_ui: SkinPicker
var room_bounds_half_extents: Vector2 = RoomConstants.DEFAULT_ROOM_HALF_EXTENTS - Vector2.ONE * ROOM_MARGIN
var room_floor_y: float = 0.0
var _debug_world_active := false
var _camera_mode := CAMERA_MODE_ROOM
var _first_person_pitch := 0.0
var _first_person_mouse_captured := false

@onready var rig: MinecraftRig = $MinecraftRig
@onready var legacy_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var first_person_pivot: Node3D = $FirstPersonPivot
@onready var first_person_camera: Camera3D = $FirstPersonPivot/Camera3D
@onready var room_camera_controller: Node = get_node_or_null(room_camera_controller_path)
@onready var placement_manager: Node = get_node_or_null(placement_manager_path)

func _ready() -> void:
	_normalize_player_pose()
	_spawn_ui()
	if legacy_camera != null:
		legacy_camera.current = false
	if first_person_camera != null:
		first_person_camera.current = false
	_sync_first_person_camera()
	_apply_camera_mode(false)

func _process(_delta: float) -> void:
	_sync_first_person_camera()

func _spawn_ui() -> void:
	skin_ui = preload("res://scripts/skin_picker.gd").new()
	skin_ui.rig_node = rig
	skin_ui.player_node = self
	add_child(skin_ui)

func _unhandled_input(event: InputEvent) -> void:
	if _debug_world_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_F5:
			toggle_camera_mode()
			get_viewport().set_input_as_handled()
			return

	if _camera_mode == CAMERA_MODE_FIRST_PERSON and _handle_first_person_input(event):
		get_viewport().set_input_as_handled()
		return

	if _camera_mode == CAMERA_MODE_ROOM and room_camera_controller != null:
		if _should_block_room_camera_input(event):
			return
		var camera_handled: bool = room_camera_controller.handle_input_event(event)
		if camera_handled:
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if _debug_world_active:
		velocity = Vector3.ZERO
		return

	var input_vector: Vector2 = _get_input_vector()
	var speed: float = FAST_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
	var move_dir: Vector3 = _get_move_direction(input_vector)

	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	velocity = move_dir * speed
	move_and_slide()
	_snap_to_floor()
	_clamp_player_to_room_bounds()

	if _camera_mode == CAMERA_MODE_FIRST_PERSON:
		rotation.y = wrapf(rotation.y, -PI, PI)
	elif Vector2(velocity.x, velocity.z).length() > 0.05:
		var target_body_yaw := atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, target_body_yaw, min(1.0, delta * BODY_TURN_SMOOTH))

	_sync_first_person_camera()

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
	if _debug_world_active:
		return null
	if _camera_mode == CAMERA_MODE_FIRST_PERSON and first_person_camera != null:
		return first_person_camera
	return _get_room_camera()

func get_camera_mode() -> String:
	return _camera_mode

func get_camera_mode_label() -> String:
	return "First Person" if _camera_mode == CAMERA_MODE_FIRST_PERSON else "Room View"

func toggle_camera_mode() -> void:
	set_camera_mode(CAMERA_MODE_ROOM if _camera_mode == CAMERA_MODE_FIRST_PERSON else CAMERA_MODE_FIRST_PERSON)

func set_camera_mode(next_mode: String, capture_mouse: bool = true) -> void:
	var resolved_mode := next_mode
	if resolved_mode != CAMERA_MODE_FIRST_PERSON:
		resolved_mode = CAMERA_MODE_ROOM

	if resolved_mode == CAMERA_MODE_FIRST_PERSON and _camera_mode != CAMERA_MODE_FIRST_PERSON:
		_align_first_person_view_to_room_camera()

	_camera_mode = resolved_mode
	_apply_camera_mode(capture_mouse)
	if skin_ui != null and skin_ui.has_method("refresh_camera_ui"):
		skin_ui.call("refresh_camera_ui")

func reset_room_camera() -> void:
	if room_camera_controller != null and room_camera_controller.has_method("reset_camera"):
		room_camera_controller.reset_camera()

func set_debug_world_active(active: bool) -> void:
	_debug_world_active = active
	velocity = Vector3.ZERO
	if rig != null:
		rig.visible = not active
		rig.set_first_person_view(_camera_mode == CAMERA_MODE_FIRST_PERSON and not active, _first_person_pitch if not active else 0.0)
	if skin_ui != null:
		skin_ui.visible = not active

	if active:
		_release_first_person_mouse()
		if first_person_camera != null:
			first_person_camera.current = false
	else:
		call_deferred("_restore_camera_mode_after_debug")

func _restore_camera_mode_after_debug() -> void:
	if _debug_world_active:
		return
	_apply_camera_mode(false)

func _handle_first_person_input(event: InputEvent) -> bool:
	if event == null:
		return false

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and _first_person_mouse_captured:
			_release_first_person_mouse()
			return true
		if key_event.keycode == KEY_HOME:
			_first_person_pitch = 0.0
			_sync_first_person_camera()
			return true

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			if not _first_person_mouse_captured and get_viewport().gui_get_hovered_control() == null:
				_capture_first_person_mouse()
				return true

	if event is InputEventMouseMotion and _first_person_mouse_captured:
		var motion := event as InputEventMouseMotion
		rotation.y = wrapf(rotation.y - motion.relative.x * FIRST_PERSON_LOOK_SENSITIVITY, -PI, PI)
		_first_person_pitch = clamp(
			_first_person_pitch - motion.relative.y * FIRST_PERSON_LOOK_SENSITIVITY,
			FIRST_PERSON_MIN_PITCH,
			FIRST_PERSON_MAX_PITCH
		)
		_sync_first_person_camera()
		return true

	return false

func _align_first_person_view_to_room_camera() -> void:
	var forward := Vector3.ZERO
	if room_camera_controller != null and room_camera_controller.has_method("get_planar_forward"):
		var forward_value: Variant = room_camera_controller.call("get_planar_forward")
		if typeof(forward_value) == TYPE_VECTOR3:
			forward = forward_value

	if forward.length_squared() > 0.0001:
		rotation.y = atan2(-forward.x, -forward.z)
	_first_person_pitch = 0.0
	_sync_first_person_camera()

func _apply_camera_mode(capture_mouse: bool = true) -> void:
	var room_camera := _get_room_camera()
	var use_first_person := _camera_mode == CAMERA_MODE_FIRST_PERSON and not _debug_world_active

	if room_camera != null:
		room_camera.current = not use_first_person
	if first_person_camera != null:
		first_person_camera.current = use_first_person

	if use_first_person:
		_sync_first_person_camera()
		if capture_mouse:
			_capture_first_person_mouse()
	else:
		_release_first_person_mouse()
		_first_person_pitch = clamp(_first_person_pitch, FIRST_PERSON_MIN_PITCH, FIRST_PERSON_MAX_PITCH)

func _capture_first_person_mouse() -> void:
	if _debug_world_active:
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_first_person_mouse_captured = true

func _release_first_person_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_first_person_mouse_captured = false

func _sync_first_person_camera() -> void:
	if first_person_pivot == null:
		return

	var anchor_position := global_position + Vector3(0.0, FIRST_PERSON_EYE_FALLBACK_Y, 0.0)
	if rig != null:
		anchor_position = rig.get_first_person_camera_global_position()
	first_person_pivot.global_position = anchor_position
	first_person_pivot.global_rotation = Vector3(_first_person_pitch, rotation.y, 0.0)

	if rig != null:
		rig.set_first_person_view(_camera_mode == CAMERA_MODE_FIRST_PERSON and not _debug_world_active, _first_person_pitch)

func _get_room_camera() -> Camera3D:
	if room_camera_controller != null and room_camera_controller.has_method("get_camera"):
		return room_camera_controller.call("get_camera") as Camera3D
	return legacy_camera

func _should_block_room_camera_input(event: InputEvent) -> bool:
	if event == null or placement_manager == null:
		return false
	if not placement_manager.has_method("blocks_room_camera_input"):
		return false
	return bool(placement_manager.call("blocks_room_camera_input", event))

func _normalize_player_pose() -> void:
	rotation = Vector3(0.0, rotation.y, 0.0)
	_snap_to_floor()

func _snap_to_floor() -> void:
	global_position.y = room_floor_y
