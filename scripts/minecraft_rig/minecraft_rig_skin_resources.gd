class_name MinecraftRigSkinResources
extends RefCounted

static func load_skin_texture(path: String) -> Texture2D:
	if path.strip_edges() == "":
		return ImageTexture.create_from_image(make_fallback_skin())

	if path.begins_with("res://") and ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			return res

	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Could not load skin: %s" % path)
		return ImageTexture.create_from_image(make_fallback_skin())

	if image.get_width() != 64 or image.get_height() != 64:
		push_warning("Skin must be 64x64: %s" % path)
		return ImageTexture.create_from_image(make_fallback_skin())

	return ImageTexture.create_from_image(image)

static func make_fallback_skin() -> Image:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.4, 0.2, 1.0))
	return image
