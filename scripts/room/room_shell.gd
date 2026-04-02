@tool
class_name RoomShell
extends Node3D

const RoomConstants := preload("res://scripts/room/room_constants.gd")
const FloorCheckerShader := preload("res://shaders/floor_checker.gdshader")
const EDITOR_PREVIEW_FLOOR_LIFT := 0.04

@export var room_half_extents: Vector2 = RoomConstants.DEFAULT_ROOM_HALF_EXTENTS
@export var wall_height: float = RoomConstants.DEFAULT_WALL_HEIGHT
@export var floor_thickness: float = RoomConstants.DEFAULT_FLOOR_THICKNESS
@export var wall_thickness: float = RoomConstants.DEFAULT_WALL_THICKNESS
@export var ceiling_thickness: float = RoomConstants.DEFAULT_CEILING_THICKNESS
@export var show_walls: bool = true
@export var show_ceiling: bool = true

@export var floor_color: Color = Color(0.843, 0.745, 0.612, 1.0)
@export var wall_color: Color = Color(0.956, 0.929, 0.882, 1.0)
@export var trim_color: Color = Color(0.745, 0.627, 0.486, 1.0)
@export var ceiling_color: Color = Color(0.984, 0.972, 0.941, 1.0)

@onready var floor: Node3D = $floor
@onready var wall_back: Node3D = $wall_back
@onready var wall_left: Node3D = $wall_left
@onready var wall_front: Node3D = $wall_front
@onready var wall_right: Node3D = $wall_right
@onready var ceiling: Node3D = $ceiling

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_rebuild")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_configure_floor()
	_configure_walls()
	_configure_ceiling()

func get_room_center() -> Vector3:
	return global_position + Vector3(0.0, wall_height * 0.45, 0.0)

func get_floor_y() -> float:
	return global_position.y

func get_ceiling_y() -> float:
	return global_position.y + wall_height

func get_inner_half_extents() -> Vector2:
	return room_half_extents
func get_walkable_half_extents(margin: float = RoomConstants.DEFAULT_PLAYER_MARGIN) -> Vector2:
	return Vector2(
		max(0.5, room_half_extents.x - margin),
		max(0.5, room_half_extents.y - margin)
	)

func get_wall_surface_coordinate(surface: String) -> float:
	match surface:
		RoomConstants.WALL_BACK:
			return global_position.z - room_half_extents.y
		RoomConstants.WALL_FRONT:
			return global_position.z + room_half_extents.y
		RoomConstants.WALL_LEFT:
			return global_position.x - room_half_extents.x
		RoomConstants.WALL_RIGHT:
			return global_position.x + room_half_extents.x
		_:
			return 0.0

func set_surface_visible(surface_name: String, is_visible: bool) -> void:
	var surface: Node3D = _get_surface_node(surface_name)
	if surface == null:
		return

	var visual: VisualInstance3D = surface.get_node_or_null("Visual") as VisualInstance3D
	if visual != null:
		visual.visible = is_visible and _is_surface_enabled(surface_name)

	var collider_body := surface.get_node_or_null("Collider") as CollisionObject3D
	if collider_body != null:
		collider_body.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
		collider_body.process_mode = Node.PROCESS_MODE_INHERIT if _is_surface_enabled(surface_name) else Node.PROCESS_MODE_DISABLED

func is_surface_visible(surface_name: String) -> bool:
	var surface: Node3D = _get_surface_node(surface_name)
	if surface == null:
		return false

	var visual: VisualInstance3D = surface.get_node_or_null("Visual") as VisualInstance3D
	return (visual == null or visual.visible) and _is_surface_enabled(surface_name)

func _configure_floor() -> void:
	var floor_size := Vector3(
		room_half_extents.x * 2.0,
		floor_thickness,
		room_half_extents.y * 2.0
	)
	var floor_center := Vector3(0.0, -floor_thickness * 0.5, 0.0)
	if Engine.is_editor_hint():
		# Lift the preview slightly above the editor grid so the floor is visible without running the scene.
		floor_center.y += EDITOR_PREVIEW_FLOOR_LIFT
	_configure_surface(floor, floor_center, floor_size, floor_color)
	_apply_floor_checker_material()

func _configure_walls() -> void:
	var span_x := room_half_extents.x * 2.0
	var span_z := room_half_extents.y * 2.0
	var wall_center_y := wall_height * 0.5

	_configure_surface(
		wall_back,
		Vector3(0.0, wall_center_y, -room_half_extents.y - wall_thickness * 0.5),
		Vector3(span_x + wall_thickness * 2.0, wall_height, wall_thickness),
		wall_color
	)
	_configure_surface(
		wall_front,
		Vector3(0.0, wall_center_y, room_half_extents.y + wall_thickness * 0.5),
		Vector3(span_x + wall_thickness * 2.0, wall_height, wall_thickness),
		wall_color
	)
	_configure_surface(
		wall_left,
		Vector3(-room_half_extents.x - wall_thickness * 0.5, wall_center_y, 0.0),
		Vector3(wall_thickness, wall_height, span_z),
		wall_color
	)
	_configure_surface(
		wall_right,
		Vector3(room_half_extents.x + wall_thickness * 0.5, wall_center_y, 0.0),
		Vector3(wall_thickness, wall_height, span_z),
		wall_color
	)

func _configure_ceiling() -> void:
	var ceiling_size := Vector3(
		room_half_extents.x * 2.0 + wall_thickness * 2.0,
		ceiling_thickness,
		room_half_extents.y * 2.0 + wall_thickness * 2.0
	)
	var ceiling_center := Vector3(0.0, wall_height + ceiling_thickness * 0.5, 0.0)
	_configure_surface(ceiling, ceiling_center, ceiling_size, ceiling_color)

func _configure_surface(surface: Node3D, center: Vector3, size: Vector3, color: Color) -> void:
	if surface == null:
		return

	surface.position = center

	var visual := surface.get_node_or_null("Visual") as MeshInstance3D
	var collider := surface.get_node_or_null("Collider/CollisionShape3D") as CollisionShape3D
	if visual == null or collider == null:
		return

	if visual.mesh == null:
		visual.mesh = BoxMesh.new()
	if collider.shape == null:
		collider.shape = BoxShape3D.new()

	var box_mesh := visual.mesh as BoxMesh
	var box_shape := collider.shape as BoxShape3D
	if box_mesh == null or box_shape == null:
		return

	box_mesh.size = size
	box_shape.size = size

	if visual.material_override == null:
		var material := StandardMaterial3D.new()
		material.roughness = 0.92
		material.metallic_specular = 0.0
		visual.material_override = material

	var override := visual.material_override as StandardMaterial3D
	if override != null:
		override.albedo_color = color

	set_surface_visible(_get_surface_name(surface), true)

func _get_surface_node(surface_name: String) -> Node3D:
	match surface_name:
		RoomConstants.FLOOR_SURFACE:
			return floor
		RoomConstants.WALL_BACK:
			return wall_back
		RoomConstants.WALL_LEFT:
			return wall_left
		RoomConstants.WALL_FRONT:
			return wall_front
		RoomConstants.WALL_RIGHT:
			return wall_right
		RoomConstants.CEILING_SURFACE:
			return ceiling
		_:
			return null

func _get_surface_name(surface: Node3D) -> String:
	if surface == floor:
		return RoomConstants.FLOOR_SURFACE
	if surface == wall_back:
		return RoomConstants.WALL_BACK
	if surface == wall_left:
		return RoomConstants.WALL_LEFT
	if surface == wall_front:
		return RoomConstants.WALL_FRONT
	if surface == wall_right:
		return RoomConstants.WALL_RIGHT
	if surface == ceiling:
		return RoomConstants.CEILING_SURFACE
	return ""

func _is_surface_enabled(surface_name: String) -> bool:
	if RoomConstants.is_wall_surface(surface_name):
		return show_walls
	if surface_name == RoomConstants.CEILING_SURFACE:
		return show_ceiling
	return true

func _apply_floor_checker_material() -> void:
	var visual := floor.get_node_or_null("Visual") as MeshInstance3D
	if visual == null:
		return

	var shader_material := visual.material_override as ShaderMaterial
	if shader_material == null or shader_material.shader != FloorCheckerShader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = FloorCheckerShader
		visual.material_override = shader_material

	shader_material.set_shader_parameter("checker_size", RoomConstants.DEFAULT_GRID_SIZE)
	shader_material.set_shader_parameter("light_color", Color(0.67, 0.67, 0.67, 1.0))
	shader_material.set_shader_parameter("dark_color", Color(0.12, 0.12, 0.12, 1.0))
