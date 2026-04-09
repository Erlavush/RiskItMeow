@tool
class_name MacawsCeilingFanPlaceable
extends ImportedScenePlaceable

const WorldTimeControllerScript := preload("res://scripts/world/world_time_controller.gd")
const DEFAULT_FAN_SPEED_DEGREES_PER_SECOND := 240.0
const FAN_BODY_NODE_NAME := "fan_body"
const FAN_BLADES_NODE_NAME := "fan_blades"
const FAN_BLADE_PIVOT_NODE_NAME := "FanBladePivot"

var _fan_speed_degrees_per_second := DEFAULT_FAN_SPEED_DEGREES_PER_SECOND
var _fan_body: Node3D
var _fan_blades: Node3D
var _fan_blade_pivot: Node3D
var _fallback_rotation_radians := 0.0

func _ready() -> void:
	super._ready()
	_refresh_fan_nodes()
	set_process(true)

func _process(delta: float) -> void:
	if _is_preview:
		return
	if _fan_blade_pivot == null or not is_instance_valid(_fan_blade_pivot):
		_refresh_fan_nodes()
		if _fan_blade_pivot == null:
			return
	_fan_blade_pivot.rotation.y = _get_runtime_fan_rotation(delta)

func configure_from_item_def(item_def: Dictionary) -> void:
	super.configure_from_item_def(item_def)
	_fan_speed_degrees_per_second = float(item_def.get("fan_speed_degrees_per_second", DEFAULT_FAN_SPEED_DEGREES_PER_SECOND))
	_refresh_fan_nodes()

func ensure_runtime_visual_setup() -> void:
	super.ensure_runtime_visual_setup()
	_refresh_fan_nodes()

func _refresh_fan_nodes() -> void:
	_fan_body = find_child(FAN_BODY_NODE_NAME, true, false) as Node3D
	_fan_blades = find_child(FAN_BLADES_NODE_NAME, true, false) as Node3D
	_fan_blade_pivot = find_child(FAN_BLADE_PIVOT_NODE_NAME, true, false) as Node3D
	if _fan_blades == null:
		return
	if _fan_blade_pivot == null:
		_fan_blade_pivot = _create_blade_pivot()

func _create_blade_pivot() -> Node3D:
	if _fan_blades == null:
		return null
	var fan_parent := _fan_blades.get_parent() as Node3D
	if fan_parent == null:
		return null

	var blades_center_global := _get_bounds_center_global(_fan_blades)
	var pivot_center_global := blades_center_global
	if _fan_body != null:
		var body_center_global := _get_bounds_center_global(_fan_body)
		pivot_center_global.x = body_center_global.x
		pivot_center_global.z = body_center_global.z

	var pivot := Node3D.new()
	pivot.name = FAN_BLADE_PIVOT_NODE_NAME
	fan_parent.add_child(pivot)
	pivot.owner = owner
	pivot.position = fan_parent.to_local(pivot_center_global)

	var blades_global_transform := _fan_blades.global_transform
	fan_parent.remove_child(_fan_blades)
	pivot.add_child(_fan_blades)
	_fan_blades.global_transform = blades_global_transform
	return pivot

func _get_runtime_fan_rotation(delta: float) -> float:
	var time_controller := get_tree().get_first_node_in_group(WorldTimeControllerScript.GROUP_NAME) as WorldTimeController
	if time_controller != null:
		var elapsed_seconds := (float(time_controller.get_game_time()) + time_controller.get_partial_tick()) / WorldTimeControllerScript.TICKS_PER_SECOND
		return wrapf(elapsed_seconds * deg_to_rad(_fan_speed_degrees_per_second), 0.0, TAU)

	_fallback_rotation_radians = wrapf(
		_fallback_rotation_radians + delta * deg_to_rad(_fan_speed_degrees_per_second),
		0.0,
		TAU
	)
	return _fallback_rotation_radians

func _get_bounds_center_global(root: Node3D) -> Vector3:
	var bounds := _compute_runtime_bounds_world(root)
	var minimum: Vector3 = bounds.get("min", root.global_position) as Vector3
	var maximum: Vector3 = bounds.get("max", root.global_position) as Vector3
	return (minimum + maximum) * 0.5

func _compute_runtime_bounds_world(root: Node3D) -> Dictionary:
	var state: Dictionary = {
		"ready": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	var initial_transform := Transform3D.IDENTITY
	var root_parent := root.get_parent_node_3d()
	if root_parent != null:
		initial_transform = root_parent.global_transform
	_accumulate_runtime_bounds_recursive(root, initial_transform, state)
	if not state.get("ready", false):
		return {
			"min": root.global_position,
			"max": root.global_position,
		}
	return {
		"min": state.get("min", root.global_position),
		"max": state.get("max", root.global_position),
	}

func _accumulate_runtime_bounds_recursive(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
		if node_3d is MeshInstance3D:
			var mesh_instance := node_3d as MeshInstance3D
			if mesh_instance.mesh != null and mesh_instance.visible:
				_merge_runtime_mesh_aabb(mesh_instance.mesh.get_aabb(), current_transform, state)
	for child in node.get_children():
		_accumulate_runtime_bounds_recursive(child, current_transform, state)

func _merge_runtime_mesh_aabb(aabb: AABB, aabb_transform: Transform3D, state: Dictionary) -> void:
	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	for corner in corners:
		var world_corner: Vector3 = aabb_transform * corner
		if not state.get("ready", false):
			state["ready"] = true
			state["min"] = world_corner
			state["max"] = world_corner
			continue
		var minimum: Vector3 = state.get("min", world_corner) as Vector3
		var maximum: Vector3 = state.get("max", world_corner) as Vector3
		minimum.x = minf(minimum.x, world_corner.x)
		minimum.y = minf(minimum.y, world_corner.y)
		minimum.z = minf(minimum.z, world_corner.z)
		maximum.x = maxf(maximum.x, world_corner.x)
		maximum.y = maxf(maximum.y, world_corner.y)
		maximum.z = maxf(maximum.z, world_corner.z)
		state["min"] = minimum
		state["max"] = maximum
