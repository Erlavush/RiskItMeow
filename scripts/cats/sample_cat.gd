class_name SampleCat
extends Node3D

signal idle_finished(cat)
signal wander_finished(cat)

enum BehaviorState {
	IDLE,
	WANDER,
}

const BODY_SIZE := Vector3(0.58, 0.28, 0.9)
const HEAD_SIZE := Vector3(0.34, 0.28, 0.3)
const EAR_SIZE := Vector3(0.08, 0.12, 0.06)
const TAIL_SIZE := Vector3(0.08, 0.08, 0.48)
const PAW_SIZE := Vector3(0.1, 0.24, 0.1)

const FRONT_LEFT_PAW := Vector3(-0.18, 0.12, -0.24)
const FRONT_RIGHT_PAW := Vector3(0.18, 0.12, -0.24)
const BACK_LEFT_PAW := Vector3(-0.18, 0.12, 0.26)
const BACK_RIGHT_PAW := Vector3(0.18, 0.12, 0.26)

@export var move_speed: float = 1.25
@export var turn_speed: float = 8.0
@export var arrival_distance: float = 0.12
@export var room_margin: float = 0.72
@export var floor_y: float = 0.0
@export var room_bounds_half_extents: Vector2 = Vector2(5.2, 5.2)
@export var room_origin: Vector3 = Vector3.ZERO

@export var fur_color: Color = Color(0.89, 0.63, 0.34, 1.0)
@export var stripe_color: Color = Color(0.39, 0.24, 0.14, 1.0)
@export var accent_color: Color = Color(0.97, 0.88, 0.8, 1.0)
@export var nose_color: Color = Color(0.93, 0.57, 0.64, 1.0)

var _state: int = BehaviorState.IDLE
var _idle_timer: float = 0.0
var _target_position: Vector3 = Vector3.ZERO
var _current_speed: float = 0.0
var _gait_phase: float = 0.0
var _awaiting_next_cycle: bool = false

@onready var visual_root: Node3D = $VisualRoot
@onready var body_pivot: Node3D = $VisualRoot/BodyPivot
@onready var body: MeshInstance3D = $VisualRoot/BodyPivot/Body
@onready var stripe: MeshInstance3D = $VisualRoot/BodyPivot/Stripe
@onready var head_pivot: Node3D = $VisualRoot/BodyPivot/HeadPivot
@onready var head: MeshInstance3D = $VisualRoot/BodyPivot/HeadPivot/Head
@onready var ear_left: MeshInstance3D = $VisualRoot/BodyPivot/HeadPivot/EarLeft
@onready var ear_right: MeshInstance3D = $VisualRoot/BodyPivot/HeadPivot/EarRight
@onready var nose: MeshInstance3D = $VisualRoot/BodyPivot/HeadPivot/Nose
@onready var tail_pivot: Node3D = $VisualRoot/BodyPivot/TailPivot
@onready var tail: MeshInstance3D = $VisualRoot/BodyPivot/TailPivot/Tail
@onready var paw_front_left: MeshInstance3D = $VisualRoot/BodyPivot/PawFrontLeft
@onready var paw_front_right: MeshInstance3D = $VisualRoot/BodyPivot/PawFrontRight
@onready var paw_back_left: MeshInstance3D = $VisualRoot/BodyPivot/PawBackLeft
@onready var paw_back_right: MeshInstance3D = $VisualRoot/BodyPivot/PawBackRight

func _ready() -> void:
	_configure_visuals()
	global_position = _clamp_to_room(global_position)
	_align_to_floor()
	_target_position = get_floor_position()
	set_idle(1.0)

func _physics_process(delta: float) -> void:
	_align_to_floor()

	if _state == BehaviorState.WANDER:
		_update_wander(delta)
	else:
		_update_idle(delta)

	_update_animation(delta)

func set_room_context(next_bounds: Vector2, next_floor_y: float, next_room_origin: Vector3 = Vector3.ZERO) -> void:
	room_bounds_half_extents = Vector2(
		max(1.0, next_bounds.x),
		max(1.0, next_bounds.y)
	)
	floor_y = next_floor_y
	room_origin = next_room_origin
	global_position = _clamp_to_room(global_position)
	_target_position = _clamp_to_room(_target_position)
	_align_to_floor()

func set_idle(duration: float) -> void:
	_state = BehaviorState.IDLE
	_idle_timer = max(0.15, duration)
	_current_speed = 0.0
	_awaiting_next_cycle = false
	_target_position = get_floor_position()

func set_wander_target(target_position: Vector3) -> void:
	_state = BehaviorState.WANDER
	_target_position = _clamp_to_room(target_position)
	_target_position.y = floor_y
	_awaiting_next_cycle = false

func get_floor_position() -> Vector3:
	return Vector3(global_position.x, floor_y, global_position.z)

func get_target_position() -> Vector3:
	return _target_position

func is_idle() -> bool:
	return _state == BehaviorState.IDLE

func _update_idle(delta: float) -> void:
	_current_speed = move_toward(_current_speed, 0.0, delta * 6.0)
	_idle_timer -= delta
	if _idle_timer > 0.0 or _awaiting_next_cycle:
		return

	_awaiting_next_cycle = true
	idle_finished.emit(self)

func _update_wander(delta: float) -> void:
	var current_position := get_floor_position()
	var to_target := _target_position - current_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= arrival_distance:
		global_position = _clamp_to_room(_target_position)
		_align_to_floor()
		_state = BehaviorState.IDLE
		_current_speed = 0.0
		if not _awaiting_next_cycle:
			_awaiting_next_cycle = true
			wander_finished.emit(self)
		return

	var direction := to_target / max(distance, 0.0001)
	var step := min(distance, move_speed * delta)
	global_position += direction * step
	global_position = _clamp_to_room(global_position)
	_align_to_floor()
	_current_speed = step / max(delta, 0.0001)

	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, min(1.0, delta * turn_speed))

func _update_animation(delta: float) -> void:
	var gait_amount := clampf(_current_speed / max(move_speed, 0.01), 0.0, 1.2)
	var gait_speed := lerpf(2.6, 11.0, gait_amount)
	_gait_phase += delta * gait_speed

	var idle_sway := sin(_gait_phase * 0.8) * 0.01
	var body_bob := sin(_gait_phase * 2.0) * 0.026 * gait_amount + idle_sway
	visual_root.position = Vector3(0.0, body_bob, 0.0)

	head_pivot.rotation.x = sin(_gait_phase * 1.1 + 0.4) * 0.06 + gait_amount * 0.04
	tail_pivot.rotation = Vector3(0.65, 0.0, 0.3 + sin(_gait_phase * 2.5 + 0.8) * (0.12 + gait_amount * 0.08))

	var front_step := max(0.0, sin(_gait_phase * 2.0)) * 0.05 * gait_amount
	var back_step := max(0.0, sin(_gait_phase * 2.0 + PI)) * 0.05 * gait_amount
	paw_front_left.position = FRONT_LEFT_PAW + Vector3(0.0, front_step, 0.0)
	paw_back_right.position = BACK_RIGHT_PAW + Vector3(0.0, front_step, 0.0)
	paw_front_right.position = FRONT_RIGHT_PAW + Vector3(0.0, back_step, 0.0)
	paw_back_left.position = BACK_LEFT_PAW + Vector3(0.0, back_step, 0.0)

func _align_to_floor() -> void:
	global_position.y = floor_y

func _clamp_to_room(position_value: Vector3) -> Vector3:
	var min_x: float = room_origin.x - room_bounds_half_extents.x + room_margin
	var max_x: float = room_origin.x + room_bounds_half_extents.x - room_margin
	var min_z: float = room_origin.z - room_bounds_half_extents.y + room_margin
	var max_z: float = room_origin.z + room_bounds_half_extents.y - room_margin
	return Vector3(
		clampf(position_value.x, min_x, max_x),
		floor_y,
		clampf(position_value.z, min_z, max_z)
	)

func _configure_visuals() -> void:
	_configure_box(body, BODY_SIZE, Vector3(0.0, 0.28, 0.0), fur_color)
	_configure_box(stripe, Vector3(0.18, 0.14, 0.92), Vector3(0.0, 0.37, 0.0), stripe_color)

	head_pivot.position = Vector3(0.0, 0.36, -0.5)
	_configure_box(head, HEAD_SIZE, Vector3.ZERO, fur_color)
	_configure_box(ear_left, EAR_SIZE, Vector3(-0.1, 0.17, -0.04), accent_color)
	_configure_box(ear_right, EAR_SIZE, Vector3(0.1, 0.17, -0.04), accent_color)
	_configure_sphere(nose, 0.055, Vector3(0.0, -0.02, -0.18), nose_color)

	tail_pivot.position = Vector3(0.0, 0.34, 0.46)
	_configure_box(tail, TAIL_SIZE, Vector3(0.0, 0.0, 0.22), stripe_color)

	_configure_box(paw_front_left, PAW_SIZE, FRONT_LEFT_PAW, accent_color)
	_configure_box(paw_front_right, PAW_SIZE, FRONT_RIGHT_PAW, accent_color)
	_configure_box(paw_back_left, PAW_SIZE, BACK_LEFT_PAW, accent_color)
	_configure_box(paw_back_right, PAW_SIZE, BACK_RIGHT_PAW, accent_color)

func _configure_box(mesh_instance: MeshInstance3D, size: Vector3, center: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = _make_material(color)

func _configure_sphere(mesh_instance: MeshInstance3D, radius: float, center: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = _make_material(color)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.metallic_specular = 0.0
	return material
