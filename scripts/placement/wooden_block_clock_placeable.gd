@tool
class_name WoodenBlockClockPlaceable
extends SimpleWoodChair

const CLOCK_DISPLAY_NAME := "Wooden Block Clock"
const BODY_SCENE_PATH := "res://assets/props/tanuki_decor/wooden_block_clock/wooden_block_clock.glb"
const LONG_HAND_SCENE_PATH := "res://assets/props/tanuki_decor/wooden_block_clock/long_hand.glb"
const SHORT_HAND_SCENE_PATH := "res://assets/props/tanuki_decor/wooden_block_clock/short_hand.glb"
const PENDULUM_SCENE_PATH := "res://assets/props/tanuki_decor/wooden_block_clock/pendulum.glb"
const CLOCK_COLLISION_SIZE := Vector3(1.0, 1.45, 0.5)
const HAND_ATTACHMENT_OFFSET := Vector3(0.0, -0.12625, 0.0)
const PENDULUM_ATTACHMENT_OFFSET := Vector3(0, -0.325, 0.0)
const HAND_MESH_Y_OFFSET := 0.0
const PENDULUM_MESH_Y_OFFSET := 0.0
const WALL_ROTATION_OFFSET := PI
const WALL_MOUNT_DEPTH_OFFSET := 0.19
const WorldTimeControllerScript := preload("res://scripts/world/world_time_controller.gd")

var _mount_kind_override := RoomConstants.MOUNT_WALL
var _mount_kinds_override: Array[String] = [RoomConstants.MOUNT_WALL]
var _supported_wall_surfaces_override: Array[String] = []
var _collision_size_override := CLOCK_COLLISION_SIZE
var _has_collision_center_offset_override := false
var _collision_center_offset_override := Vector3.ZERO
var _has_footprint_half_extents_override := false
var _footprint_half_extents_override := Vector2.ZERO
var _has_wall_half_extents_override := false
var _wall_half_extents_override := Vector2.ZERO
var _requires_wall_opening_override := false
var _wall_opening_half_extents_override := Vector2.ZERO
var _can_host_surface_items_override := false
var _support_surfaces_override: Array[Dictionary] = []
var _visual_scale_override := Vector3.	ONE
var _visual_y_offset_override := 0.0
var _visual_yaw_override := 0.0

var _assembly_root: Node3D
var _long_hand_pivot: Node3D	
var _short_hand_pivot: Node3D
var _pendulum_pivot: Node3D
var _world_time_controller: Node

func _ready() -> void:
	super._ready()
	_world_time_controller = _resolve_world_time_controller()
	_apply_clock_animation()
	set_process(true)

func _process(_delta: float) -> void:
	if _world_time_controller == null:
		_world_time_controller = _resolve_world_time_controller()
	_apply_clock_animation()

func get_display_name() -> String:
	return CLOCK_DISPLAY_NAME

func configure_from_item_def(item_def: Dictionary) -> void:
	_mount_kinds_override = _normalize_mount_kinds(item_def.get("mount_kinds", [RoomConstants.MOUNT_WALL]))
	_mount_kind_override = _resolve_primary_mount_kind(item_def)
	_supported_wall_surfaces_override.clear()
	var raw_surfaces: Variant = item_def.get("supported_wall_surfaces", [])
	if raw_surfaces is Array:
		for surface_name in raw_surfaces:
			_supported_wall_surfaces_override.append(String(surface_name))
	_collision_size_override = item_def.get("collision_size", CLOCK_COLLISION_SIZE) as Vector3
	_has_collision_center_offset_override = item_def.has("collision_center_offset")
	_collision_center_offset_override = item_def.get("collision_center_offset", Vector3.ZERO) as Vector3
	_has_footprint_half_extents_override = item_def.has("footprint_half_extents")
	_footprint_half_extents_override = item_def.get("footprint_half_extents", Vector2.ZERO) as Vector2
	_has_wall_half_extents_override = item_def.has("wall_half_extents")
	_wall_half_extents_override = item_def.get("wall_half_extents", Vector2.ZERO) as Vector2
	_requires_wall_opening_override = bool(item_def.get("requires_wall_opening", false))
	_wall_opening_half_extents_override = item_def.get("wall_opening_half_extents", Vector2.ZERO) as Vector2
	_can_host_surface_items_override = bool(item_def.get("can_host_surface_items", false))
	_support_surfaces_override = _normalize_support_surfaces(item_def.get("support_surfaces", []))
	_visual_scale_override = item_def.get("visual_scale", Vector3.ONE) as Vector3
	_visual_y_offset_override = float(item_def.get("visual_y_offset", 0.0))
	_visual_yaw_override = float(item_def.get("visual_yaw", 0.0))

func get_primary_mount_kind() -> String:
	return _mount_kind_override

func get_mount_kinds() -> Array[String]:
	return _mount_kinds_override.duplicate()

func get_supported_wall_surfaces() -> Array[String]:
	return _supported_wall_surfaces_override.duplicate()

func get_collision_size() -> Vector3:
	return _collision_size_override

func get_collision_center_offset() -> Vector3:
	if _has_collision_center_offset_override:
		return _collision_center_offset_override
	return Vector3(0.0, get_collision_size().y * 0.5, 0.0)

func get_footprint_half_extents() -> Vector2:
	if _has_footprint_half_extents_override:
		return _footprint_half_extents_override
	return super.get_footprint_half_extents()

func get_wall_half_extents() -> Vector2:
	if _has_wall_half_extents_override:
		return _wall_half_extents_override
	return super.get_wall_half_extents()

func get_wall_mount_depth_offset() -> float:
	return WALL_MOUNT_DEPTH_OFFSET

func get_wall_rotation_offset() -> float:
	return WALL_ROTATION_OFFSET

func requires_wall_opening() -> bool:
	return _requires_wall_opening_override

func get_wall_opening_half_extents() -> Vector2:
	if _wall_opening_half_extents_override.length_squared() > 0.0001:
		return _wall_opening_half_extents_override
	return super.get_wall_opening_half_extents()

func can_host_surface_items() -> bool:
	return _can_host_surface_items_override or not _support_surfaces_override.is_empty()

func get_support_surfaces() -> Array[Dictionary]:
	if not _support_surfaces_override.is_empty():
		return _support_surfaces_override.duplicate(true)
	if _can_host_surface_items_override:
		return [build_top_support_surface()]
	return []

func _normalize_support_surfaces(raw_surfaces: Variant) -> Array[Dictionary]:
	var support_surfaces: Array[Dictionary] = []
	if raw_surfaces is Array:
		for raw_surface in raw_surfaces:
			if typeof(raw_surface) != TYPE_DICTIONARY:
				continue
			var surface_dict := raw_surface as Dictionary
			var center_offset := surface_dict.get("center_offset", Vector3.ZERO) as Vector3
			var half_extents := surface_dict.get("half_extents", Vector2.ZERO) as Vector2
			if half_extents.x <= 0.001 or half_extents.y <= 0.001:
				continue
			support_surfaces.append(
				{
					"id": String(surface_dict.get("id", "top")),
					"center_offset": center_offset,
					"half_extents": half_extents,
				}
			)
	return support_surfaces

func _ensure_visual() -> void:
	_visual_root = get_node_or_null("VisualRoot") as Node3D
	if _visual_root == null:
		_visual_root = Node3D.new()
		_visual_root.name = "VisualRoot"
		add_child(_visual_root)

	if _visual_root.get_child_count() == 0:
		var assembly := _build_clock_assembly()
		if assembly != null:
			assembly.name = "ClockAssembly"
			_visual_root.add_child(assembly)
		else:
			_create_fallback_visual()

	_mesh_instances.clear()
	_collect_mesh_instances(_visual_root)
	_cache_animation_nodes()

func _build_clock_assembly() -> Node3D:
	var assembly := Node3D.new()
	var body := _instantiate_source_scene(BODY_SCENE_PATH)
	var long_hand := _instantiate_source_scene(LONG_HAND_SCENE_PATH)
	var short_hand := _instantiate_source_scene(SHORT_HAND_SCENE_PATH)
	var pendulum := _instantiate_source_scene(PENDULUM_SCENE_PATH)

	if body == null or long_hand == null or short_hand == null or pendulum == null:
		if body != null:
			body.free()
		if long_hand != null:
			long_hand.free()
		if short_hand != null:
			short_hand.free()
		if pendulum != null:
			pendulum.free()
		assembly.free()
		return null

	body.name = "Body"
	long_hand.name = "LongHandScene"
	short_hand.name = "ShortHandScene"
	pendulum.name = "PendulumScene"
	long_hand.position = HAND_ATTACHMENT_OFFSET
	short_hand.position = HAND_ATTACHMENT_OFFSET
	pendulum.position = PENDULUM_ATTACHMENT_OFFSET

	assembly.add_child(body)
	assembly.add_child(long_hand)
	assembly.add_child(short_hand)
	assembly.add_child(pendulum)
	_tune_imported_part_offsets(long_hand, short_hand, pendulum)

	_anchor_assembly_to_floor_center(assembly)
	assembly.scale = _visual_scale_override
	assembly.position.y += _visual_y_offset_override
	assembly.rotation.y = _visual_yaw_override
	_assembly_root = assembly
	return assembly

func _tune_imported_part_offsets(long_hand: Node3D, short_hand: Node3D, pendulum: Node3D) -> void:
	var long_mesh := long_hand.find_child("long", true, false) as Node3D
	if long_mesh != null:
		long_mesh.position.y = HAND_MESH_Y_OFFSET

	var short_mesh := short_hand.find_child("short", true, false) as Node3D
	if short_mesh != null:
		short_mesh.position.y = HAND_MESH_Y_OFFSET

	var pendulum_mesh := pendulum.find_child("pendulum", true, false) as Node3D
	if pendulum_mesh != null:
		pendulum_mesh.position.y = PENDULUM_MESH_Y_OFFSET

func _instantiate_source_scene(source_path: String) -> Node3D:
	if source_path.ends_with(".glb") or source_path.ends_with(".gltf"):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error_code := document.append_from_file(ProjectSettings.globalize_path(source_path), state)
		if error_code != OK:
			push_warning("Could not load GLTF source at %s" % source_path)
			return null
		return document.generate_scene(state) as Node3D

	var source_scene := load(source_path) as PackedScene
	if source_scene != null:
		return source_scene.instantiate() as Node3D
	return null

func _anchor_assembly_to_floor_center(assembly: Node3D) -> void:
	var anchor_target := assembly.get_node_or_null("Body") as Node3D
	var bounds := _compute_visual_bounds(anchor_target if anchor_target != null else assembly)
	if bounds.is_empty():
		return
	var minimum: Vector3 = bounds.get("min", Vector3.ZERO) as Vector3
	var maximum: Vector3 = bounds.get("max", Vector3.ZERO) as Vector3
	assembly.position = - Vector3(
		(minimum.x + maximum.x) * 0.5,
		minimum.y,
		(minimum.z + maximum.z) * 0.5
	)

func _cache_animation_nodes() -> void:
	_assembly_root = _visual_root.get_node_or_null("ClockAssembly") as Node3D
	if _assembly_root == null:
		return

	var long_hand_scene := _assembly_root.get_node_or_null("LongHandScene") as Node3D
	var short_hand_scene := _assembly_root.get_node_or_null("ShortHandScene") as Node3D
	var pendulum_scene := _assembly_root.get_node_or_null("PendulumScene") as Node3D

	_long_hand_pivot = long_hand_scene.find_child("long2", true, false) as Node3D if long_hand_scene != null else null
	_short_hand_pivot = short_hand_scene.find_child("short2", true, false) as Node3D if short_hand_scene != null else null
	_pendulum_pivot = pendulum_scene.find_child("pendulum2", true, false) as Node3D if pendulum_scene != null else null

func _apply_clock_animation() -> void:
	if _long_hand_pivot == null or _short_hand_pivot == null or _pendulum_pivot == null:
		return

	var hour_rotation := TAU
	var minute_rotation := 0.0
	var pendulum_rotation := 0.0
	if _world_time_controller != null:
		hour_rotation = float(_world_time_controller.call("get_hour_hand_rotation_radians"))
		minute_rotation = float(_world_time_controller.call("get_minute_hand_rotation_radians"))
		pendulum_rotation = float(_world_time_controller.call("get_pendulum_rotation_radians"))

	_short_hand_pivot.rotation.z = hour_rotation
	_long_hand_pivot.rotation.z = minute_rotation
	_pendulum_pivot.rotation.z = _get_pendulum_bias() * pendulum_rotation

func _resolve_world_time_controller() -> Node:
	if get_tree() == null:
		return null
	for node in get_tree().get_nodes_in_group(WorldTimeControllerScript.GROUP_NAME):
		if node != null:
			return node
	return null

func _resolve_primary_mount_kind(item_def: Dictionary) -> String:
	var requested_mount := String(item_def.get("mount_kind", ""))
	if RoomConstants.is_mount_kind(requested_mount):
		if not _mount_kinds_override.has(requested_mount):
			_mount_kinds_override.push_front(requested_mount)
		return requested_mount
	if not _mount_kinds_override.is_empty():
		return _mount_kinds_override[0]
	return RoomConstants.MOUNT_WALL

func _normalize_mount_kinds(raw_mounts: Variant) -> Array[String]:
	var mount_kinds: Array[String] = []
	if raw_mounts is Array:
		for raw_mount in raw_mounts:
			var mount_kind := String(raw_mount)
			if not RoomConstants.is_mount_kind(mount_kind):
				continue
			if mount_kinds.has(mount_kind):
				continue
			mount_kinds.append(mount_kind)
	if mount_kinds.is_empty():
		mount_kinds.append(RoomConstants.MOUNT_WALL)
	return mount_kinds

func _get_pendulum_bias() -> float:
	var cell := Vector3i(roundi(global_position.x), roundi(global_position.y), roundi(global_position.z))
	var key := "%d:%d:%d:%s" % [cell.x, cell.y, cell.z, String(get_meta("instance_id", name))]
	return -1.0 if abs(hash(key)) % 2 == 0 else 1.0

func _compute_visual_bounds(root: Node3D) -> Dictionary:
	var state: Dictionary = {
		"ready": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_node_bounds(root, Transform3D.IDENTITY, state)
	if not bool(state.get("ready", false)):
		return {}
	return {
		"min": state.get("min", Vector3.ZERO),
		"max": state.get("max", Vector3.ZERO),
	}

func _accumulate_node_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
		if node_3d is MeshInstance3D:
			var mesh_instance := node_3d as MeshInstance3D
			if mesh_instance.mesh != null:
				_merge_aabb(mesh_instance.mesh.get_aabb(), current_transform, state)
	for child in node.get_children():
		_accumulate_node_bounds(child, current_transform, state)

func _merge_aabb(aabb: AABB, aabb_transform: Transform3D, state: Dictionary) -> void:
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
		var transformed_corner: Vector3 = aabb_transform * corner
		if not bool(state.get("ready", false)):
			state["min"] = transformed_corner
			state["max"] = transformed_corner
			state["ready"] = true
			continue
		var minimum: Vector3 = state.get("min", Vector3.ZERO) as Vector3
		var maximum: Vector3 = state.get("max", Vector3.ZERO) as Vector3
		minimum.x = minf(minimum.x, transformed_corner.x)
		minimum.y = minf(minimum.y, transformed_corner.y)
		minimum.z = minf(minimum.z, transformed_corner.z)
		maximum.x = maxf(maximum.x, transformed_corner.x)
		maximum.y = maxf(maximum.y, transformed_corner.y)
		maximum.z = maxf(maximum.z, transformed_corner.z)
		state["min"] = minimum
		state["max"] = maximum
