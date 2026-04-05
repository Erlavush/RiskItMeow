class_name DeveloperEnvironmentState
extends RefCounted

static func capture_defaults(environment: Environment, directional_light: DirectionalLight3D) -> Dictionary:
	var values := {}
	var base_ambient_color := Color.WHITE
	var base_fog_color := Color.WHITE
	var base_light_color := Color.WHITE

	if environment != null:
		values["ambient_light_energy"] = environment.ambient_light_energy
		values["ambient_light_sky_contribution"] = environment.ambient_light_sky_contribution
		values["tonemap_exposure"] = environment.tonemap_exposure
		values["adjustment_enabled"] = environment.adjustment_enabled
		values["adjustment_brightness"] = environment.adjustment_brightness
		values["adjustment_contrast"] = environment.adjustment_contrast
		values["adjustment_saturation"] = environment.adjustment_saturation
		values["fog_enabled"] = environment.fog_enabled
		values["fog_density"] = environment.fog_density
		values["fog_depth_end"] = environment.fog_depth_end
		values["fog_light_energy"] = environment.fog_light_energy
		values["glow_enabled"] = environment.glow_enabled
		values["glow_bloom"] = environment.glow_bloom
		values["glow_hdr_scale"] = environment.glow_hdr_scale
		base_ambient_color = environment.ambient_light_color
		base_fog_color = environment.fog_light_color
		var sky_material := get_procedural_sky_material(environment)
		if sky_material != null:
			values["sky_top_color"] = sky_material.sky_top_color
			values["sky_horizon_color"] = sky_material.sky_horizon_color
			values["ground_bottom_color"] = sky_material.ground_bottom_color
			values["ground_horizon_color"] = sky_material.ground_horizon_color
			values["sky_curve"] = sky_material.sky_curve
			values["ground_curve"] = sky_material.ground_curve

	if directional_light != null:
		values["light_energy"] = directional_light.light_energy
		values["shadow_enabled"] = directional_light.shadow_enabled
		values["shadow_opacity"] = directional_light.shadow_opacity
		values["shadow_blur"] = directional_light.shadow_blur
		values["directional_shadow_max_distance"] = directional_light.directional_shadow_max_distance
		var sun_source_direction := capture_sun_source_direction(directional_light)
		values["sun_source_direction_x"] = sun_source_direction.x
		values["sun_source_direction_y"] = sun_source_direction.y
		values["sun_source_direction_z"] = sun_source_direction.z
		base_light_color = directional_light.light_color

	values["warmth"] = 0.0
	return {
		"values": values,
		"base_ambient_color": base_ambient_color,
		"base_fog_color": base_fog_color,
		"base_light_color": base_light_color,
	}

static func capture_current_values(environment: Environment, directional_light: DirectionalLight3D, warmth: float) -> Dictionary:
	var values := {}

	if environment != null:
		values["ambient_light_energy"] = environment.ambient_light_energy
		values["ambient_light_sky_contribution"] = environment.ambient_light_sky_contribution
		values["tonemap_exposure"] = environment.tonemap_exposure
		values["adjustment_enabled"] = environment.adjustment_enabled
		values["adjustment_brightness"] = environment.adjustment_brightness
		values["adjustment_contrast"] = environment.adjustment_contrast
		values["adjustment_saturation"] = environment.adjustment_saturation
		values["fog_enabled"] = environment.fog_enabled
		values["fog_density"] = environment.fog_density
		values["fog_depth_end"] = environment.fog_depth_end
		values["fog_light_energy"] = environment.fog_light_energy
		values["glow_enabled"] = environment.glow_enabled
		values["glow_bloom"] = environment.glow_bloom
		values["glow_hdr_scale"] = environment.glow_hdr_scale
		var sky_material := get_procedural_sky_material(environment)
		if sky_material != null:
			values["sky_top_color"] = sky_material.sky_top_color
			values["sky_horizon_color"] = sky_material.sky_horizon_color
			values["ground_bottom_color"] = sky_material.ground_bottom_color
			values["ground_horizon_color"] = sky_material.ground_horizon_color
			values["sky_curve"] = sky_material.sky_curve
			values["ground_curve"] = sky_material.ground_curve

	if directional_light != null:
		values["light_energy"] = directional_light.light_energy
		values["shadow_enabled"] = directional_light.shadow_enabled
		values["shadow_opacity"] = directional_light.shadow_opacity
		values["shadow_blur"] = directional_light.shadow_blur
		values["directional_shadow_max_distance"] = directional_light.directional_shadow_max_distance
		var sun_source_direction := capture_sun_source_direction(directional_light)
		values["sun_source_direction_x"] = sun_source_direction.x
		values["sun_source_direction_y"] = sun_source_direction.y
		values["sun_source_direction_z"] = sun_source_direction.z

	values["warmth"] = warmth
	return values

static func apply_state_values(
	environment: Environment,
	directional_light: DirectionalLight3D,
	default_values: Dictionary,
	base_ambient_color: Color,
	base_fog_color: Color,
	base_light_color: Color,
	values: Dictionary
) -> float:
	if environment != null:
		environment.ambient_light_energy = float(values.get("ambient_light_energy", environment.ambient_light_energy))
		environment.ambient_light_sky_contribution = float(values.get("ambient_light_sky_contribution", environment.ambient_light_sky_contribution))
		environment.tonemap_exposure = float(values.get("tonemap_exposure", environment.tonemap_exposure))
		environment.adjustment_enabled = bool(values.get("adjustment_enabled", environment.adjustment_enabled))
		environment.adjustment_brightness = float(values.get("adjustment_brightness", environment.adjustment_brightness))
		environment.adjustment_contrast = float(values.get("adjustment_contrast", environment.adjustment_contrast))
		environment.adjustment_saturation = float(values.get("adjustment_saturation", environment.adjustment_saturation))
		environment.fog_enabled = bool(values.get("fog_enabled", environment.fog_enabled))
		environment.fog_density = float(values.get("fog_density", environment.fog_density))
		environment.fog_depth_end = float(values.get("fog_depth_end", environment.fog_depth_end))
		environment.fog_light_energy = float(values.get("fog_light_energy", environment.fog_light_energy))
		environment.glow_enabled = bool(values.get("glow_enabled", environment.glow_enabled))
		environment.glow_bloom = float(values.get("glow_bloom", environment.glow_bloom))
		environment.glow_hdr_scale = float(values.get("glow_hdr_scale", environment.glow_hdr_scale))
		var sky_top_value: Variant = values.get("sky_top_color", null)
		var sky_horizon_value: Variant = values.get("sky_horizon_color", null)
		var ground_bottom_value: Variant = values.get("ground_bottom_color", null)
		var ground_horizon_value: Variant = values.get("ground_horizon_color", null)
		var sky_curve_value: float = float(values.get("sky_curve", default_values.get("sky_curve", 0.2)))
		var ground_curve_value: float = float(values.get("ground_curve", default_values.get("ground_curve", 0.14)))
		if sky_top_value is Color and sky_horizon_value is Color and ground_bottom_value is Color and ground_horizon_value is Color:
			set_sky_palette(
				environment,
				sky_top_value as Color,
				sky_horizon_value as Color,
				ground_bottom_value as Color,
				ground_horizon_value as Color,
				sky_curve_value,
				ground_curve_value
			)

	if directional_light != null:
		directional_light.light_energy = float(values.get("light_energy", directional_light.light_energy))
		directional_light.shadow_enabled = bool(values.get("shadow_enabled", directional_light.shadow_enabled))
		directional_light.shadow_opacity = float(values.get("shadow_opacity", directional_light.shadow_opacity))
		directional_light.shadow_blur = float(values.get("shadow_blur", directional_light.shadow_blur))
		directional_light.directional_shadow_max_distance = float(values.get("directional_shadow_max_distance", directional_light.directional_shadow_max_distance))
		var sun_source_direction := Vector3(
			float(values.get("sun_source_direction_x", default_values.get("sun_source_direction_x", 0.25))),
			float(values.get("sun_source_direction_y", default_values.get("sun_source_direction_y", 0.866025))),
			float(values.get("sun_source_direction_z", default_values.get("sun_source_direction_z", 0.433013)))
		)
		set_sun_source_direction(directional_light, sun_source_direction)

	var warmth := float(values.get("warmth", 0.0))
	apply_warmth(environment, directional_light, base_ambient_color, base_fog_color, base_light_color, warmth)
	return warmth

static func apply_warmth(
	environment: Environment,
	directional_light: DirectionalLight3D,
	base_ambient_color: Color,
	base_fog_color: Color,
	base_light_color: Color,
	warmth: float
) -> void:
	if environment != null:
		environment.ambient_light_color = apply_warmth_to_color(base_ambient_color, warmth)
		environment.fog_light_color = apply_warmth_to_color(base_fog_color, warmth)

	if directional_light != null:
		directional_light.light_color = apply_warmth_to_color(base_light_color, warmth)

static func apply_warmth_to_color(base_color: Color, warmth: float) -> Color:
	if warmth == 0.0:
		return base_color

	var warm_target := Color(
		clampf(base_color.r * 1.08 + 0.03, 0.0, 1.0),
		clampf(base_color.g * 1.01, 0.0, 1.0),
		clampf(base_color.b * 0.88, 0.0, 1.0),
		base_color.a
	)
	var cool_target := Color(
		clampf(base_color.r * 0.88, 0.0, 1.0),
		clampf(base_color.g * 0.96, 0.0, 1.0),
		clampf(base_color.b * 1.08 + 0.03, 0.0, 1.0),
		base_color.a
	)

	if warmth > 0.0:
		return base_color.lerp(warm_target, warmth)
	return base_color.lerp(cool_target, absf(warmth))

static func capture_sun_source_direction(directional_light: DirectionalLight3D) -> Vector3:
	if directional_light == null:
		return Vector3(0.25, 0.866025, 0.433013)
	return directional_light.global_basis.z.normalized()

static func get_procedural_sky_material(environment: Environment) -> ProceduralSkyMaterial:
	if environment == null or environment.sky == null:
		return null
	return environment.sky.sky_material as ProceduralSkyMaterial

static func set_sky_palette(
	environment: Environment,
	sky_top: Color,
	sky_horizon: Color,
	ground_bottom: Color,
	ground_horizon: Color,
	sky_curve: float = -1.0,
	ground_curve: float = -1.0
) -> void:
	var sky_material := get_procedural_sky_material(environment)
	if sky_material == null:
		return

	sky_material.sky_top_color = sky_top
	sky_material.sky_horizon_color = sky_horizon
	sky_material.ground_bottom_color = ground_bottom
	sky_material.ground_horizon_color = ground_horizon
	if sky_curve >= 0.0:
		sky_material.sky_curve = sky_curve
	if ground_curve >= 0.0:
		sky_material.ground_curve = ground_curve

static func set_sun_source_direction(directional_light: DirectionalLight3D, direction_from_room_to_sun: Vector3) -> void:
	if directional_light == null:
		return

	var normalized_direction := direction_from_room_to_sun.normalized()
	if normalized_direction.length_squared() <= 0.0001:
		return

	var transform_copy := directional_light.transform
	transform_copy.basis = Basis.looking_at(-normalized_direction, Vector3.UP)
	directional_light.transform = transform_copy
