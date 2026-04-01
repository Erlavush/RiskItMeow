@tool
class_name MinecraftRig
extends Node3D

enum SkinModel {
	CLASSIC,
	SLIM,
}

enum PivotMode {
	CENTER,
	TOP,
	BOTTOM,
}

const PX := 1.0 / 16.0
const BODY_OUTER_INFLATE_PX := 0.25
const HEAD_OUTER_INFLATE_PX := 0.5

var _skin_model: SkinModel = SkinModel.CLASSIC
@export var skin_model: SkinModel:
	get:
		return _skin_model
	set(value):
		if _skin_model == value:
			return
		_skin_model = value
		_queue_rebuild()

var _skin_path: String = ""
@export_file("*.png") var skin_path: String:
	get:
		return _skin_path
	set(value):
		if _skin_path == value:
			return
		_skin_path = value
		_queue_rebuild()

var _show_outer_layer := true
@export var show_outer_layer := true:
	get:
		return _show_outer_layer
	set(value):
		_show_outer_layer = value
		_apply_outer_visibility()

@export var rebuild_now := false:
	set(value):
		if value:
			_queue_rebuild()
		rebuild_now = false

var material_inner: StandardMaterial3D
var material_outer: StandardMaterial3D

var model_root: Node3D

var head: Node3D
var body: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D

var _outer_meshes: Array[MeshInstance3D] = []
var _rebuild_queued := false

func _ready() -> void:
	# Clean up any statically saved legacy meshes from the previous script run!
	for child in get_children():
		child.queue_free()
	
	_queue_rebuild()

func _queue_rebuild() -> void:
	if not is_inside_tree():
		return
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")

func _rebuild() -> void:
	_rebuild_queued = false
	_ensure_materials()
	_ensure_model_root()
	_clear_model_root()

	var skin_texture := _load_skin_texture(_skin_path)
	material_inner.albedo_texture = skin_texture
	material_outer.albedo_texture = skin_texture

	_build_parts()
	_apply_outer_visibility()

func _ensure_materials() -> void:
	material_inner = StandardMaterial3D.new()
	material_inner.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material_inner.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_inner.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material_inner.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_inner.albedo_color = Color.WHITE

	material_outer = StandardMaterial3D.new()
	material_outer.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material_outer.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_outer.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material_outer.alpha_scissor_threshold = 0.5
	material_outer.cull_mode = BaseMaterial3D.CULL_BACK
	material_outer.albedo_color = Color.WHITE

func _ensure_model_root() -> void:
	if model_root != null and is_instance_valid(model_root):
		return

	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)

func _clear_model_root() -> void:
	_outer_meshes.clear()

	for child in model_root.get_children():
		child.free()

	head = null
	body = null
	arm_l = null
	arm_r = null
	leg_l = null
	leg_r = null

func _build_parts() -> void:
	var arm_width_px := 3.0 if _skin_model == SkinModel.SLIM else 4.0
	var shoulder_x_px := 4.0 + arm_width_px * 0.5

	leg_r = _create_part(
		"RightLeg",
		Vector3(4, 12, 4),
		_right_leg_uv(true),
		_right_leg_uv(false),
		PivotMode.TOP,
		BODY_OUTER_INFLATE_PX
	)
	leg_r.position = Vector3(-2.0 * PX, 12.0 * PX, 0.0)

	leg_l = _create_part(
		"LeftLeg",
		Vector3(4, 12, 4),
		_left_leg_uv(true),
		_left_leg_uv(false),
		PivotMode.TOP,
		BODY_OUTER_INFLATE_PX
	)
	leg_l.position = Vector3(2.0 * PX, 12.0 * PX, 0.0)

	body = _create_part(
		"Body",
		Vector3(8, 12, 4),
		_body_uv(true),
		_body_uv(false),
		PivotMode.CENTER,
		BODY_OUTER_INFLATE_PX
	)
	body.position = Vector3(0.0, 18.0 * PX, 0.0)

	head = _create_part(
		"Head",
		Vector3(8, 8, 8),
		_head_uv(true),
		_head_uv(false),
		PivotMode.BOTTOM,
		HEAD_OUTER_INFLATE_PX
	)
	head.position = Vector3(0.0, 24.0 * PX, 0.0)

	arm_r = _create_part(
		"RightArm",
		Vector3(arm_width_px, 12, 4),
		_right_arm_uv(true, _skin_model == SkinModel.SLIM),
		_right_arm_uv(false, _skin_model == SkinModel.SLIM),
		PivotMode.TOP,
		BODY_OUTER_INFLATE_PX
	)
	arm_r.position = Vector3(-shoulder_x_px * PX, 24.0 * PX, 0.0)

	arm_l = _create_part(
		"LeftArm",
		Vector3(arm_width_px, 12, 4),
		_left_arm_uv(true, _skin_model == SkinModel.SLIM),
		_left_arm_uv(false, _skin_model == SkinModel.SLIM),
		PivotMode.TOP,
		BODY_OUTER_INFLATE_PX
	)
	arm_l.position = Vector3(shoulder_x_px * PX, 24.0 * PX, 0.0)

func _create_part(
	part_name: String,
	size_px: Vector3,
	inner_uv: Dictionary,
	outer_uv: Dictionary,
	pivot_mode: PivotMode,
	outer_inflate_px: float
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	model_root.add_child(pivot)

	var inner := MeshInstance3D.new()
	inner.name = "Inner"
	inner.mesh = _build_cuboid(size_px, inner_uv, 0.0)
	inner.position = _mesh_offset_for_pivot(size_px, pivot_mode)
	inner.material_override = material_inner
	pivot.add_child(inner)

	var outer := MeshInstance3D.new()
	outer.name = "Outer"
	outer.mesh = _build_cuboid(size_px, outer_uv, outer_inflate_px)
	outer.position = _mesh_offset_for_pivot(size_px, pivot_mode)
	outer.material_override = material_outer
	pivot.add_child(outer)

	_outer_meshes.append(outer)

	if part_name == "Head": head = pivot
	elif part_name == "Body": body = pivot
	elif part_name == "RightArm": arm_r = pivot
	elif part_name == "LeftArm": arm_l = pivot
	elif part_name == "RightLeg": leg_r = pivot
	elif part_name == "LeftLeg": leg_l = pivot

	return pivot

func _mesh_offset_for_pivot(size_px: Vector3, pivot_mode: PivotMode) -> Vector3:
	var half_h := size_px.y * 0.5 * PX

	match pivot_mode:
		PivotMode.TOP:
			return Vector3(0.0, -half_h, 0.0)
		PivotMode.BOTTOM:
			return Vector3(0.0, half_h, 0.0)
		_:
			return Vector3.ZERO

func _build_cuboid(size_px: Vector3, uv_map: Dictionary, inflate_px: float) -> ArrayMesh:
	var hx := size_px.x * 0.5 * PX + inflate_px * PX
	var hy := size_px.y * 0.5 * PX + inflate_px * PX
	var hz := size_px.z * 0.5 * PX + inflate_px * PX

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Front (-Z)
	_add_quad(
		st,
		Vector3(hx, hy, -hz),
		Vector3(-hx, hy, -hz),
		Vector3(-hx, -hy, -hz),
		Vector3(hx, -hy, -hz),
		uv_map["front"],
		Vector3(0, 0, -1)
	)

	# Back (+Z)
	_add_quad(
		st,
		Vector3(-hx, hy, hz),
		Vector3(hx, hy, hz),
		Vector3(hx, -hy, hz),
		Vector3(-hx, -hy, hz),
		uv_map["back"],
		Vector3(0, 0, 1)
	)

	# Right (+X)
	_add_quad(
		st,
		Vector3(hx, hy, hz),
		Vector3(hx, hy, -hz),
		Vector3(hx, -hy, -hz),
		Vector3(hx, -hy, hz),
		uv_map["right"],
		Vector3(1, 0, 0)
	)

	# Left (-X)
	_add_quad(
		st,
		Vector3(-hx, hy, -hz),
		Vector3(-hx, hy, hz),
		Vector3(-hx, -hy, hz),
		Vector3(-hx, -hy, -hz),
		uv_map["left"],
		Vector3(-1, 0, 0)
	)

	# Top (+Y)
	_add_quad(
		st,
		Vector3(hx, hy, hz),
		Vector3(-hx, hy, hz),
		Vector3(-hx, hy, -hz),
		Vector3(hx, hy, -hz),
		uv_map["top"],
		Vector3(0, 1, 0)
	)

	# Bottom (-Y)
	_add_quad(
		st,
		Vector3(hx, -hy, -hz),
		Vector3(-hx, -hy, -hz),
		Vector3(-hx, -hy, hz),
		Vector3(hx, -hy, hz),
		uv_map["bottom"],
		Vector3(0, -1, 0)
	)

	return st.commit()

func _add_quad(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	uv_rect: Rect2,
	normal: Vector3
) -> void:
	var uv := _rect_to_uv_clockwise(uv_rect)

	_add_vertex(st, a, uv[0], normal)
	_add_vertex(st, b, uv[1], normal)
	_add_vertex(st, c, uv[2], normal)

	_add_vertex(st, a, uv[0], normal)
	_add_vertex(st, c, uv[2], normal)
	_add_vertex(st, d, uv[3], normal)

func _add_vertex(st: SurfaceTool, vertex: Vector3, uv: Vector2, normal: Vector3) -> void:
	st.set_normal(normal)
	st.set_uv(uv)
	st.add_vertex(vertex)

func _rect_to_uv_clockwise(rect: Rect2) -> Array[Vector2]:
	var tex_size := 64.0
	var u0 := rect.position.x / tex_size
	var v0 := rect.position.y / tex_size
	var u1 := (rect.position.x + rect.size.x) / tex_size
	var v1 := (rect.position.y + rect.size.y) / tex_size

	# TL, TR, BR, BL
	return [
		Vector2(u0, v0),
		Vector2(u1, v0),
		Vector2(u1, v1),
		Vector2(u0, v1),
	]

func load_skin_from_file(file_path: String) -> bool:
	var image := Image.load_from_file(file_path)
	if image == null or image.is_empty():
		push_warning("Could not load image: %s" % file_path)
		return false

	if image.get_width() != 64 or image.get_height() != 64:
		push_warning("Minecraft skin must be 64x64.")
		return false

	_skin_path = file_path
	var texture := ImageTexture.create_from_image(image)
	_apply_texture(texture)
	return true

func _load_skin_texture(path: String) -> Texture2D:
	if path.strip_edges() == "":
		return ImageTexture.create_from_image(_make_fallback_skin())

	# Wait! The earlier AI explicitly noted load() vs Image.load_from_file!
	# The script handles checking ResourceLoader.exists logic, so let's blend the safe approach:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res

	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Could not load skin: %s" % path)
		return ImageTexture.create_from_image(_make_fallback_skin())

	if image.get_width() != 64 or image.get_height() != 64:
		push_warning("Skin must be 64x64: %s" % path)
		return ImageTexture.create_from_image(_make_fallback_skin())

	return ImageTexture.create_from_image(image)

func _apply_texture(texture: Texture2D) -> void:
	if material_inner == null or material_outer == null:
		return
	material_inner.albedo_texture = texture
	material_outer.albedo_texture = texture

func _apply_outer_visibility() -> void:
	for mesh in _outer_meshes:
		if is_instance_valid(mesh):
			mesh.visible = _show_outer_layer

func _make_fallback_skin() -> Image:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.4, 0.2, 1.0)) # Plain brown default skin!
	return image

# We'll use '_process' from our original script to retain the walking motion!
var time := 0.0
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not is_instance_valid(get_parent()): return
	
	# Fallback if no parts exist yet
	if arm_l == null or arm_r == null or leg_l == null or leg_r == null: return
	
	var velocity: Vector3 = get_parent().get("velocity")
	if velocity == null: return
	
	var speed_sq = velocity.x * velocity.x + velocity.z * velocity.z
	if speed_sq > 0.1:
		time += delta * sqrt(speed_sq) * 1.5
		var swing = sin(time) * 1.0
		arm_l.rotation.x = swing
		arm_r.rotation.x = -swing
		leg_l.rotation.x = -swing
		leg_r.rotation.x = swing
	else:
		var reset = delta * 15.0
		arm_l.rotation.x = lerp_angle(arm_l.rotation.x, 0.0, reset)
		arm_r.rotation.x = lerp_angle(arm_r.rotation.x, 0.0, reset)
		leg_l.rotation.x = lerp_angle(leg_l.rotation.x, 0.0, reset)
		leg_r.rotation.x = lerp_angle(leg_r.rotation.x, 0.0, reset)

func _head_uv(base_layer: bool) -> Dictionary:
	var ox := 0 if base_layer else 32
	return {
		"right": Rect2(ox + 0, 8, 8, 8),
		"front": Rect2(ox + 8, 8, 8, 8),
		"left": Rect2(ox + 16, 8, 8, 8),
		"back": Rect2(ox + 24, 8, 8, 8),
		"top": Rect2(ox + 8, 0, 8, 8),
		"bottom": Rect2(ox + 16, 0, 8, 8),
	}

func _body_uv(base_layer: bool) -> Dictionary:
	var oy := 16 if base_layer else 32
	return {
		"right": Rect2(16, oy + 4, 4, 12),
		"front": Rect2(20, oy + 4, 8, 12),
		"left": Rect2(28, oy + 4, 4, 12),
		"back": Rect2(32, oy + 4, 8, 12),
		"top": Rect2(20, oy + 0, 8, 4),
		"bottom": Rect2(28, oy + 0, 8, 4),
	}

func _right_leg_uv(base_layer: bool) -> Dictionary:
	var oy := 16 if base_layer else 32
	return {
		"right": Rect2(0, oy + 4, 4, 12),
		"front": Rect2(4, oy + 4, 4, 12),
		"left": Rect2(8, oy + 4, 4, 12),
		"back": Rect2(12, oy + 4, 4, 12),
		"top": Rect2(4, oy + 0, 4, 4),
		"bottom": Rect2(8, oy + 0, 4, 4),
	}

func _left_leg_uv(base_layer: bool) -> Dictionary:
	var ox := 16 if base_layer else 0
	var oy := 48
	return {
		"right": Rect2(ox + 0, oy + 4, 4, 12),
		"front": Rect2(ox + 4, oy + 4, 4, 12),
		"left": Rect2(ox + 8, oy + 4, 4, 12),
		"back": Rect2(ox + 12, oy + 4, 4, 12),
		"top": Rect2(ox + 4, oy + 0, 4, 4),
		"bottom": Rect2(ox + 8, oy + 0, 4, 4),
	}

func _right_arm_uv(base_layer: bool, slim: bool) -> Dictionary:
	var ox := 40
	var oy := 16 if base_layer else 32

	if slim:
		return {
			"right": Rect2(ox + 0, oy + 4, 4, 12),
			"front": Rect2(ox + 4, oy + 4, 3, 12),
			"left": Rect2(ox + 7, oy + 4, 4, 12),
			"back": Rect2(ox + 11, oy + 4, 3, 12),
			"top": Rect2(ox + 4, oy + 0, 3, 4),
			"bottom": Rect2(ox + 7, oy + 0, 3, 4),
		}

	return {
		"right": Rect2(ox + 0, oy + 4, 4, 12),
		"front": Rect2(ox + 4, oy + 4, 4, 12),
		"left": Rect2(ox + 8, oy + 4, 4, 12),
		"back": Rect2(ox + 12, oy + 4, 4, 12),
		"top": Rect2(ox + 4, oy + 0, 4, 4),
		"bottom": Rect2(ox + 8, oy + 0, 4, 4),
	}

func _left_arm_uv(base_layer: bool, slim: bool) -> Dictionary:
	var ox := 32 if base_layer else 48
	var oy := 48

	if slim:
		return {
			"right": Rect2(ox + 0, oy + 4, 4, 12),
			"front": Rect2(ox + 4, oy + 4, 3, 12),
			"left": Rect2(ox + 7, oy + 4, 4, 12),
			"back": Rect2(ox + 11, oy + 4, 3, 12),
			"top": Rect2(ox + 4, oy + 0, 3, 4),
			"bottom": Rect2(ox + 7, oy + 0, 3, 4),
		}

	return {
		"right": Rect2(ox + 0, oy + 4, 4, 12),
		"front": Rect2(ox + 4, oy + 4, 4, 12),
		"left": Rect2(ox + 8, oy + 4, 4, 12),
		"back": Rect2(ox + 12, oy + 4, 4, 12),
		"top": Rect2(ox + 4, oy + 0, 4, 4),
		"bottom": Rect2(ox + 8, oy + 0, 4, 4),
	}
