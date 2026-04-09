class_name WorldTimeController
extends Node

signal tick_advanced(game_time: int, day_time: int)
signal time_changed(game_time: int, day_time: int, partial_tick: float)

const GROUP_NAME := "world_time_controller"
const TICKS_PER_SECOND := 20.0
const TICKS_PER_DAY := 24000
const REAL_SECONDS_PER_DAY := 1200.0
const REAL_SECONDS_PER_TICK := REAL_SECONDS_PER_DAY / float(TICKS_PER_DAY)
const CLOCK_DISPLAY_OFFSET_TICKS := 6000

@export_range(0, TICKS_PER_DAY - 1, 1) var start_day_time := 6000
@export var daylight_cycle_enabled := true
@export_range(0.1, 64.0, 0.1) var time_scale := 1.0

var _game_time := 0
var _day_time := 0
var _tick_accumulator := 0.0
var _partial_tick := 0.0

func _ready() -> void:
	add_to_group(GROUP_NAME)
	_day_time = wrapi(start_day_time, 0, TICKS_PER_DAY)
	set_process(true)
	time_changed.emit(_game_time, _day_time, _partial_tick)

func _process(delta: float) -> void:
	var tick_duration := _get_tick_duration_seconds()
	if tick_duration <= 0.0:
		_partial_tick = 0.0
		return

	_tick_accumulator += delta
	var advanced_any_tick := false
	var safety_counter := 0
	while _tick_accumulator >= tick_duration and safety_counter < 1000:
		_tick_accumulator -= tick_duration
		_advance_one_tick()
		advanced_any_tick = true
		safety_counter += 1

	_partial_tick = clampf(_tick_accumulator / tick_duration, 0.0, 0.9999)
	if advanced_any_tick or delta > 0.0:
		time_changed.emit(_game_time, _day_time, _partial_tick)

func _advance_one_tick() -> void:
	_game_time += 1
	if daylight_cycle_enabled:
		_day_time = (_day_time + 1) % TICKS_PER_DAY
	tick_advanced.emit(_game_time, _day_time)

func _get_tick_duration_seconds() -> float:
	return REAL_SECONDS_PER_TICK / maxf(time_scale, 0.0001)

func get_game_time() -> int:
	return _game_time

func get_day_time() -> int:
	return _day_time

func get_partial_tick() -> float:
	return _partial_tick

func get_day_progress() -> float:
	return float(_day_time) / float(TICKS_PER_DAY)

func set_day_time(ticks: int) -> void:
	_day_time = wrapi(ticks, 0, TICKS_PER_DAY)
	time_changed.emit(_game_time, _day_time, _partial_tick)

func get_clock_display_day_time() -> int:
	return (_day_time + CLOCK_DISPLAY_OFFSET_TICKS) % TICKS_PER_DAY

func get_hour_hand_rotation_radians(partial_tick: float = -1.0) -> float:
	var render_partial_tick := _partial_tick if partial_tick < 0.0 else partial_tick
	return get_hour(get_clock_display_day_time(), render_partial_tick) * TAU / 12.0

func get_minute_hand_rotation_radians(partial_tick: float = -1.0) -> float:
	var render_partial_tick := _partial_tick if partial_tick < 0.0 else partial_tick
	return get_minute(get_clock_display_day_time(), render_partial_tick) * TAU

func get_pendulum_rotation_radians(speed: float = 1.0, maximum_angle_radians: float = 18.0 * PI / 180.0, partial_tick: float = -1.0) -> float:
	var render_partial_tick := _partial_tick if partial_tick < 0.0 else partial_tick
	return sin(get_second(_day_time % TICKS_PER_DAY, render_partial_tick) * speed * TAU) * maximum_angle_radians

static func get_hour(day_time: int, partial_tick: float) -> float:
	return lerpf(float(day_time - 1), float(day_time), partial_tick) / 1000.0

static func get_minute(day_time: int, partial_tick: float) -> float:
	var minute := day_time % 1000
	return lerpf(float(minute - 1), float(minute), partial_tick) / 1000.0

static func get_second(day_time: int, partial_tick: float) -> float:
	return lerpf(float(day_time - 1), float(day_time), partial_tick) / 20.0
