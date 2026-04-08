extends SceneTree

var _root_control: Control

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_root_control = Control.new()
	_root_control.name = "PreviewGeneratorRoot"
	_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_root_control)

	var item_defs := PlacementInventoryCatalog.build_item_defs()
	print("Generating previews for %d items..." % item_defs.size())

	for item_def in item_defs:
		await _generate_preview_for_item(item_def)

	print("Preview generation finished.")
	quit(0)

func _generate_preview_for_item(item_def: Dictionary) -> void:
	var preview := PlacementItemPreview.new()
	preview.name = "Preview_%s" % String(item_def.get("id", "item"))
	_root_control.add_child(preview)
	preview.configure(item_def, Callable(self, "_create_item_instance"))

	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw

	var image := preview.capture_image()
	if image != null and not image.is_empty():
		var preview_path := PlacementPreviewCache.get_preview_image_path(item_def)
		if not PlacementPreviewCache.save_preview_image(image, preview_path):
			push_warning("Failed to save preview for %s" % String(item_def.get("id", "")))
	else:
		push_warning("Failed to capture preview for %s" % String(item_def.get("id", "")))

	preview.queue_free()
	await process_frame

func _create_item_instance(item_def: Dictionary):
	if PlacementInventoryCatalog.uses_imported_scene_factory(item_def):
		return PlacementInventoryCatalog.create_imported_scene_instance(item_def)

	var script_ref := PlacementInventoryCatalog.get_item_script(item_def)
	if script_ref == null:
		return null
	return script_ref.new()
