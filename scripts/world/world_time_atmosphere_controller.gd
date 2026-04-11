@tool
class_name WorldTimeAtmosphereController
extends Node

const WorldTimeControllerScript := preload("res://scripts/world/world_time_controller.gd")

const ATMOSPHERE_KEYFRAMES := [
	{
		"tick": 0,
		"sky_top_color": Color(0.36, 0.43, 0.57, 1.0),
		"sky_horizon_color": Color(1.0, 0.74, 0.56, 1.0),
		"ground_bottom_color": Color(0.42, 0.31, 0.24, 1.0),
		"ground_horizon_color": Color(0.98, 0.73, 0.55, 1.0),
		"ambient_color": Color(0.92, 0.85, 0.76, 1.0),
		"ambient_light_energy": 0.52,
		"ambient_light_sky_contribution": 0.34,
		"light_color": Color(1.0, 0.82, 0.66, 1.0),
		"light_energy": 0.84,
		"fog_color": Color(0.95, 0.77, 0.63, 1.0),
		"fog_density": 0.03,
		"fog_depth_end": 72.0,
		"fog_light_energy": 0.14,
		"tonemap_exposure": 0.95,
		"glow_enabled": true,
		"glow_bloom": 0.08,
		"glow_hdr_scale": 1.08,
		"sky_curve": 0.28,
		"ground_curve": 0.2,
	},
	{
		"tick": 3000,
		"sky_top_color": Color(0.44, 0.62, 0.84, 1.0),
		"sky_horizon_color": Color(0.98, 0.88, 0.78, 1.0),
		"ground_bottom_color": Color(0.52, 0.43, 0.35, 1.0),
		"ground_horizon_color": Color(0.95, 0.86, 0.77, 1.0),
		"ambient_color": Color(0.85, 0.91, 0.97, 1.0),
		"ambient_light_energy": 0.7,
		"ambient_light_sky_contribution": 0.46,
		"light_color": Color(1.0, 0.95, 0.88, 1.0),
		"light_energy": 1.02,
		"fog_color": Color(0.79, 0.90, 0.98, 1.0),
		"fog_density": 0.024,
		"fog_depth_end": 82.0,
		"fog_light_energy": 0.12,
		"tonemap_exposure": 1.0,
		"glow_enabled": true,
		"glow_bloom": 0.05,
		"glow_hdr_scale": 1.02,
		"sky_curve": 0.24,
		"ground_curve": 0.16,
	},
	{
		"tick": 6000,
		"sky_top_color": Color(0.18, 0.47, 0.89, 1.0),
		"sky_horizon_color": Color(0.76, 0.92, 1.0, 1.0),
		"ground_bottom_color": Color(0.58, 0.82, 0.98, 1.0),
		"ground_horizon_color": Color(0.76, 0.92, 1.0, 1.0),
		"ambient_color": Color(0.85, 0.91, 0.98, 1.0),
		"ambient_light_energy": 0.82,
		"ambient_light_sky_contribution": 0.56,
		"light_color": Color(1.0, 0.99, 0.96, 1.0),
		"light_energy": 1.18,
		"fog_color": Color(0.82, 0.92, 1.0, 1.0),
		"fog_density": 0.018,
		"fog_depth_end": 96.0,
		"fog_light_energy": 0.08,
		"tonemap_exposure": 1.03,
		"glow_enabled": false,
		"glow_bloom": 0.0,
		"glow_hdr_scale": 1.0,
		"sky_curve": 0.2,
		"ground_curve": 0.14,
	},
	{
		"tick": 9000,
		"sky_top_color": Color(0.42, 0.60, 0.83, 1.0),
		"sky_horizon_color": Color(1.0, 0.84, 0.68, 1.0),
		"ground_bottom_color": Color(0.63, 0.54, 0.42, 1.0),
		"ground_horizon_color": Color(1.0, 0.83, 0.66, 1.0),
		"ambient_color": Color(0.92, 0.86, 0.77, 1.0),
		"ambient_light_energy": 0.64,
		"ambient_light_sky_contribution": 0.28,
		"light_color": Color(1.0, 0.88, 0.74, 1.0),
		"light_energy": 1.02,
		"fog_color": Color(0.94, 0.79, 0.63, 1.0),
		"fog_density": 0.024,
		"fog_depth_end": 76.0,
		"fog_light_energy": 0.16,
		"tonemap_exposure": 0.98,
		"glow_enabled": true,
		"glow_bloom": 0.08,
		"glow_hdr_scale": 1.1,
		"sky_curve": 0.24,
		"ground_curve": 0.18,
	},
	{
		"tick": 12000,
		"sky_top_color": Color(0.80, 0.39, 0.39, 1.0),
		"sky_horizon_color": Color(1.0, 0.69, 0.5, 1.0),
		"ground_bottom_color": Color(0.46, 0.24, 0.17, 1.0),
		"ground_horizon_color": Color(0.99, 0.68, 0.49, 1.0),
		"ambient_color": Color(0.94, 0.76, 0.65, 1.0),
		"ambient_light_energy": 0.44,
		"ambient_light_sky_contribution": 0.18,
		"light_color": Color(1.0, 0.70, 0.56, 1.0),
		"light_energy": 0.84,
		"fog_color": Color(0.92, 0.60, 0.49, 1.0),
		"fog_density": 0.032,
		"fog_depth_end": 68.0,
		"fog_light_energy": 0.18,
		"tonemap_exposure": 0.92,
		"glow_enabled": true,
		"glow_bloom": 0.12,
		"glow_hdr_scale": 1.18,
		"sky_curve": 0.3,
		"ground_curve": 0.22,
	},
	{
		"tick": 15000,
		"sky_top_color": Color(0.22, 0.25, 0.42, 1.0),
		"sky_horizon_color": Color(0.57, 0.42, 0.58, 1.0),
		"ground_bottom_color": Color(0.18, 0.16, 0.22, 1.0),
		"ground_horizon_color": Color(0.44, 0.34, 0.44, 1.0),
		"ambient_color": Color(0.57, 0.62, 0.76, 1.0),
		"ambient_light_energy": 0.28,
		"ambient_light_sky_contribution": 0.16,
		"light_color": Color(0.76, 0.72, 0.86, 1.0),
		"light_energy": 0.42,
		"fog_color": Color(0.36, 0.38, 0.54, 1.0),
		"fog_density": 0.036,
		"fog_depth_end": 60.0,
		"fog_light_energy": 0.11,
		"tonemap_exposure": 0.82,
		"glow_enabled": true,
		"glow_bloom": 0.16,
		"glow_hdr_scale": 1.28,
		"sky_curve": 0.26,
		"ground_curve": 0.2,
	},
	{
		"tick": 18000,
		"sky_top_color": Color(0.05, 0.08, 0.20, 1.0),
		"sky_horizon_color": Color(0.14, 0.22, 0.38, 1.0),
		"ground_bottom_color": Color(0.05, 0.06, 0.12, 1.0),
		"ground_horizon_color": Color(0.1, 0.14, 0.24, 1.0),
		"ambient_color": Color(0.30, 0.39, 0.58, 1.0),
		"ambient_light_energy": 0.18,
		"ambient_light_sky_contribution": 0.12,
		"light_color": Color(0.65, 0.73, 0.93, 1.0),
		"light_energy": 0.28,
		"fog_color": Color(0.12, 0.18, 0.32, 1.0),
		"fog_density": 0.042,
		"fog_depth_end": 54.0,
		"fog_light_energy": 0.08,
		"tonemap_exposure": 0.76,
		"glow_enabled": true,
		"glow_bloom": 0.18,
		"glow_hdr_scale": 1.34,
		"sky_curve": 0.22,
		"ground_curve": 0.18,
	},
	{
		"tick": 21000,
		"sky_top_color": Color(0.16, 0.22, 0.34, 1.0),
		"sky_horizon_color": Color(0.46, 0.55, 0.72, 1.0),
		"ground_bottom_color": Color(0.16, 0.18, 0.24, 1.0),
		"ground_horizon_color": Color(0.34, 0.40, 0.54, 1.0),
		"ambient_color": Color(0.52, 0.61, 0.76, 1.0),
		"ambient_light_energy": 0.26,
		"ambient_light_sky_contribution": 0.18,
		"light_color": Color(0.78, 0.84, 0.96, 1.0),
		"light_energy": 0.34,
		"fog_color": Color(0.28, 0.37, 0.54, 1.0),
		"fog_density": 0.034,
		"fog_depth_end": 62.0,
		"fog_light_energy": 0.09,
		"tonemap_exposure": 0.82,
		"glow_enabled": true,
		"glow_bloom": 0.15,
		"glow_hdr_scale": 1.22,
		"sky_curve": 0.24,
		"ground_curve": 0.18,
	},
]

@export var world_time_controller_path: NodePath
@export var world_environment_path: NodePath
@export var directional_light_path: NodePath
@export var atmosphere_enabled := true
@export_range(0.0, 1.0, 0.01) var atmosphere_strength := 1.0

var _world_time_controller: Node
var _world_environment: WorldEnvironment
var _environment: Environment
var _directional_light: DirectionalLight3D
var _base_values: Dictionary = {}
var _base_ambient_color := Color.WHITE
var _base_fog_color := Color.WHITE
var _base_light_color := Color.WHITE

func _ready() -> void:
	_resolve_dependencies()
	capture_current_as_base()
	set_process(true)
	if atmosphere_enabled:
		apply_atmosphere_now()

func _process(_delta: float) -> void:
	_resolve_dependencies()
	if not atmosphere_enabled:
		return
	apply_atmosphere_now()

func is_atmosphere_enabled() -> bool:
	return atmosphere_enabled

func set_atmosphere_enabled(enabled: bool) -> void:
	atmosphere_enabled = bool(enabled)
	if atmosphere_enabled:
		apply_atmosphere_now()
	else:
		restore_base_state()

func get_atmosphere_strength() -> float:
	return atmosphere_strength

func set_atmosphere_strength(value: float) -> void:
	atmosphere_strength = clampf(value, 0.0, 1.0)
	if atmosphere_enabled:
		apply_atmosphere_now()

func capture_current_as_base() -> void:
	if _environment == null and _directional_light == null:
		return
	var captured := DeveloperEnvironmentState.capture_defaults(_environment, _directional_light)
	_base_values = captured.get("values", {}) as Dictionary
	_base_ambient_color = captured.get("base_ambient_color", Color.WHITE) as Color
	_base_fog_color = captured.get("base_fog_color", Color.WHITE) as Color
	_base_light_color = captured.get("base_light_color", Color.WHITE) as Color

func restore_base_state() -> void:
	if _environment != null:
		_environment.ambient_light_color = _base_ambient_color
		_environment.ambient_light_energy = float(_base_values.get("ambient_light_energy", _environment.ambient_light_energy))
		_environment.ambient_light_sky_contribution = float(_base_values.get("ambient_light_sky_contribution", _environment.ambient_light_sky_contribution))
		_environment.tonemap_exposure = float(_base_values.get("tonemap_exposure", _environment.tonemap_exposure))
		_environment.fog_enabled = bool(_base_values.get("fog_enabled", _environment.fog_enabled))
		_environment.fog_density = float(_base_values.get("fog_density", _environment.fog_density))
		_environment.fog_depth_end = float(_base_values.get("fog_depth_end", _environment.fog_depth_end))
		_environment.fog_light_energy = float(_base_values.get("fog_light_energy", _environment.fog_light_energy))
		_environment.fog_light_color = _base_fog_color
		_environment.glow_enabled = bool(_base_values.get("glow_enabled", _environment.glow_enabled))
		_environment.glow_bloom = float(_base_values.get("glow_bloom", _environment.glow_bloom))
		_environment.glow_hdr_scale = float(_base_values.get("glow_hdr_scale", _environment.glow_hdr_scale))
		DeveloperEnvironmentState.set_sky_palette(
			_environment,
			_base_values.get("sky_top_color", Color(0.17, 0.45, 0.89, 1.0)) as Color,
			_base_values.get("sky_horizon_color", Color(0.75, 0.91, 1.0, 1.0)) as Color,
			_base_values.get("ground_bottom_color", Color(0.56, 0.82, 0.99, 1.0)) as Color,
			_base_values.get("ground_horizon_color", Color(0.75, 0.91, 1.0, 1.0)) as Color,
			float(_base_values.get("sky_curve", 0.2)),
			float(_base_values.get("ground_curve", 0.14))
		)

	if _directional_light != null:
		_directional_light.light_color = _base_light_color
		_directional_light.light_energy = float(_base_values.get("light_energy", _directional_light.light_energy))

func apply_atmosphere_now() -> void:
	if not _can_query_world_time_day_time() or _environment == null or _directional_light == null:
		return

	var day_time := int(_world_time_controller.call("get_day_time"))
	var sampled_state := _sample_state(day_time)
	var strength := clampf(atmosphere_strength, 0.0, 1.0)

	_environment.ambient_light_color = _base_ambient_color.lerp(sampled_state.get("ambient_color", _base_ambient_color) as Color, strength)
	_environment.ambient_light_energy = lerpf(float(_base_values.get("ambient_light_energy", _environment.ambient_light_energy)), float(sampled_state.get("ambient_light_energy", _environment.ambient_light_energy)), strength)
	_environment.ambient_light_sky_contribution = lerpf(float(_base_values.get("ambient_light_sky_contribution", _environment.ambient_light_sky_contribution)), float(sampled_state.get("ambient_light_sky_contribution", _environment.ambient_light_sky_contribution)), strength)
	_environment.tonemap_exposure = lerpf(float(_base_values.get("tonemap_exposure", _environment.tonemap_exposure)), float(sampled_state.get("tonemap_exposure", _environment.tonemap_exposure)), strength)
	_environment.fog_enabled = bool(_base_values.get("fog_enabled", true)) or bool(sampled_state.get("fog_enabled", true))
	_environment.fog_density = lerpf(float(_base_values.get("fog_density", _environment.fog_density)), float(sampled_state.get("fog_density", _environment.fog_density)), strength)
	_environment.fog_depth_end = lerpf(float(_base_values.get("fog_depth_end", _environment.fog_depth_end)), float(sampled_state.get("fog_depth_end", _environment.fog_depth_end)), strength)
	_environment.fog_light_energy = lerpf(float(_base_values.get("fog_light_energy", _environment.fog_light_energy)), float(sampled_state.get("fog_light_energy", _environment.fog_light_energy)), strength)
	_environment.fog_light_color = _base_fog_color.lerp(sampled_state.get("fog_color", _base_fog_color) as Color, strength)
	_environment.glow_enabled = bool(_base_values.get("glow_enabled", false)) or bool(sampled_state.get("glow_enabled", false))
	_environment.glow_bloom = lerpf(float(_base_values.get("glow_bloom", _environment.glow_bloom)), float(sampled_state.get("glow_bloom", _environment.glow_bloom)), strength)
	_environment.glow_hdr_scale = lerpf(float(_base_values.get("glow_hdr_scale", _environment.glow_hdr_scale)), float(sampled_state.get("glow_hdr_scale", _environment.glow_hdr_scale)), strength)
	DeveloperEnvironmentState.set_sky_palette(
		_environment,
		(_base_values.get("sky_top_color", Color(0.17, 0.45, 0.89, 1.0)) as Color).lerp(sampled_state.get("sky_top_color", Color(0.17, 0.45, 0.89, 1.0)) as Color, strength),
		(_base_values.get("sky_horizon_color", Color(0.75, 0.91, 1.0, 1.0)) as Color).lerp(sampled_state.get("sky_horizon_color", Color(0.75, 0.91, 1.0, 1.0)) as Color, strength),
		(_base_values.get("ground_bottom_color", Color(0.56, 0.82, 0.99, 1.0)) as Color).lerp(sampled_state.get("ground_bottom_color", Color(0.56, 0.82, 0.99, 1.0)) as Color, strength),
		(_base_values.get("ground_horizon_color", Color(0.75, 0.91, 1.0, 1.0)) as Color).lerp(sampled_state.get("ground_horizon_color", Color(0.75, 0.91, 1.0, 1.0)) as Color, strength),
		lerpf(float(_base_values.get("sky_curve", 0.2)), float(sampled_state.get("sky_curve", 0.2)), strength),
		lerpf(float(_base_values.get("ground_curve", 0.14)), float(sampled_state.get("ground_curve", 0.14)), strength)
	)
	_directional_light.light_color = _base_light_color.lerp(sampled_state.get("light_color", _base_light_color) as Color, strength)
	_directional_light.light_energy = lerpf(float(_base_values.get("light_energy", _directional_light.light_energy)), float(sampled_state.get("light_energy", _directional_light.light_energy)), strength)

func _resolve_dependencies() -> void:
	if _world_time_controller == null:
		_world_time_controller = _resolve_world_time_controller()
	if _world_environment == null:
		_world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
		_environment = _world_environment.environment if _world_environment != null else null
	if _directional_light == null:
		_directional_light = get_node_or_null(directional_light_path) as DirectionalLight3D

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

func _can_query_world_time_day_time() -> bool:
	if Engine.is_editor_hint():
		return false
	return _world_time_controller != null and _world_time_controller.has_method("get_day_time")

func _sample_state(day_time: int) -> Dictionary:
	var wrapped_day_time := wrapi(day_time, 0, WorldTimeControllerScript.TICKS_PER_DAY)
	var from_keyframe := ATMOSPHERE_KEYFRAMES[0]
	var to_keyframe := ATMOSPHERE_KEYFRAMES[0]
	for index in range(ATMOSPHERE_KEYFRAMES.size()):
		var current_keyframe: Dictionary = ATMOSPHERE_KEYFRAMES[index]
		var next_keyframe: Dictionary = ATMOSPHERE_KEYFRAMES[(index + 1) % ATMOSPHERE_KEYFRAMES.size()]
		var current_tick := int(current_keyframe.get("tick", 0))
		var next_tick := int(next_keyframe.get("tick", WorldTimeControllerScript.TICKS_PER_DAY))
		var wrapped_next_tick := next_tick
		var test_day_time := wrapped_day_time
		if wrapped_next_tick <= current_tick:
			wrapped_next_tick += WorldTimeControllerScript.TICKS_PER_DAY
			if test_day_time < current_tick:
				test_day_time += WorldTimeControllerScript.TICKS_PER_DAY
		if test_day_time >= current_tick and test_day_time <= wrapped_next_tick:
			from_keyframe = current_keyframe
			to_keyframe = next_keyframe
			var blend := inverse_lerp(float(current_tick), float(wrapped_next_tick), float(test_day_time))
			return _interpolate_keyframes(from_keyframe, to_keyframe, blend)
	return ATMOSPHERE_KEYFRAMES[0].duplicate(true)

func _interpolate_keyframes(from_keyframe: Dictionary, to_keyframe: Dictionary, blend: float) -> Dictionary:
	return {
		"sky_top_color": (from_keyframe.get("sky_top_color", Color.BLACK) as Color).lerp(to_keyframe.get("sky_top_color", Color.BLACK) as Color, blend),
		"sky_horizon_color": (from_keyframe.get("sky_horizon_color", Color.BLACK) as Color).lerp(to_keyframe.get("sky_horizon_color", Color.BLACK) as Color, blend),
		"ground_bottom_color": (from_keyframe.get("ground_bottom_color", Color.BLACK) as Color).lerp(to_keyframe.get("ground_bottom_color", Color.BLACK) as Color, blend),
		"ground_horizon_color": (from_keyframe.get("ground_horizon_color", Color.BLACK) as Color).lerp(to_keyframe.get("ground_horizon_color", Color.BLACK) as Color, blend),
		"ambient_color": (from_keyframe.get("ambient_color", Color.WHITE) as Color).lerp(to_keyframe.get("ambient_color", Color.WHITE) as Color, blend),
		"ambient_light_energy": lerpf(float(from_keyframe.get("ambient_light_energy", 0.7)), float(to_keyframe.get("ambient_light_energy", 0.7)), blend),
		"ambient_light_sky_contribution": lerpf(float(from_keyframe.get("ambient_light_sky_contribution", 0.4)), float(to_keyframe.get("ambient_light_sky_contribution", 0.4)), blend),
		"light_color": (from_keyframe.get("light_color", Color.WHITE) as Color).lerp(to_keyframe.get("light_color", Color.WHITE) as Color, blend),
		"light_energy": lerpf(float(from_keyframe.get("light_energy", 1.0)), float(to_keyframe.get("light_energy", 1.0)), blend),
		"fog_color": (from_keyframe.get("fog_color", Color.WHITE) as Color).lerp(to_keyframe.get("fog_color", Color.WHITE) as Color, blend),
		"fog_density": lerpf(float(from_keyframe.get("fog_density", 0.02)), float(to_keyframe.get("fog_density", 0.02)), blend),
		"fog_depth_end": lerpf(float(from_keyframe.get("fog_depth_end", 80.0)), float(to_keyframe.get("fog_depth_end", 80.0)), blend),
		"fog_light_energy": lerpf(float(from_keyframe.get("fog_light_energy", 0.12)), float(to_keyframe.get("fog_light_energy", 0.12)), blend),
		"tonemap_exposure": lerpf(float(from_keyframe.get("tonemap_exposure", 1.0)), float(to_keyframe.get("tonemap_exposure", 1.0)), blend),
		"glow_enabled": bool(from_keyframe.get("glow_enabled", false)) or bool(to_keyframe.get("glow_enabled", false)),
		"glow_bloom": lerpf(float(from_keyframe.get("glow_bloom", 0.0)), float(to_keyframe.get("glow_bloom", 0.0)), blend),
		"glow_hdr_scale": lerpf(float(from_keyframe.get("glow_hdr_scale", 1.0)), float(to_keyframe.get("glow_hdr_scale", 1.0)), blend),
		"sky_curve": lerpf(float(from_keyframe.get("sky_curve", 0.2)), float(to_keyframe.get("sky_curve", 0.2)), blend),
		"ground_curve": lerpf(float(from_keyframe.get("ground_curve", 0.14)), float(to_keyframe.get("ground_curve", 0.14)), blend),
	}
