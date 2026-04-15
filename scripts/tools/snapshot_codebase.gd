extends SceneTree
## Generates a single-file codebase snapshot for AI context.
## Run:  .\Godot_v4.6.1-stable_win64.exe --path . -s scripts/tools/snapshot_codebase.gd --headless

const OUTPUT_FILE := "res://codebase_snapshot.txt"
const PROJECT_FILE := "res://project.godot"

const ALLOWED_EXTENSIONS := [
	"godot",
	"tscn",
	"gd",
	"gdshader",
	"shader",
	"tres",
]
const EXCLUDED_DIR_NAMES := [
	".git",
	".godot",
	".godot_user",
	".import",
	".planning",
	"temporary",
	"assets",
	"data",
]

const EXCLUDED_PREFIXES := [
	"res://scripts/tools/",
]

const EXCLUDED_FILES := [
	"res://codebase_snapshot.txt",
	"res://scripts/dump_codebase.gd",
	"res://scripts/WorldGenerator.gd",
	"res://generate_scene.py",
]

func _init() -> void:
	var paths: Array[String] = []
	_collect_files("res://", paths)
	paths.sort_custom(_sort_files_for_flow)

	var out := FileAccess.open(OUTPUT_FILE, FileAccess.WRITE)
	if out == null:
		push_error("Failed to open output file: %s" % OUTPUT_FILE)
		quit(1)
		return

	_write_header(out, paths)
	_write_tree(out, paths)
	_write_file_manifest(out, paths)
	_write_file_contents(out, paths)
	out.close()

	print("Codebase snapshot saved → %s  (%d files)" % [OUTPUT_FILE, paths.size()])
	quit()

func _collect_files(path: String, results: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	var directories := dir.get_directories()
	directories.sort()
	for dir_name in directories:
		if _should_skip_dir(dir_name):
			continue
		_collect_files(path.path_join(dir_name), results)

	var files := dir.get_files()
	files.sort()
	for file_name in files:
		var full_path := path.path_join(file_name)
		if _should_include_file(full_path):
			results.append(full_path)

func _should_skip_dir(dir_name: String) -> bool:
	if dir_name.begins_with("."):
		return true
	return EXCLUDED_DIR_NAMES.has(dir_name)

func _should_include_file(path: String) -> bool:
	if EXCLUDED_FILES.has(path):
		return false

	for prefix in EXCLUDED_PREFIXES:
		if path.begins_with(prefix):
			return false

	var extension := path.get_extension().to_lower()
	if not ALLOWED_EXTENSIONS.has(extension):
		return false

	if path == PROJECT_FILE:
		return true
	if extension == "tscn" and path.begins_with("res://scenes/"):
		return true
	if extension == "gd" and path.begins_with("res://scripts/"):
		return true
	if (extension == "gdshader" or extension == "shader") and path.begins_with("res://shaders/"):
		return true
	if extension == "tres" and path.begins_with("res://resources/"):
		return true

	return false

func _sort_files_for_flow(a: String, b: String) -> bool:
	var priority_a := _get_flow_priority(a)
	var priority_b := _get_flow_priority(b)
	if priority_a != priority_b:
		return priority_a < priority_b
	return a.naturalnocasecmp_to(b) < 0

func _get_flow_priority(path: String) -> int:
	if path == PROJECT_FILE:
		return 0
	if path == "res://scenes/main.tscn":
		return 10
	if path.begins_with("res://scenes/"):
		return 20

	if path == "res://scripts/player.gd":
		return 30
	if path.begins_with("res://scripts/camera/"):
		return 40
	if path.begins_with("res://scripts/room/"):
		return 50
	if path.begins_with("res://scripts/placement/"):
		return 60
	if path.begins_with("res://scripts/world/"):
		return 70
	if path.begins_with("res://scripts/debug/"):
		return 80
	if path == "res://scripts/MinecraftRig.gd" or path == "res://scripts/skin_picker.gd" or path.begins_with("res://scripts/minecraft_rig/"):
		return 90
	if path.begins_with("res://scripts/"):
		return 95

	if path.begins_with("res://shaders/"):
		return 100

	return 200

func _write_header(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("RISK IT MEOW — CODEBASE SNAPSHOT\n")
	out.store_string("================================\n\n")
	out.store_string("Generated: %s\n" % Time.get_datetime_string_from_system())
	out.store_string("Output: %s\n" % OUTPUT_FILE)
	out.store_string("Included files: %d\n" % paths.size())
	out.store_string("Scope: project config + gameplay scenes + runtime scripts + shaders.\n")
	out.store_string("Note: Large ArrayMesh/PackedArray blobs in scene files are collapsed for readability.\n\n")

func _write_tree(out: FileAccess, paths: Array[String]) -> void:
	var tree := _build_tree(paths)
	out.store_string("[TREE]\n")
	out.store_string("res://\n")
	_write_tree_node(out, tree, "")
	out.store_string("\n")

func _build_tree(paths: Array[String]) -> Dictionary:
	var tree: Dictionary = {}
	for path in paths:
		var relative_path := path.trim_prefix("res://")
		if relative_path.is_empty():
			continue
		var parts: PackedStringArray = relative_path.split("/", false)
		_insert_tree_path(tree, parts, 0)
	return tree

func _insert_tree_path(node: Dictionary, parts: PackedStringArray, index: int) -> void:
	if index >= parts.size():
		return

	var part := String(parts[index])
	var child: Dictionary = node.get(part, {}) as Dictionary
	_insert_tree_path(child, parts, index + 1)
	node[part] = child

func _write_tree_node(out: FileAccess, node: Dictionary, prefix: String) -> void:
	var names: Array[String] = []
	for key in node.keys():
		names.append(String(key))
	names.sort()

	for i in range(names.size()):
		var name := names[i]
		var child := node.get(name, {}) as Dictionary
		var is_last := i == names.size() - 1
		var branch := "\\-- " if is_last else "|-- "
		out.store_string("%s%s%s\n" % [prefix, branch, name])
		var next_prefix := prefix + ("    " if is_last else "|   ")
		_write_tree_node(out, child, next_prefix)

func _write_file_manifest(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("[FILES]\n")
	for i in range(paths.size()):
		out.store_string("%d. %s\n" % [i + 1, paths[i]])
	out.store_string("\n")

func _write_file_contents(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("[FILE_CONTENTS]\n\n")

	for path in paths:
		var content := _read_text(path)
		content = _sanitize_content(path, content)
		var numbered_content := _with_line_numbers(content)

		out.store_string("=== FILE: %s ===\n" % path)
		out.store_string(numbered_content)
		if not numbered_content.ends_with("\n"):
			out.store_string("\n")
		out.store_string("=== END FILE ===\n\n")

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _with_line_numbers(content: String) -> String:
	var lines: PackedStringArray = content.split("\n", true)
	if lines.is_empty():
		return "1: \n"

	var width := str(lines.size()).length()
	var numbered_lines: Array[String] = []
	for index in range(lines.size()):
		numbered_lines.append("%s: %s" % [str(index + 1).pad_zeros(width), String(lines[index])])
	return "\n".join(numbered_lines)

func _sanitize_content(path: String, content: String) -> String:
	var extension := path.get_extension().to_lower()
	if extension == "tscn":
		content = _strip_arraymesh_subresources(content)
		content = _strip_large_packed_arrays(content)
	return content

func _strip_large_packed_arrays(content: String) -> String:
	var regex := RegEx.new()
	var err := regex.compile('Packed[A-Za-z0-9_]+Array\\(".*?"\\)')
	if err == OK:
		content = regex.sub(content, 'PackedByteArray("<binary_data_omitted>")', true)
	return content

func _strip_arraymesh_subresources(content: String) -> String:
	var lines := content.split("\n")
	var result: Array[String] = []
	var index := 0

	while index < lines.size():
		var line := String(lines[index])
		if line.begins_with('[sub_resource type="ArrayMesh"'):
			var resource_id := _extract_attr(line, "id")
			if resource_id.is_empty():
				resource_id = "<unknown_mesh>"

			result.append('[sub_resource type="ArrayMesh" id="%s"]' % resource_id)
			result.append("; <ArrayMesh vertex buffer omitted>")
			result.append("")

			index += 1
			while index < lines.size():
				var next_line := String(lines[index])
				if next_line.begins_with("[sub_resource ") \
				or next_line.begins_with("[node ") \
				or next_line.begins_with("[ext_resource ") \
				or next_line.begins_with("[connection ") \
				or next_line.begins_with("[editable ") \
				or next_line.begins_with("[gd_scene"):
					break
				index += 1
			continue

		result.append(line)
		index += 1

	return "\n".join(result)

func _extract_attr(line: String, attribute_name: String) -> String:
	var token := attribute_name + "=\""
	var start := line.find(token)
	if start == -1:
		return ""
	start += token.length()
	var end := line.find("\"", start)
	if end == -1:
		return ""
	return line.substr(start, end - start)
