@tool
class_name ClassicWindowItem
extends "res://scripts/placement/window_item.gd"

const CLASSIC_SOURCE_SCENE_PATH := "res://assets/props/window/window.glb"

func get_display_name() -> String:
	return "Window (Classic)"

func get_source_scene_path() -> String:
	return CLASSIC_SOURCE_SCENE_PATH
