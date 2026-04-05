@tool
class_name RoomSunlightController
extends Node3D

const RoomConstants := preload("res://scripts/room/room_constants.gd")
const WINDOW_ITEM_IDS := ["window", "window_classic"]

@export var room_shell_path: NodePath
@export var placement_manager_path: NodePath
@export var directional_light_path: NodePath
@export var developer_environment_panel_path: NodePath

var _room_shell: RoomShell
var _placement_manager: PlacementManager
var _directional_light: DirectionalLight3D
var _developer_environment_panel: DeveloperEnvironmentPanel
var _bounce_light: OmniLight3D
var _portal_lights: Dictionary = {}
var _sync_requested := false

func _ready() -> void:
	_room_shell = get_node_or_null(room_shell_path) as RoomShell
	_placement_manager = get_node_or_null(placement_manager_path) as PlacementManager
	_directional_light = get_node_or_null(directional_light_path) as DirectionalLight3D
	_developer_environment_panel = _resolve_developer_environment_panel()
	_ensure_bounce_light()
	_connect_runtime_signals()
	_request_sunlight_sync(true)

func _connect_runtime_signals() -> void:
	if _placement_manager != null and _placement_manager.has_signal("room_layout_visuals_changed"):
		var placement_callback := Callable(self, "_on_room_layout_visuals_changed")
		if not _placement_manager.room_layout_visuals_changed.is_connected(placement_callback):
			_placement_manager.room_layout_visuals_changed.connect(placement_callback)
	if _developer_environment_panel != null and _developer_environment_panel.has_signal("environment_state_changed"):
		var environment_callback := Callable(self, "_on_environment_state_changed")
		if not _developer_environment_panel.environment_state_changed.is_connected(environment_callback):
			_developer_environment_panel.environment_state_changed.connect(environment_callback)

func _resolve_developer_environment_panel() -> DeveloperEnvironmentPanel:
	var panel := get_node_or_null(developer_environment_panel_path) as DeveloperEnvironmentPanel
	if panel != null:
		return panel
	return get_node_or_null("../DeveloperEnvironmentPanel") as DeveloperEnvironmentPanel

func _request_sunlight_sync(force: bool = false) -> void:
	if force:
		_sync_requested = false
		_sync_window_sunlight(true)
		return
	if _sync_requested:
		return
	_sync_requested = true
	call_deferred("_flush_sunlight_sync")

func _flush_sunlight_sync() -> void:
	_sync_requested = false
	_sync_window_sunlight()

func _on_room_layout_visuals_changed() -> void:
	_request_sunlight_sync()

func _on_environment_state_changed() -> void:
	_request_sunlight_sync()

func _ensure_bounce_light() -> void:
	_bounce_light = get_node_or_null("InteriorBounceLight") as OmniLight3D
	if _bounce_light != null:
		return

	_bounce_light = OmniLight3D.new()
	_bounce_light.name = "InteriorBounceLight"
	_bounce_light.light_color = Color(1.0, 0.86, 0.68, 1.0)
	_bounce_light.light_energy = 0.0
	_bounce_light.shadow_enabled = false
	_bounce_light.omni_range = 10.0
	_bounce_light.omni_attenuation = 1.0
	_bounce_light.visible = false
	add_child(_bounce_light)

func _sync_window_sunlight(force: bool = false) -> void:
	if _room_shell == null or _placement_manager == null or _directional_light == null:
		_set_portals_hidden()
		if _bounce_light != null:
			_bounce_light.visible = false
		return

	var sun_from_direction := _directional_light.global_basis.z.normalized()
	var seen_ids: Dictionary = {}
	var total_exposure := 0.0

	for window in _get_window_placeables():
		if window == null:
			continue

		var instance_id := window.get_instance_id()
		seen_ids[instance_id] = true
		var surface_name := String(window.get_meta("placement_surface")) if window.has_meta("placement_surface") else RoomConstants.FLOOR_SURFACE
		if not RoomConstants.is_wall_surface(surface_name):
			_set_portal_light_visible(instance_id, false)
			continue

		var outward_normal := _get_wall_outward_normal(surface_name)
		var exposure := maxf(0.0, outward_normal.dot(sun_from_direction))
		if exposure <= 0.05:
			_set_portal_light_visible(instance_id, false)
			continue

		total_exposure += exposure
		var inward_normal := -outward_normal
		var portal_light := _get_or_create_portal_light(instance_id)
		var portal_position := window.global_position + inward_normal * 0.35 + Vector3.UP * 0.05
		portal_light.global_position = portal_position
		portal_light.look_at(portal_position + inward_normal + Vector3.DOWN * 0.18, Vector3.UP)
		portal_light.light_color = _get_portal_light_color()
		portal_light.light_energy = lerpf(0.72, 1.62, minf(exposure, 1.0))
		portal_light.spot_range = maxf(5.5, (_room_shell.room_half_extents.x + _room_shell.room_half_extents.y) * 0.8)
		portal_light.visible = true

	for portal_id in _portal_lights.keys():
		if not seen_ids.has(portal_id):
			var stale_light := _portal_lights.get(portal_id) as SpotLight3D
			if stale_light != null:
				stale_light.queue_free()
			_portal_lights.erase(portal_id)

	_update_bounce_light(total_exposure)

func _update_bounce_light(total_exposure: float) -> void:
	if _bounce_light == null or _room_shell == null:
		return

	_bounce_light.global_position = _room_shell.get_room_center() + Vector3(0.0, -0.15, 0.0)
	_bounce_light.light_color = _get_bounce_light_color()
	_bounce_light.omni_range = maxf(8.0, maxf(_room_shell.room_half_extents.x, _room_shell.room_half_extents.y) * 3.0)
	_bounce_light.light_energy = minf(1.08, total_exposure * 0.34)
	_bounce_light.visible = total_exposure > 0.05

func _get_window_placeables() -> Array[SimpleWoodChair]:
	var windows: Array[SimpleWoodChair] = []
	if _placement_manager == null or _placement_manager._placed_items_root == null:
		return windows

	for child in _placement_manager._placed_items_root.get_children():
		var placeable := child as SimpleWoodChair
		if placeable == null:
			continue
		if not placeable.has_meta("item_id") or not WINDOW_ITEM_IDS.has(String(placeable.get_meta("item_id"))):
			continue
		windows.append(placeable)

	return windows

func _get_or_create_portal_light(instance_id: int) -> SpotLight3D:
	if _portal_lights.has(instance_id):
		var cached := _portal_lights.get(instance_id) as SpotLight3D
		if cached != null:
			return cached

	var portal_light := SpotLight3D.new()
	portal_light.name = "SunPortalLight_%s" % instance_id
	portal_light.light_color = _get_portal_light_color()
	portal_light.light_energy = 0.75
	portal_light.shadow_enabled = false
	portal_light.spot_angle = 72.0
	portal_light.spot_angle_attenuation = 0.7
	portal_light.spot_attenuation = 1.0
	portal_light.visible = false
	add_child(portal_light)
	_portal_lights[instance_id] = portal_light
	return portal_light

func _get_portal_light_color() -> Color:
	if _directional_light == null:
		return Color(1.0, 0.86, 0.68, 1.0)
	return _directional_light.light_color.lerp(Color(1.0, 0.82, 0.62, 1.0), 0.45)

func _get_bounce_light_color() -> Color:
	if _directional_light == null:
		return Color(1.0, 0.82, 0.62, 1.0)
	return _directional_light.light_color.lerp(Color(0.96, 0.76, 0.56, 1.0), 0.5)

func _set_portal_light_visible(instance_id: int, is_visible: bool) -> void:
	var portal_light := _portal_lights.get(instance_id) as SpotLight3D
	if portal_light != null:
		portal_light.visible = is_visible

func _set_portals_hidden() -> void:
	for portal_light in _portal_lights.values():
		var light_node := portal_light as SpotLight3D
		if light_node != null:
			light_node.visible = false

func _get_wall_outward_normal(surface_name: String) -> Vector3:
	match surface_name:
		RoomConstants.WALL_BACK:
			return Vector3.BACK
		RoomConstants.WALL_FRONT:
			return Vector3.FORWARD
		RoomConstants.WALL_LEFT:
			return Vector3.LEFT
		RoomConstants.WALL_RIGHT:
			return Vector3.RIGHT
		_:
			return Vector3.ZERO
