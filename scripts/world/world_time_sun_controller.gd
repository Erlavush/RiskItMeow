class_name WorldTimeSunController
extends Node3D

const WorldTimeControllerScript := preload("res://scripts/world/world_time_controller.gd")
const DEFAULT_NOON_DIRECTION := Vector3(0.25, 0.866025, 0.433013)
const SUN_DIRECTIONAL_LIGHT_NAME := "DirectionalLight3D"
const MOON_DIRECTIONAL_LIGHT_NAME := "MoonDirectionalLight"
const MOON_VISUAL_NAME := "MoonVisual"
const LIGHT_ACTIVE_ALTITUDE := 0.02

@export var world_time_controller_path: NodePath
@export var directional_light_path: NodePath
@export var moon_directional_light_path: NodePath
@export var moon_visual_path: NodePath
@export var noon_direction_from_room_to_sun := DEFAULT_NOON_DIRECTION
@export var moon_light_color := Color(0.59, 0.68, 0.92, 1.0)
@export_range(0.0, 1.0, 0.01) var moon_light_energy := 0.14
@export var moon_shadow_enabled := false
@export_range(8.0, 256.0, 1.0) var moon_visual_distance := 56.0
@export_range(0.1, 8.0, 0.05) var moon_visual_scale := 1.15
@export var moon_visual_color := Color(0.92, 0.95, 1.0, 1.0)

var _world_time_controller: Node
var _directional_light: DirectionalLight3D
var _moon_directional_light: DirectionalLight3D
var _moon_visual: MeshInstance3D
var _horizon_direction := Vector3.ZERO
var _sun_shadow_enabled_base := true
var _sun_is_active := true

func _ready() -> void:
	_world_time_controller = _resolve_world_time_controller()
	_directional_light = get_node_or_null(directional_light_path) as DirectionalLight3D
	if _directional_light == null:
		_directional_light = _find_light_by_name(SUN_DIRECTIONAL_LIGHT_NAME)
	_moon_directional_light = _find_light_by_name(MOON_DIRECTIONAL_LIGHT_NAME)
	_moon_visual = _find_mesh_by_name(MOON_VISUAL_NAME)
	if _directional_light != null:
		_sun_shadow_enabled_base = _directional_light.shadow_enabled
	_rebuild_orbit_basis()
	set_process(true)
	call_deferred("_ensure_auxiliary_celestials")
	_sync_celestial_lighting()

func _process(_delta: float) -> void:
	if _world_time_controller == null:
		_world_time_controller = _resolve_world_time_controller()
		if _world_time_controller == null:
			return
	if _directional_light == null:
		_directional_light = get_node_or_null(directional_light_path) as DirectionalLight3D
		if _directional_light == null:
			_directional_light = _find_light_by_name(SUN_DIRECTIONAL_LIGHT_NAME)
	if _moon_directional_light == null:
		_moon_directional_light = _find_light_by_name(MOON_DIRECTIONAL_LIGHT_NAME)
	if _moon_visual == null:
		_moon_visual = _find_mesh_by_name(MOON_VISUAL_NAME)
	if _moon_directional_light == null or _moon_visual == null:
		_ensure_auxiliary_celestials()
	_sync_celestial_lighting()

func _resolve_world_time_controller() -> Node:
	var controller := get_node_or_null(world_time_controller_path)
	if controller != null:
		return controller
	if get_tree() == null:
		return null
	for node in get_tree().get_nodes_in_group(WorldTimeControllerScript.GROUP_NAME):
		if node != null:
			return node
	return null

func _rebuild_orbit_basis() -> void:
	var noon_direction := noon_direction_from_room_to_sun.normalized()
	if noon_direction.length_squared() <= 0.0001:
		noon_direction = Vector3(0.25, 0.866025, 0.433013).normalized()
	noon_direction_from_room_to_sun = noon_direction

	var orbit_normal := noon_direction.cross(Vector3.UP)
	if orbit_normal.length_squared() <= 0.0001:
		orbit_normal = Vector3.RIGHT
	orbit_normal = orbit_normal.normalized()
	_horizon_direction = orbit_normal.cross(noon_direction).normalized()

func _sync_celestial_lighting() -> void:
	if _world_time_controller == null:
		return
	var phase := float(_world_time_controller.call("get_day_progress")) * TAU
	var sun_direction := (-_horizon_direction * cos(phase) + noon_direction_from_room_to_sun * sin(phase)).normalized()
	var moon_direction := -sun_direction
	_apply_sun_state(sun_direction)
	_apply_moon_state(moon_direction)

func _apply_sun_state(sun_direction: Vector3) -> void:
	if _directional_light == null:
		return

	DeveloperEnvironmentState.set_sun_source_direction(_directional_light, sun_direction)
	var sun_altitude := sun_direction.y
	var sun_is_active := sun_altitude > LIGHT_ACTIVE_ALTITUDE
	if sun_is_active:
		if not _sun_is_active:
			_directional_light.visible = true
			_directional_light.shadow_enabled = _sun_shadow_enabled_base
		else:
			_sun_shadow_enabled_base = _directional_light.shadow_enabled
			_directional_light.visible = true
	else:
		if _sun_is_active:
			_sun_shadow_enabled_base = _directional_light.shadow_enabled
		_directional_light.visible = false
		_directional_light.shadow_enabled = false
	_sun_is_active = sun_is_active

func _apply_moon_state(moon_direction: Vector3) -> void:
	if _moon_directional_light != null:
		DeveloperEnvironmentState.set_sun_source_direction(_moon_directional_light, moon_direction)
		var moon_altitude := moon_direction.y
		var moon_factor := _get_horizon_light_factor(moon_altitude)
		_moon_directional_light.visible = moon_factor > 0.001
		_moon_directional_light.light_color = moon_light_color
		_moon_directional_light.light_energy = moon_light_energy * moon_factor
		_moon_directional_light.shadow_enabled = moon_shadow_enabled and moon_factor > 0.35

	if _moon_visual != null:
		var moon_visible := moon_direction.y > 0.0
		_moon_visual.visible = moon_visible
		if _moon_visual.is_inside_tree():
			_moon_visual.global_position = global_position + moon_direction * moon_visual_distance
		else:
			_moon_visual.position = moon_direction * moon_visual_distance
		_moon_visual.scale = Vector3.ONE * moon_visual_scale

func _resolve_or_create_moon_directional_light() -> DirectionalLight3D:
	var moon_light := get_node_or_null(moon_directional_light_path) as DirectionalLight3D
	if moon_light != null:
		return moon_light
	moon_light = _find_light_by_name(MOON_DIRECTIONAL_LIGHT_NAME)
	if moon_light != null:
		return moon_light
	var parent_node := get_parent() if get_parent() != null else self
	moon_light = DirectionalLight3D.new()
	moon_light.name = MOON_DIRECTIONAL_LIGHT_NAME
	moon_light.light_color = moon_light_color
	moon_light.light_energy = moon_light_energy
	moon_light.shadow_enabled = moon_shadow_enabled
	moon_light.visible = false
	moon_light.directional_shadow_fade_start = 1.0
	parent_node.add_child(moon_light)
	return moon_light

func _resolve_or_create_moon_visual() -> MeshInstance3D:
	var moon_visual := get_node_or_null(moon_visual_path) as MeshInstance3D
	if moon_visual != null:
		return moon_visual
	var existing_visual := _find_mesh_by_name(MOON_VISUAL_NAME)
	if existing_visual != null:
		return existing_visual
	var parent_node := get_parent() if get_parent() != null else self
	moon_visual = MeshInstance3D.new()
	moon_visual.name = MOON_VISUAL_NAME
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = moon_visual_color * 0.8
	material.albedo_color = moon_visual_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	moon_visual.mesh = sphere_mesh
	moon_visual.material_override = material
	moon_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	moon_visual.visible = false
	parent_node.add_child(moon_visual)
	return moon_visual

func _ensure_auxiliary_celestials() -> void:
	if _moon_directional_light == null:
		_moon_directional_light = _resolve_or_create_moon_directional_light()
	if _moon_visual == null:
		_moon_visual = _resolve_or_create_moon_visual()

func _find_light_by_name(node_name: String) -> DirectionalLight3D:
	var parent_node := get_parent() if get_parent() != null else self
	return parent_node.get_node_or_null(node_name) as DirectionalLight3D

func _find_mesh_by_name(node_name: String) -> MeshInstance3D:
	var parent_node := get_parent() if get_parent() != null else self
	return parent_node.get_node_or_null(node_name) as MeshInstance3D

func _get_horizon_light_factor(altitude: float) -> float:
	return clampf(inverse_lerp(LIGHT_ACTIVE_ALTITUDE, 0.45, altitude), 0.0, 1.0)
