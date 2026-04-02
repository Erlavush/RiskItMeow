class_name RoomConstants
extends RefCounted

const FLOOR_SURFACE := "floor"
const CEILING_SURFACE := "ceiling"
const SURFACE_DECOR := "surface"

const WALL_BACK := "wall_back"
const WALL_LEFT := "wall_left"
const WALL_FRONT := "wall_front"
const WALL_RIGHT := "wall_right"

const WALL_SURFACES := [
	WALL_BACK,
	WALL_LEFT,
	WALL_FRONT,
	WALL_RIGHT,
]

const DEFAULT_ROOM_HALF_EXTENTS := Vector2(5.0, 5.0)
const DEFAULT_WALL_HEIGHT := 3.4
const DEFAULT_FLOOR_THICKNESS := 0.45
const DEFAULT_WALL_THICKNESS := 0.24
const DEFAULT_CEILING_THICKNESS := 0.24
const DEFAULT_PLAYER_MARGIN := 0.4
const DEFAULT_GRID_SIZE := 1.0

static func is_wall_surface(surface: String) -> bool:
	return WALL_SURFACES.has(surface)

static func get_wall_rotation(surface: String) -> float:
	match surface:
		WALL_BACK:
			return 0.0
		WALL_FRONT:
			return PI
		WALL_LEFT:
			return -PI * 0.5
		WALL_RIGHT:
			return PI * 0.5
		_:
			return 0.0
