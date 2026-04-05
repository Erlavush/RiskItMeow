@tool
class_name RoomShell
extends Node3D

const RoomConstants := preload("res://scripts/room/room_constants.gd")
const RoomFloorMaterials := preload("res://scripts/room/room_floor_materials.gd")
const RoomWallSegments := preload("res://scripts/room/room_wall_segments.gd")
const EDITOR_PREVIEW_FLOOR_LIFT := 0.04
const SURFACE_SHADOWS_ONLY := GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
const SURFACE_SHADOWS_ON := GeometryInstance3D.SHADOW_CASTING_SETTING_ON

enum FloorStyle {
	COZY_BROWN,
	CHECKERBOARD,
}

@export var room_half_extents: Vector2 = RoomConstants.DEFAULT_ROOM_HALF_EXTENTS
@export var wall_height: float = RoomConstants.DEFAULT_WALL_HEIGHT
@export var floor_thickness: float = RoomConstants.DEFAULT_FLOOR_THICKNESS
@export var wall_thickness: float = RoomConstants.DEFAULT_WALL_THICKNESS
@export var ceiling_thickness: float = RoomConstants.DEFAULT_CEILING_THICKNESS
@export var show_walls: bool = true
@export var show_wall_back: bool = true
@export var show_wall_left: bool = true
@export var show_wall_front: bool = true
@export var show_wall_right: bool = true
@export var show_ceiling: bool = true
@export_enum("Brown Mat", "Checkerboard") var floor_style: int = FloorStyle.COZY_BROWN

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

var _runtime_wall_openings: Dictionary = {
	RoomConstants.WALL_BACK: [],
	RoomConstants.WALL_LEFT: [],
	RoomConstants.WALL_FRONT: [],
	RoomConstants.WALL_RIGHT: [],
}
var _runtime_wall_opening_signatures: Dictionary = {
	RoomConstants.WALL_BACK: "",
	RoomConstants.WALL_LEFT: "",
	RoomConstants.WALL_FRONT: "",
	RoomConstants.WALL_RIGHT: "",
}
var _wall_segment_materials: Dictionary = {}
var _surface_cutaway_states: Dictionary = {
	RoomConstants.WALL_BACK: false,
	RoomConstants.WALL_LEFT: false,
	RoomConstants.WALL_FRONT: false,
	RoomConstants.WALL_RIGHT: false,
	RoomConstants.CEILING_SURFACE: false,
}

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

func get_wall_bottom_y() -> float:
	return global_position.y + _get_floor_bottom_y()

func get_wall_top_y() -> float:
	return global_position.y + _get_floor_top_y() + wall_height

func get_wall_placement_vertical_bounds() -> Vector2:
	return Vector2(get_floor_y(), get_ceiling_y())

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

func get_wall_center_coordinate(surface: String) -> float:
	match surface:
		RoomConstants.WALL_BACK:
			return get_wall_surface_coordinate(surface) - wall_thickness * 0.5
		RoomConstants.WALL_FRONT:
			return get_wall_surface_coordinate(surface) + wall_thickness * 0.5
		RoomConstants.WALL_LEFT:
			return get_wall_surface_coordinate(surface) - wall_thickness * 0.5
		RoomConstants.WALL_RIGHT:
			return get_wall_surface_coordinate(surface) + wall_thickness * 0.5
		_:
			return 0.0

func get_wall_surface_horizontal_bounds(surface: String) -> Vector2:
	match surface:
		RoomConstants.WALL_BACK, RoomConstants.WALL_FRONT:
			return Vector2(global_position.x - room_half_extents.x, global_position.x + room_half_extents.x)
		RoomConstants.WALL_LEFT, RoomConstants.WALL_RIGHT:
			return Vector2(global_position.z - room_half_extents.y, global_position.z + room_half_extents.y)
		_:
			return Vector2.ZERO

func set_runtime_wall_openings(surface_name: String, openings: Array[Dictionary]) -> void:
	if not RoomConstants.is_wall_surface(surface_name):
		return
 
	var normalized_openings := _normalize_wall_openings(openings)
	var next_signature := _build_wall_openings_signature(normalized_openings)
	if next_signature == String(_runtime_wall_opening_signatures.get(surface_name, "")):
		return
	_runtime_wall_openings[surface_name] = normalized_openings
	_runtime_wall_opening_signatures[surface_name] = next_signature
	_configure_single_wall(surface_name)

func set_runtime_wall_openings_batch(openings_by_surface: Dictionary) -> void:
	var changed_surfaces: Array[String] = []
	for surface_name in RoomConstants.WALL_SURFACES:
		var surface_key := String(surface_name)
		var raw_openings: Variant = openings_by_surface.get(surface_key, [])
		var normalized_openings := _normalize_wall_openings(raw_openings)
		var next_signature := _build_wall_openings_signature(normalized_openings)
		if next_signature == String(_runtime_wall_opening_signatures.get(surface_key, "")):
			continue
		_runtime_wall_openings[surface_key] = normalized_openings
		_runtime_wall_opening_signatures[surface_key] = next_signature
		changed_surfaces.append(surface_key)

	for surface_name in changed_surfaces:
		_configure_single_wall(surface_name)

func clear_runtime_wall_openings() -> void:
	for surface_name in RoomConstants.WALL_SURFACES:
		_runtime_wall_openings[surface_name] = []
		_runtime_wall_opening_signatures[surface_name] = ""
	_configure_walls()

func set_surface_cutaway(surface_name: String, is_cutaway: bool) -> void:
	if not _surface_cutaway_states.has(surface_name):
		return

	var next_cutaway := bool(is_cutaway)
	if bool(_surface_cutaway_states.get(surface_name, false)) == next_cutaway:
		return

	_surface_cutaway_states[surface_name] = next_cutaway
	_apply_surface_render_state(surface_name)

func clear_surface_cutaways() -> void:
	for surface_name in _surface_cutaway_states.keys():
		_surface_cutaway_states[surface_name] = false
		_apply_surface_render_state(String(surface_name))

func is_surface_cutaway(surface_name: String) -> bool:
	return bool(_surface_cutaway_states.get(surface_name, false))

func set_surface_visible(surface_name: String, is_visible: bool) -> void:
	var surface: Node3D = _get_surface_node(surface_name)
	if surface == null:
		return

	var should_be_visible := is_visible and _is_surface_enabled(surface_name)
	if RoomConstants.is_wall_surface(surface_name):
		_set_wall_segments_visible(surface, should_be_visible, bool(_surface_cutaway_states.get(surface_name, false)))
		var wall_visual := surface.get_node_or_null("Visual") as VisualInstance3D
		if wall_visual != null:
			wall_visual.visible = false
		var wall_collider := surface.get_node_or_null("Collider") as CollisionObject3D
		if wall_collider != null:
			wall_collider.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
			wall_collider.process_mode = Node.PROCESS_MODE_DISABLED
		return

	var visual: VisualInstance3D = surface.get_node_or_null("Visual") as VisualInstance3D
	if visual != null:
		visual.visible = should_be_visible
		visual.cast_shadow = SURFACE_SHADOWS_ONLY if should_be_visible and bool(_surface_cutaway_states.get(surface_name, false)) else SURFACE_SHADOWS_ON

	var collider_body := surface.get_node_or_null("Collider") as CollisionObject3D
	if collider_body != null:
		collider_body.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
		collider_body.process_mode = Node.PROCESS_MODE_INHERIT if should_be_visible else Node.PROCESS_MODE_DISABLED

func is_surface_visible(surface_name: String) -> bool:
	if RoomConstants.is_wall_surface(surface_name):
		return _is_surface_enabled(surface_name)

	var surface: Node3D = _get_surface_node(surface_name)
	if surface == null:
		return false

	return _is_surface_enabled(surface_name)

func set_floor_style(style_value: int) -> void:
	var next_style := clampi(style_value, FloorStyle.COZY_BROWN, FloorStyle.CHECKERBOARD)
	if floor_style == next_style:
		return

	floor_style = next_style
	_apply_floor_material()

func get_floor_style() -> int:
	return floor_style

func _configure_floor() -> void:
	var floor_size := Vector3(
		room_half_extents.x * 2.0,
		floor_thickness,
		room_half_extents.y * 2.0
	)
	var floor_center := Vector3(0.0, _get_floor_center_y(), 0.0)
	_configure_surface(floor, floor_center, floor_size, floor_color)
	_apply_floor_material()

func _configure_walls() -> void:
	for surface_name in RoomConstants.WALL_SURFACES:
		_configure_single_wall(String(surface_name))

func _configure_ceiling() -> void:
	var ceiling_size := Vector3(
		room_half_extents.x * 2.0 + wall_thickness * 2.0,
		ceiling_thickness,
		room_half_extents.y * 2.0 + wall_thickness * 2.0
	)
	var ceiling_center := Vector3(0.0, _get_floor_top_y() + wall_height + ceiling_thickness * 0.5, 0.0)
	_configure_surface(ceiling, ceiling_center, ceiling_size, ceiling_color)

func _configure_surface(surface: Node3D, center: Vector3, size: Vector3, color: Color) -> void:
	if surface == null:
		return

	surface.position = center
	var surface_name := _get_surface_name(surface)

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

	set_surface_visible(surface_name, true)

func _configure_wall_surface(surface: Node3D, surface_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	RoomWallSegments.configure_wall_surface(
		surface,
		surface_name,
		center,
		size,
		color,
		wall_thickness,
		_runtime_wall_openings,
		_wall_segment_materials
	)
	set_surface_visible(surface_name, true)

func _configure_single_wall(surface_name: String) -> void:
	var span_x := room_half_extents.x * 2.0
	var span_z := room_half_extents.y * 2.0
	var floor_top_y := _get_floor_top_y()
	var floor_bottom_y := _get_floor_bottom_y()
	var wall_top_y := floor_top_y + wall_height
	var wall_total_height := wall_top_y - floor_bottom_y
	var wall_center_y := (wall_top_y + floor_bottom_y) * 0.5
	match surface_name:
		RoomConstants.WALL_BACK:
			_configure_wall_surface(
				wall_back,
				RoomConstants.WALL_BACK,
				Vector3(0.0, wall_center_y, -room_half_extents.y - wall_thickness * 0.5),
				Vector3(span_x, wall_total_height, wall_thickness),
				wall_color
			)
		RoomConstants.WALL_FRONT:
			_configure_wall_surface(
				wall_front,
				RoomConstants.WALL_FRONT,
				Vector3(0.0, wall_center_y, room_half_extents.y + wall_thickness * 0.5),
				Vector3(span_x, wall_total_height, wall_thickness),
				wall_color
			)
		RoomConstants.WALL_LEFT:
			_configure_wall_surface(
				wall_left,
				RoomConstants.WALL_LEFT,
				Vector3(-room_half_extents.x - wall_thickness * 0.5, wall_center_y, 0.0),
				Vector3(wall_thickness, wall_total_height, span_z),
				wall_color
			)
		RoomConstants.WALL_RIGHT:
			_configure_wall_surface(
				wall_right,
				RoomConstants.WALL_RIGHT,
				Vector3(room_half_extents.x + wall_thickness * 0.5, wall_center_y, 0.0),
				Vector3(wall_thickness, wall_total_height, span_z),
				wall_color
			)

func _normalize_wall_openings(raw_openings: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if not (raw_openings is Array):
		return normalized
	for raw_opening in raw_openings:
		if typeof(raw_opening) != TYPE_DICTIONARY:
			continue
		normalized.append((raw_opening as Dictionary).duplicate(true))
	return normalized

func _build_wall_openings_signature(openings: Array[Dictionary]) -> String:
	return JSON.stringify(openings)

func _set_wall_segments_visible(surface: Node3D, is_visible: bool, is_cutaway: bool = false) -> void:
	RoomWallSegments.set_segments_visible(surface, is_visible, is_cutaway, SURFACE_SHADOWS_ONLY, SURFACE_SHADOWS_ON)

func _apply_surface_render_state(surface_name: String) -> void:
	var surface := _get_surface_node(surface_name)
	if surface == null:
		return

	var should_be_visible := _is_surface_enabled(surface_name)
	if RoomConstants.is_wall_surface(surface_name):
		_set_wall_segments_visible(surface, should_be_visible, bool(_surface_cutaway_states.get(surface_name, false)))
		return

	var visual := surface.get_node_or_null("Visual") as VisualInstance3D
	if visual != null:
		visual.visible = should_be_visible
		visual.cast_shadow = SURFACE_SHADOWS_ONLY if should_be_visible and bool(_surface_cutaway_states.get(surface_name, false)) else SURFACE_SHADOWS_ON

	var collider_body := surface.get_node_or_null("Collider") as CollisionObject3D
	if collider_body != null:
		collider_body.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
		collider_body.process_mode = Node.PROCESS_MODE_INHERIT if should_be_visible else Node.PROCESS_MODE_DISABLED

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
		return show_walls and _is_wall_enabled(surface_name)
	if surface_name == RoomConstants.CEILING_SURFACE:
		return show_ceiling
	return true

func _get_floor_center_y() -> float:
	var floor_center_y := -floor_thickness * 0.5
	if Engine.is_editor_hint():
		floor_center_y += EDITOR_PREVIEW_FLOOR_LIFT
	return floor_center_y

func _get_floor_top_y() -> float:
	return _get_floor_center_y() + floor_thickness * 0.5

func _get_floor_bottom_y() -> float:
	return _get_floor_center_y() - floor_thickness * 0.5

func _is_wall_enabled(surface_name: String) -> bool:
	match surface_name:
		RoomConstants.WALL_BACK:
			return show_wall_back
		RoomConstants.WALL_LEFT:
			return show_wall_left
		RoomConstants.WALL_FRONT:
			return show_wall_front
		RoomConstants.WALL_RIGHT:
			return show_wall_right
		_:
			return false

func _apply_floor_material() -> void:
	var visual := floor.get_node_or_null("Visual") as MeshInstance3D
	RoomFloorMaterials.apply_floor_material(visual, floor_style, room_half_extents)
