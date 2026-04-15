extends RefCounted
class_name PlacementInteractionController

var placement_manager
var room_shell: RoomShell
var room_camera_controller: Node
var player: Node
var placed_items_root: Node3D

func process_frame(_delta: float) -> void:
	if placement_manager == null:
		return

	if not placement_manager._placement_active or placement_manager._preview_item == null:
		if placement_manager._popup_panel != null:
			placement_manager._popup_panel.visible = false
		if placement_manager._gizmo_root != null:
			placement_manager._gizmo_root.visible = false
		return

	if placement_manager._drag_mode == "":
		placement_manager._hover_target = placement_manager._pick_interaction_target(placement_manager.get_viewport().get_mouse_position())
	else:
		placement_manager._hover_target = placement_manager._drag_mode

	if placement_manager._preview_item != null:
		placement_manager._preview_item.set_hovered(placement_manager._hover_target == "move" or placement_manager._drag_mode == "move")

	placement_manager._update_gizmo_hover_state()
	placement_manager._update_popup_position()
	placement_manager._update_gizmo_transform()

func handle_input(event: InputEvent) -> bool:
	if placement_manager == null or not placement_manager._placement_active or placement_manager._preview_item == null or event == null:
		return false

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return false

		if mouse_button.pressed:
			if placement_manager._is_pointer_over_placement_ui():
				return false

			var target: String = placement_manager._pick_interaction_target(mouse_button.position)
			match target:
				"move", "axis_x", "axis_z", "rotate":
					placement_manager._begin_drag(target, mouse_button.position)
					placement_manager.get_viewport().set_input_as_handled()
					return true
			return false

		if placement_manager._drag_mode != "":
			placement_manager._end_drag()
			placement_manager.get_viewport().set_input_as_handled()
			return true
		return false

	if event is InputEventMouseMotion and placement_manager._drag_mode != "":
		var mouse_motion := event as InputEventMouseMotion
		placement_manager._update_drag(mouse_motion.position)
		placement_manager.get_viewport().set_input_as_handled()
		return true

	return false

func handle_unhandled_input(event: InputEvent) -> bool:
	if placement_manager == null or event == null:
		return false

	if event is InputEventKey and event.pressed and not event.echo:
		var global_key_event := event as InputEventKey
		if placement_manager._handle_runtime_shortcuts(global_key_event):
			placement_manager.get_viewport().set_input_as_handled()
			return true

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if placement_manager._is_edit_mode() and not placement_manager._placement_active and mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed and mouse_button.double_click:
			if placement_manager._is_pointer_over_placement_ui():
				return false

			var picked_item: SimpleWoodChair = placement_manager._pick_placeable_item(mouse_button.position)
			if picked_item != null:
				placement_manager._begin_edit_session(picked_item)
				placement_manager.get_viewport().set_input_as_handled()
				return true
			return false

	if not placement_manager._placement_active:
		if event is InputEventKey and event.pressed and not event.echo:
			var idle_key_event := event as InputEventKey
			if idle_key_event.keycode == KEY_ESCAPE and placement_manager._browser_open:
				placement_manager._set_browser_open(false)
				placement_manager.get_viewport().set_input_as_handled()
				return true
		return false

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				placement_manager._on_confirm_button_pressed()
				placement_manager.get_viewport().set_input_as_handled()
				return true
			KEY_Q:
				if placement_manager._can_rotate_preview():
					placement_manager._rotate_preview(-1)
					placement_manager.get_viewport().set_input_as_handled()
					return true
			KEY_E, KEY_R:
				if placement_manager._can_rotate_preview():
					placement_manager._rotate_preview(1)
					placement_manager.get_viewport().set_input_as_handled()
					return true
			KEY_ESCAPE:
				placement_manager._cancel_current_placement()
				placement_manager.get_viewport().set_input_as_handled()
				return true
	return false

func blocks_room_camera_input(event: InputEvent) -> bool:
	if placement_manager == null or event == null or placement_manager._debug_world_active:
		return false

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if placement_manager._is_pointer_over_placement_ui():
			match mouse_button.button_index:
				MOUSE_BUTTON_LEFT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT:
					return true

	if placement_manager._placement_active:
		if placement_manager._drag_mode != "":
			if event is InputEventMouseButton:
				var drag_mouse_button := event as InputEventMouseButton
				return drag_mouse_button.button_index == MOUSE_BUTTON_LEFT
			return event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

		if event is InputEventMouseButton:
			var placement_mouse_button := event as InputEventMouseButton
			return placement_mouse_button.button_index == MOUSE_BUTTON_LEFT \
				and placement_mouse_button.pressed \
				and placement_manager._has_camera_conflicting_placement_target(placement_mouse_button.position)
		return false

	if placement_manager._is_edit_mode() and not placement_manager._placement_active and event is InputEventMouseButton:
		var edit_mouse_button := event as InputEventMouseButton
		return edit_mouse_button.button_index == MOUSE_BUTTON_LEFT \
			and edit_mouse_button.pressed \
			and edit_mouse_button.double_click \
			and not placement_manager._is_pointer_over_placement_ui()

	return false
