class_name RoomFloorMaterials
extends RefCounted

const FloorCheckerShader := preload("res://shaders/floor_checker.gdshader")
const FloorCozyBrownShader := preload("res://shaders/floor_cozy_brown.gdshader")
const FloorCozyBrownTexture := preload("res://assets/textures/floors/dark_brown_linen_floor_32.png")

static func apply_floor_material(visual: MeshInstance3D, floor_style: int, room_half_extents: Vector2) -> void:
	if visual == null:
		return

	match floor_style:
		1:
			_apply_checker_material(visual)
		_:
			_apply_cozy_brown_material(visual, room_half_extents)

static func _apply_checker_material(visual: MeshInstance3D) -> void:
	var shader_material := visual.material_override as ShaderMaterial
	if shader_material == null or shader_material.shader != FloorCheckerShader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = FloorCheckerShader
		visual.material_override = shader_material

	shader_material.set_shader_parameter("checker_size", RoomConstants.DEFAULT_GRID_SIZE)
	shader_material.set_shader_parameter("light_color", Color(0.67, 0.67, 0.67, 1.0))
	shader_material.set_shader_parameter("dark_color", Color(0.12, 0.12, 0.12, 1.0))
	shader_material.set_shader_parameter("roughness_value", 0.96)

static func _apply_cozy_brown_material(visual: MeshInstance3D, room_half_extents: Vector2) -> void:
	var floor_texture := FloorCozyBrownTexture
	if floor_texture == null:
		return

	var shader_material := visual.material_override as ShaderMaterial
	if shader_material == null or shader_material.shader != FloorCozyBrownShader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = FloorCozyBrownShader
		visual.material_override = shader_material

	shader_material.set_shader_parameter("side_color", Color(0.133, 0.051, 0.016, 1.0))
	shader_material.set_shader_parameter("floor_texture", floor_texture)
	shader_material.set_shader_parameter(
		"uv_scale",
		Vector2(
			room_half_extents.x * 2.0 / RoomConstants.DEFAULT_GRID_SIZE,
			room_half_extents.y * 2.0 / RoomConstants.DEFAULT_GRID_SIZE
		)
	)
	shader_material.set_shader_parameter("roughness_value", 0.98)
