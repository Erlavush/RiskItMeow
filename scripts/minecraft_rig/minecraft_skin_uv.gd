class_name MinecraftSkinUv
extends RefCounted

static func head_uv(base_layer: bool) -> Dictionary:
	var ox := 0 if base_layer else 32
	return {
		"right": Rect2(ox + 0, 8, 8, 8),
		"front": Rect2(ox + 8, 8, 8, 8),
		"left": Rect2(ox + 16, 8, 8, 8),
		"back": Rect2(ox + 24, 8, 8, 8),
		"top": Rect2(ox + 8, 0, 8, 8),
		"bottom": Rect2(ox + 16, 0, 8, 8),
	}

static func body_uv(base_layer: bool) -> Dictionary:
	var oy := 16 if base_layer else 32
	return {
		"right": Rect2(16, oy + 4, 4, 12),
		"front": Rect2(20, oy + 4, 8, 12),
		"left": Rect2(28, oy + 4, 4, 12),
		"back": Rect2(32, oy + 4, 8, 12),
		"top": Rect2(20, oy + 0, 8, 4),
		"bottom": Rect2(28, oy + 0, 8, 4),
	}

static func right_leg_uv(base_layer: bool) -> Dictionary:
	var oy := 16 if base_layer else 32
	return {
		"right": Rect2(0, oy + 4, 4, 12),
		"front": Rect2(4, oy + 4, 4, 12),
		"left": Rect2(8, oy + 4, 4, 12),
		"back": Rect2(12, oy + 4, 4, 12),
		"top": Rect2(4, oy + 0, 4, 4),
		"bottom": Rect2(8, oy + 0, 4, 4),
	}

static func left_leg_uv(base_layer: bool) -> Dictionary:
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

static func right_arm_uv(base_layer: bool, slim: bool) -> Dictionary:
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

static func left_arm_uv(base_layer: bool, slim: bool) -> Dictionary:
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
