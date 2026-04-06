@tool
class_name PlacementPreviewCache
extends RefCounted

const CACHE_ROOT := "res://assets/ui/item_previews"

static func should_use_cached_preview(item_def: Dictionary) -> bool:
	return true

static func get_preview_source_path(item_def: Dictionary) -> String:
	return String(item_def.get("source_scene_path", ""))

static func get_preview_image_path(item_def: Dictionary) -> String:
	var item_id := String(item_def.get("id", "item"))
	return "%s/%s.png" % [CACHE_ROOT, item_id]

static func has_cached_preview(item_def: Dictionary) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(get_preview_image_path(item_def)))

static func load_preview_texture(item_def: Dictionary) -> Texture2D:
	var preview_path := get_preview_image_path(item_def)
	if not FileAccess.file_exists(ProjectSettings.globalize_path(preview_path)):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(preview_path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

static func save_preview_texture(texture: Texture2D, preview_path: String) -> bool:
	if texture == null or preview_path.is_empty():
		return false
	var image := texture.get_image()
	if image == null:
		return false
	return save_preview_image(image, preview_path)

static func save_preview_image(image: Image, preview_path: String) -> bool:
	if image == null or preview_path.is_empty():
		return false
	var absolute_path := ProjectSettings.globalize_path(preview_path)
	var directory_path := absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory_path):
		var mkdir_error := DirAccess.make_dir_recursive_absolute(directory_path)
		if mkdir_error != OK:
			push_warning("Failed to create preview directory %s" % directory_path)
			return false
	var save_error := image.save_png(absolute_path)
	if save_error != OK:
		push_warning("Failed to save preview image at %s" % preview_path)
		return false
	return true
