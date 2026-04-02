class_name PlacementTypes
extends RefCounted

const FAMILY_FLOOR := "floor"
const FAMILY_WALL := "wall"
const FAMILY_CEILING := "ceiling"
const FAMILY_SURFACE := "surface"

const SURFACE_FLOOR := "floor"
const SURFACE_CEILING := "ceiling"
const SURFACE_SURFACE := "surface"
const SURFACE_WALL_BACK := "wall_back"
const SURFACE_WALL_LEFT := "wall_left"
const SURFACE_WALL_FRONT := "wall_front"
const SURFACE_WALL_RIGHT := "wall_right"

const WALL_SURFACES := [
	SURFACE_WALL_BACK,
	SURFACE_WALL_LEFT,
	SURFACE_WALL_FRONT,
	SURFACE_WALL_RIGHT,
]

const GRID_SIZE := 0.5
const SURFACE_DECOR_GRID := 0.25

static func is_wall_surface(surface: String) -> bool:
	return WALL_SURFACES.has(surface)

static func get_shortcut_label(index: int) -> String:
	return str(index + 1)
