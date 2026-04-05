class_name MinecraftRigMeshBuilder
extends RefCounted

const PX := 1.0 / 16.0
const PIVOT_CENTER := 0
const PIVOT_TOP := 1
const PIVOT_BOTTOM := 2

static func create_part(
	model_root: Node3D,
	outer_meshes: Array[MeshInstance3D],
	material_inner: Material,
	material_outer: Material,
	part_name: String,
	size_px: Vector3,
	inner_uv: Dictionary,
	outer_uv: Dictionary,
	pivot_mode: int,
	outer_inflate_px: float
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	model_root.add_child(pivot)

	var inner := MeshInstance3D.new()
	inner.name = "Inner"
	inner.mesh = build_cuboid(size_px, inner_uv, 0.0)
	inner.position = mesh_offset_for_pivot(size_px, pivot_mode)
	inner.material_override = material_inner
	pivot.add_child(inner)

	var outer := MeshInstance3D.new()
	outer.name = "Outer"
	outer.mesh = build_cuboid(size_px, outer_uv, outer_inflate_px)
	outer.position = mesh_offset_for_pivot(size_px, pivot_mode)
	outer.material_override = material_outer
	pivot.add_child(outer)

	outer_meshes.append(outer)
	return pivot

static func mesh_offset_for_pivot(size_px: Vector3, pivot_mode: int) -> Vector3:
	var half_h := size_px.y * 0.5 * PX

	match pivot_mode:
		PIVOT_TOP:
			return Vector3(0.0, -half_h, 0.0)
		PIVOT_BOTTOM:
			return Vector3(0.0, half_h, 0.0)
		_:
			return Vector3.ZERO

static func build_cuboid(size_px: Vector3, uv_map: Dictionary, inflate_px: float) -> ArrayMesh:
	var hx := size_px.x * 0.5 * PX + inflate_px * PX
	var hy := size_px.y * 0.5 * PX + inflate_px * PX
	var hz := size_px.z * 0.5 * PX + inflate_px * PX

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_quad(st, Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz), Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), uv_map["front"], Vector3(0, 0, -1))
	_add_quad(st, Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz), uv_map["back"], Vector3(0, 0, 1))
	_add_quad(st, Vector3(hx, hy, hz), Vector3(hx, hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), uv_map["right"], Vector3(1, 0, 0))
	_add_quad(st, Vector3(-hx, hy, -hz), Vector3(-hx, hy, hz), Vector3(-hx, -hy, hz), Vector3(-hx, -hy, -hz), uv_map["left"], Vector3(-1, 0, 0))
	_add_quad(st, Vector3(hx, hy, hz), Vector3(-hx, hy, hz), Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz), uv_map["top"], Vector3(0, 1, 0))
	_add_quad(st, Vector3(hx, -hy, -hz), Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), uv_map["bottom"], Vector3(0, -1, 0))

	return st.commit()

static func _add_quad(
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

static func _add_vertex(st: SurfaceTool, vertex: Vector3, uv: Vector2, normal: Vector3) -> void:
	st.set_normal(normal)
	st.set_uv(uv)
	st.add_vertex(vertex)

static func _rect_to_uv_clockwise(rect: Rect2) -> Array[Vector2]:
	var tex_size := 64.0
	var u0 := rect.position.x / tex_size
	var v0 := rect.position.y / tex_size
	var u1 := (rect.position.x + rect.size.x) / tex_size
	var v1 := (rect.position.y + rect.size.y) / tex_size
	return [
		Vector2(u0, v0),
		Vector2(u1, v0),
		Vector2(u1, v1),
		Vector2(u0, v1),
	]
