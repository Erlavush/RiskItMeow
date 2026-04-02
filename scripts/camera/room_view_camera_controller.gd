class_name RoomViewCameraController
extends Node3D

const DEFAULT_TARGET_POSITION := Vector3(0.0, 0.9, 0.0)
const DEFAULT_CAMERA_POSITION := Vector3(11.8, 9.6, 11.2)

@export var target_position: Vector3 = DEFAULT_TARGET_POSITION
@export_range(0.001, 0.03, 0.001) var orbit_sensitivity: float = 0.01
@export_range(-1.2, 1.4, 0.01) var min_pitch: float = -0.75
@export_range(0.2, 1.5, 0.01) var max_pitch: float = 1.5
@export_range(2.0, 48.0, 0.1) var min_distance: float = 5.0
@export_range(2.0, 48.0, 0.1) var max_distance: float = 48.0
@export_range(0.0001, 0.01, 0.0001) var wheel_sensitivity: float = 0.0015
@export_range(1.0, 30.0, 0.1) var zoom_smoothing: float = 14.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _current_distance: float = 0.0
var _target_distance: float = 0.0
var _drag_button: MouseButton = MOUSE_BUTTON_NONE

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	reset_camera()
	if camera != null:
		camera.current = true
	_sync_camera_transform()

func _process(delta: float) -> void:
	if camera == null:
		return

	var zoom_blend: float = min(1.0, delta * zoom_smoothing)
	_current_distance = lerpf(_current_distance, _target_distance, zoom_blend)
	_sync_camera_transform()

func handle_input_event(event: InputEvent) -> bool:
	if camera == null:
		return false

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mouse_button.pressed:
					_apply_zoom_delta(-1.0, absf(mouse_button.factor))
					return true
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_button.pressed:
					_apply_zoom_delta(1.0, absf(mouse_button.factor))
					return true
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE:
				if mouse_button.pressed:
					_drag_button = mouse_button.button_index
					return true
				if _drag_button == mouse_button.button_index:
					_drag_button = MOUSE_BUTTON_NONE
					return true
		return false

	if event is InputEventMouseMotion and _drag_button != MOUSE_BUTTON_NONE:
		var motion := event as InputEventMouseMotion
		_yaw = wrapf(_yaw - motion.relative.x * orbit_sensitivity, -PI, PI)
		_pitch = clamp(_pitch + motion.relative.y * orbit_sensitivity, min_pitch, max_pitch)
		_sync_camera_transform()
		return true

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_HOME:
			reset_camera()
			return true

	return false

func get_camera() -> Camera3D:
	return camera

func get_target_global_position() -> Vector3:
	return global_position + target_position

func get_planar_forward() -> Vector3:
	if camera == null:
		return Vector3.FORWARD

	var forward := get_target_global_position() - camera.global_position
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return forward.normalized()

func get_planar_right() -> Vector3:
	var forward := get_planar_forward()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() <= 0.0001:
		return Vector3.RIGHT
	return right.normalized()

func reset_camera() -> void:
	var default_offset := DEFAULT_CAMERA_POSITION - DEFAULT_TARGET_POSITION
	_yaw = atan2(default_offset.x, default_offset.z)
	_pitch = clamp(asin(default_offset.y / default_offset.length()), min_pitch, max_pitch)
	_current_distance = clamp(default_offset.length(), min_distance, max_distance)
	_target_distance = _current_distance
	_drag_button = MOUSE_BUTTON_NONE
	_sync_camera_transform()

func _apply_zoom_delta(direction: float, magnitude: float = 0.0) -> void:
	var zoom_amount: float = maxf(magnitude, 1.0)
	var zoom_scale: float = exp(direction * zoom_amount * wheel_sensitivity * 100.0)
	_target_distance = clamp(_target_distance * zoom_scale, min_distance, max_distance)

func _sync_camera_transform() -> void:
	if camera == null:
		return

	var target_global := get_target_global_position()
	var orbit_radius := cos(_pitch) * _current_distance
	var camera_offset := Vector3(
		sin(_yaw) * orbit_radius,
		sin(_pitch) * _current_distance,
		cos(_yaw) * orbit_radius
	)

	camera.global_position = target_global + camera_offset
	camera.look_at(target_global, Vector3.UP)
