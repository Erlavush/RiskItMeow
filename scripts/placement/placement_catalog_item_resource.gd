@tool
class_name PlacementCatalogItemResource
extends Resource

@export var id := ""
@export var display_name := ""
@export var category := "Miscellaneous"
@export var initial_owned := 0

@export var factory_type := ""
@export var item_script: Script
@export var source_scene_path := ""

@export var mount_kind := RoomConstants.MOUNT_FLOOR
@export var mount_kinds: Array[String] = []
@export var supported_wall_surfaces: Array[String] = []
@export var support_surfaces: Array = []

@export var collision_size := Vector3.ONE
@export var collision_center_offset := Vector3.ZERO
@export var footprint_half_extents := Vector2.ONE * 0.5
@export var wall_half_extents := Vector2.ONE * 0.5
@export var wall_opening_half_extents := Vector2.ONE * 0.5

@export var visual_scale := Vector3.ONE
@export var visual_y_offset := 0.0
@export var visual_yaw := 0.0
@export var preview_yaw := 0.0
@export var visual_fit_height := 0.0

@export var source_node_names: Array[String] = []
@export var anchor_mode := ""
@export var supports_rotation := true
@export var wall_rotation_offset := 0.0
@export var runtime_shadow_cast_setting := -1

@export var can_host_surface_items := false
@export var requires_wall_opening := false
@export var supports_studio_edit := false
@export var fan_speed_degrees_per_second := 0.0

func to_item_def() -> Dictionary:
	var item_def: Dictionary = {
		"id": id,
		"display_name": display_name,
		"category": category,
		"initial_owned": initial_owned,
		"mount_kind": mount_kind,
		"mount_kinds": mount_kinds.duplicate(),
		"supported_wall_surfaces": supported_wall_surfaces.duplicate(),
		"support_surfaces": support_surfaces.duplicate(true),
		"collision_size": collision_size,
		"collision_center_offset": collision_center_offset,
		"footprint_half_extents": footprint_half_extents,
		"wall_half_extents": wall_half_extents,
		"wall_opening_half_extents": wall_opening_half_extents,
		"visual_scale": visual_scale,
		"visual_y_offset": visual_y_offset,
		"visual_yaw": visual_yaw,
		"preview_yaw": preview_yaw,
		"visual_fit_height": visual_fit_height,
		"source_node_names": source_node_names.duplicate(),
		"anchor_mode": anchor_mode,
		"supports_rotation": supports_rotation,
		"wall_rotation_offset": wall_rotation_offset,
		"runtime_shadow_cast_setting": runtime_shadow_cast_setting,
		"can_host_surface_items": can_host_surface_items,
		"requires_wall_opening": requires_wall_opening,
		"supports_studio_edit": supports_studio_edit,
	}

	if not factory_type.is_empty():
		item_def["factory_type"] = factory_type

	if item_script != null:
		item_def["script"] = item_script

	if not source_scene_path.is_empty():
		item_def["source_scene_path"] = source_scene_path

	if fan_speed_degrees_per_second != 0.0:
		item_def["fan_speed_degrees_per_second"] = fan_speed_degrees_per_second

	return item_def
