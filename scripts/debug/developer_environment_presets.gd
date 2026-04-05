class_name DeveloperEnvironmentPresets
extends RefCounted

const SUN_PRESET_MORNING := "morning"
const SUN_PRESET_NOON := "noon"
const SUN_PRESET_SUNSET := "sunset"
const SUN_PRESET_AFTERNOON_COZY := "afternoon_cozy"

static func get_preset_names() -> Array[String]:
	return [
		SUN_PRESET_MORNING,
		SUN_PRESET_NOON,
		SUN_PRESET_SUNSET,
		SUN_PRESET_AFTERNOON_COZY,
	]

static func get_label(preset_name: String) -> String:
	match preset_name:
		SUN_PRESET_MORNING:
			return "Morning"
		SUN_PRESET_NOON:
			return "Noon"
		SUN_PRESET_SUNSET:
			return "Sunset"
		SUN_PRESET_AFTERNOON_COZY:
			return "Afternoon Cozy"
		_:
			return preset_name.capitalize().replace("_", " ")

static func build_state(preset_name: String, default_values: Dictionary) -> Dictionary:
	match preset_name:
		SUN_PRESET_MORNING:
			return {
				"sky_top_color": Color(0.54, 0.64, 0.76, 1.0),
				"sky_horizon_color": Color(0.98, 0.86, 0.76, 1.0),
				"ground_bottom_color": Color(0.62, 0.52, 0.43, 1.0),
				"ground_horizon_color": Color(0.96, 0.86, 0.77, 1.0),
				"sky_curve": 0.28,
				"ground_curve": 0.2,
				"sun_source_direction_x": 0.72,
				"sun_source_direction_y": 0.46,
				"sun_source_direction_z": 0.52,
				"light_energy": 1.02,
				"directional_shadow_max_distance": 100.0,
				"ambient_light_energy": 0.74,
				"ambient_light_sky_contribution": 0.48,
				"warmth": 0.22,
			}
		SUN_PRESET_NOON:
			return {
				"sky_top_color": default_values.get("sky_top_color", Color(0.17, 0.45, 0.89, 1.0)),
				"sky_horizon_color": default_values.get("sky_horizon_color", Color(0.75, 0.91, 1.0, 1.0)),
				"ground_bottom_color": default_values.get("ground_bottom_color", Color(0.56, 0.82, 0.99, 1.0)),
				"ground_horizon_color": default_values.get("ground_horizon_color", Color(0.75, 0.91, 1.0, 1.0)),
				"sky_curve": float(default_values.get("sky_curve", 0.2)),
				"ground_curve": float(default_values.get("ground_curve", 0.14)),
				"sun_source_direction_x": 0.18,
				"sun_source_direction_y": 0.96,
				"sun_source_direction_z": 0.22,
				"light_energy": 1.2,
				"directional_shadow_max_distance": 100.0,
				"ambient_light_energy": 0.8,
				"ambient_light_sky_contribution": 0.56,
				"warmth": 0.02,
			}
		SUN_PRESET_SUNSET:
			return {
				"sky_top_color": Color(0.88, 0.48, 0.40, 1.0),
				"sky_horizon_color": Color(1.0, 0.72, 0.50, 1.0),
				"ground_bottom_color": Color(0.60, 0.32, 0.20, 1.0),
				"ground_horizon_color": Color(0.98, 0.70, 0.50, 1.0),
				"sky_curve": 0.3,
				"ground_curve": 0.22,
				"sun_source_direction_x": -0.78,
				"sun_source_direction_y": 0.36,
				"sun_source_direction_z": -0.5,
				"light_energy": 0.96,
				"directional_shadow_max_distance": 100.0,
				"ambient_light_energy": 0.66,
				"ambient_light_sky_contribution": 0.38,
				"warmth": 0.42,
			}
		SUN_PRESET_AFTERNOON_COZY:
			return {
				"sky_top_color": Color(0.95, 0.60, 0.42, 1.0),
				"sky_horizon_color": Color(1.0, 0.80, 0.60, 1.0),
				"ground_bottom_color": Color(0.74, 0.44, 0.26, 1.0),
				"ground_horizon_color": Color(1.0, 0.79, 0.60, 1.0),
				"sky_curve": 0.26,
				"ground_curve": 0.18,
				"sun_source_direction_x": 0.82,
				"sun_source_direction_y": 0.42,
				"sun_source_direction_z": 0.38,
				"light_energy": 1.02,
				"shadow_enabled": true,
				"shadow_opacity": 0.8,
				"shadow_blur": 2.25,
				"directional_shadow_max_distance": 100.0,
				"ambient_light_energy": 0.46,
				"ambient_light_sky_contribution": 0.12,
				"tonemap_exposure": 0.97,
				"adjustment_enabled": true,
				"adjustment_brightness": 1.0,
				"adjustment_contrast": 1.17,
				"adjustment_saturation": 1.14,
				"fog_enabled": true,
				"fog_density": 0.026,
				"fog_depth_end": 74.0,
				"fog_light_energy": 0.16,
				"glow_enabled": true,
				"glow_bloom": 0.14,
				"glow_hdr_scale": 1.22,
				"warmth": 0.58,
			}
		_:
			return {}
