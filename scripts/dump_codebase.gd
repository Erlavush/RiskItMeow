# res://scripts/dump_codebase.gd
@tool
extends EditorScript

const OUTPUT_FILE := "res://compiled_codebase.txt"

const ALLOWED_EXTENSIONS := [
	"gd",
	"tscn",
	"tres",
	"godot",
	"gdshader",
	"shader",
	"json",
	"cfg"
]

const EXCLUDED_DIR_NAMES := [
	".godot",
	".git",
	".vscode",
	".idea",
	".import",
	".mono",
	"build",
	"dist",
	"bin",
	"tmp"
]

const EXCLUDED_FILE_NAMES := [
	"compiled_codebase.txt",
	"minecraftsampleAI.txt"
]

const AI_INSTRUCTIONS := """
[AI_CONTEXT_INSTRUCTIONS]

You are reading a Godot project codebase export.
Your response will be passed to a smarter IDE coding AI that can directly edit files.

Your job is to produce precise, minimal, block-based edit instructions that are easy for an IDE AI to locate and apply even if line numbers have shifted.

PRIMARY GOAL
- Understand the current codebase first.
- Then produce specific edit operations using file paths and exact code blocks.
- Prefer minimal edits over full-file rewrites.
- Use semantic anchors and exact code matching, not line numbers.

GENERAL RULES
- Preserve Godot 4.x compatibility.
- Prefer minimal, safe, targeted edits.
- Preserve existing architecture unless a change is necessary.
- Avoid unnecessary renames or folder moves.
- Do not use markdown tables.
- Do not use placeholders like:
  - ...
  - // rest unchanged
  - same as before
  - omitted for brevity
- Do not refer to line numbers.
- Do not say "somewhere in this file" or other vague phrases.
- Every edit must target a specific file and specific code block.

WHEN THE REQUEST IS AMBIGUOUS
- Ask at most 3 short clarifying questions.
- If missing detail would likely break implementation, do not generate edit operations yet.

RESPONSE FORMAT
Output your answer using EXACTLY these sections in this order:

1. TASK_UNDERSTANDING
- 3 to 8 short bullets maximum.

2. CHANGE_SUMMARY
- Short bullets describing what will change.

3. RISKS_AND_ASSUMPTIONS
- Only real risks, constraints, or assumptions.

4. APPLY_ORDER
- Ordered list of edits/actions in safest order.

5. EDIT_OPERATIONS
Use one or more of the following operation formats.

A. REPLACE_BLOCK
Use when replacing an existing code block.

===REPLACE_BLOCK_START===
FILE: res://path/to/file.ext
FIND:
<exact existing code block from the codebase>
REPLACE_WITH:
<new full replacement code block>
===REPLACE_BLOCK_END===

B. INSERT_AFTER
Use when adding code after an existing anchor block.

===INSERT_AFTER_START===
FILE: res://path/to/file.ext
AFTER:
<exact existing code block from the codebase>
INSERT:
<new code block to insert after it>
===INSERT_AFTER_END===

C. INSERT_BEFORE
Use when adding code before an existing anchor block.

===INSERT_BEFORE_START===
FILE: res://path/to/file.ext
BEFORE:
<exact existing code block from the codebase>
INSERT:
<new code block to insert before it>
===INSERT_BEFORE_END===

D. DELETE_BLOCK
Use when removing an existing block.

===DELETE_BLOCK_START===
FILE: res://path/to/file.ext
DELETE:
<exact existing code block to remove>
===DELETE_BLOCK_END===

E. NEW_FILE
Use when creating a new file.

===NEW_FILE_START===
FILE: res://path/to/new_file.ext
CONTENT:
<complete file content>
===NEW_FILE_END===

F. DELETE_FILE
Use when removing a file.

===DELETE_FILE_START===
FILE: res://path/to/file.ext
===DELETE_FILE_END===

6. EDITOR_STEPS
Only include this for things that cannot be represented as text edits.
Examples:
- connecting signals in the editor
- creating nodes manually
- inspector property changes
- Input Map changes
- Project Settings changes

Use this exact format:

===EDITOR_STEPS_START===
1. Step one...
2. Step two...
===EDITOR_STEPS_END===

7. VALIDATION_CHECKLIST
- Short checklist describing how to verify the change in Godot.

EDITING RULES
- Prefer block-based edits over full-file rewrites.
- Only use NEW_FILE for actually new files.
- Only use full-file replacement when block edits would be too fragile or too large.
- FIND / BEFORE / AFTER / DELETE blocks must be copied exactly from the current codebase.
- The anchor block must be unique enough that an IDE AI can locate it safely.
- If a block may not be unique, include more surrounding code to disambiguate.
- REPLACE_WITH must contain the full final replacement for that block.
- INSERT blocks must be complete and valid code.
- Keep indentation correct.
- Keep answers copy-pasteable and deterministic.

[END_AI_CONTEXT_INSTRUCTIONS]
"""
func _run() -> void:
	var paths: Array[String] = []
	_collect_files("res://", paths)
	paths.sort()

	var out := FileAccess.open(OUTPUT_FILE, FileAccess.WRITE)
	if out == null:
		push_error("Failed to open output file: %s" % OUTPUT_FILE)
		return

	_write_header(out, paths)
	_write_project_hints(out)
	_write_manifest(out, paths)
	_write_script_summaries(out, paths)
	_write_scene_summaries(out, paths)
	_write_codebase(out, paths)

	out.close()
	print("=> Codebase successfully exported to: %s" % OUTPUT_FILE)

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
	return dir_name in EXCLUDED_DIR_NAMES

func _should_include_file(path: String) -> bool:
	var file_name := path.get_file()
	if file_name in EXCLUDED_FILE_NAMES:
		return false

	if path == OUTPUT_FILE:
		return false

	var this_script: Script = get_script() as Script
	if this_script != null:
		var script_path: String = this_script.resource_path
		if script_path != "" and path == script_path:
			return false

	var ext: String = path.get_extension().to_lower()
	return ext in ALLOWED_EXTENSIONS

func _write_header(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("GODOT CODEBASE EXPORT\n")
	out.store_string("====================\n\n")

	out.store_string("EXPORT_METADATA\n")
	out.store_string("---------------\n")
	out.store_string("Generated at: %s\n" % Time.get_datetime_string_from_system())
	out.store_string("Root path: res://\n")
	out.store_string("Output file: %s\n" % OUTPUT_FILE)
	out.store_string("Included file count: %d\n\n" % paths.size())

	out.store_string(AI_INSTRUCTIONS)
	out.store_string("\n\n")

func _write_project_hints(out: FileAccess) -> void:
	out.store_string("[PROJECT_HINTS]\n\n")

	var project_path := "res://project.godot"
	if not FileAccess.file_exists(project_path):
		out.store_string("- project.godot not found.\n\n")
		return

	var text := _read_text(project_path)
	if text == "":
		out.store_string("- project.godot could not be read.\n\n")
		return

	var main_scene := _extract_project_setting(text, "[application]", "run/main_scene")
	var config_name := _extract_project_setting(text, "[application]", "config/name")
	var autoloads := _extract_autoloads(text)

	if config_name != "":
		out.store_string("- Project name: %s\n" % config_name)
	if main_scene != "":
		out.store_string("- Main scene: %s\n" % main_scene)

	if autoloads.size() > 0:
		out.store_string("- Autoloads:\n")
		for item in autoloads:
			out.store_string("  - %s\n" % item)
	else:
		out.store_string("- Autoloads: none found\n")

	out.store_string("\n")

func _write_manifest(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("[FILE_MANIFEST]\n\n")

	var counts := {}
	for path in paths:
		var ext := path.get_extension().to_lower()
		counts[ext] = int(counts.get(ext, 0)) + 1

	out.store_string("Counts by extension:\n")
	var keys := counts.keys()
	keys.sort()
	for key in keys:
		out.store_string("- .%s: %d\n" % [key, counts[key]])

	out.store_string("\nFiles:\n")
	for path in paths:
		var length := _get_file_length(path)
		out.store_string("- %s | %d bytes\n" % [path, length])

	out.store_string("\n")

func _write_script_summaries(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("[SCRIPT_SUMMARIES]\n\n")

	var had_any := false

	for path in paths:
		if path.get_extension().to_lower() != "gd":
			continue

		had_any = true
		var text := _read_text(path)
		var summary := _summarize_script(text)

		out.store_string("===SCRIPT: %s===\n" % path)
		if summary["extends"] != "":
			out.store_string("- extends: %s\n" % summary["extends"])
		if summary["class_name"] != "":
			out.store_string("- class_name: %s\n" % summary["class_name"])
		out.store_string("- tool: %s\n" % ("yes" if summary["tool"] else "no"))

		if summary["signals"].size() > 0:
			out.store_string("- signals: %s\n" % ", ".join(summary["signals"]))

		if summary["exports"].size() > 0:
			out.store_string("- exports: %s\n" % ", ".join(summary["exports"]))

		if summary["functions"].size() > 0:
			out.store_string("- functions: %s\n" % ", ".join(summary["functions"]))

		if summary["dependencies"].size() > 0:
			out.store_string("- path_refs: %s\n" % ", ".join(summary["dependencies"]))

		out.store_string("\n")

	if not had_any:
		out.store_string("- No script files found.\n\n")

func _write_scene_summaries(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("[SCENE_SUMMARIES]\n\n")

	var had_any := false

	for path in paths:
		if path.get_extension().to_lower() != "tscn":
			continue

		had_any = true
		var text := _read_text(path)
		var summary := _summarize_scene(text)

		out.store_string("===SCENE: %s===\n" % path)
		out.store_string("- node_count: %d\n" % summary["node_count"])

		if summary["root_name"] != "":
			out.store_string("- root_name: %s\n" % summary["root_name"])
		if summary["root_type"] != "":
			out.store_string("- root_type: %s\n" % summary["root_type"])

		if summary["script_refs"].size() > 0:
			out.store_string("- script_refs: %s\n" % ", ".join(summary["script_refs"]))

		if summary["nodes"].size() > 0:
			out.store_string("- node_tree:\n")
			for line in summary["nodes"]:
				out.store_string("  %s\n" % line)

		out.store_string("\n")

	if not had_any:
		out.store_string("- No scene files found.\n\n")

func _write_codebase(out: FileAccess, paths: Array[String]) -> void:
	out.store_string("[BEGIN_CODEBASE]\n\n")

	for path in paths:
		var content := _read_text(path)

		if path.ends_with(".tscn"):
			content = _strip_large_packed_arrays(content)
			content = _strip_arraymesh_subresources(content)
		elif path.ends_with(".tres"):
			content = _strip_large_packed_arrays(content)

		out.store_string("===FILE: %s===\n" % path)
		out.store_string(content)
		if not content.ends_with("\n"):
			out.store_string("\n")
		out.store_string("===END_FILE===\n\n")

	out.store_string("[END_CODEBASE]\n")

func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()

func _get_file_length(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return -1
	return int(f.get_length())

func _extract_project_setting(text: String, section_name: String, key_name: String) -> String:
	var lines := text.split("\n")
	var in_section := false

	for raw_line in lines:
		var line := raw_line.strip_edges()

		if line.begins_with("[") and line.ends_with("]"):
			in_section = line == section_name
			continue

		if not in_section:
			continue

		if line.begins_with(key_name + "="):
			var value := line.substr((key_name + "=").length())
			return value.strip_edges().trim_prefix("\"").trim_suffix("\"")

	return ""

func _extract_autoloads(text: String) -> Array[String]:
	var result: Array[String] = []
	var lines := text.split("\n")
	var in_section := false

	for raw_line in lines:
		var line := raw_line.strip_edges()

		if line.begins_with("[") and line.ends_with("]"):
			in_section = line == "[autoload]"
			continue

		if not in_section:
			continue

		if line == "" or line.begins_with(";"):
			continue

		var eq := line.find("=")
		if eq == -1:
			continue

		var left := line.substr(0, eq).strip_edges()
		var right := line.substr(eq + 1).strip_edges()
		result.append("%s => %s" % [left, right])

	return result

func _summarize_script(text: String) -> Dictionary:
	var result := {
		"extends": "",
		"class_name": "",
		"tool": false,
		"signals": [],
		"exports": [],
		"functions": [],
		"dependencies": []
	}

	var dependencies := {}
	var lines := text.split("\n")

	for raw_line in lines:
		var line := raw_line.strip_edges()

		if line == "@tool":
			result["tool"] = true

		if line.begins_with("extends "):
			result["extends"] = line.substr("extends ".length()).strip_edges()

		elif line.begins_with("class_name "):
			result["class_name"] = line.substr("class_name ".length()).strip_edges()

		elif line.begins_with("signal "):
			var signal_name := line.substr("signal ".length()).strip_edges()
			result["signals"].append(signal_name)

		elif line.begins_with("@export"):
			result["exports"].append(line)

		elif line.begins_with("func "):
			var fn := line.substr("func ".length())
			var paren := fn.find("(")
			if paren != -1:
				fn = fn.substr(0, paren)
			result["functions"].append(fn.strip_edges())

		var refs := _extract_res_paths_from_line(line)
		for ref in refs:
			dependencies[ref] = true

	result["signals"] = _limit_array(result["signals"], 20)
	result["exports"] = _limit_array(result["exports"], 20)
	result["functions"] = _limit_array(result["functions"], 60)

	var dep_list: Array[String] = []
	for key in dependencies.keys():
		dep_list.append(str(key))
	dep_list.sort()
	result["dependencies"] = _limit_array(dep_list, 40)

	return result

func _summarize_scene(text: String) -> Dictionary:
	var result := {
		"node_count": 0,
		"root_name": "",
		"root_type": "",
		"script_refs": [],
		"nodes": []
	}

	var ext_script_map := {}
	var script_refs := {}
	var nodes: Array[String] = []

	var lines := text.split("\n")
	var current_node_name := ""
	var current_node_type := ""
	var current_node_parent := ""

	for raw_line in lines:
		var line := raw_line.strip_edges()

		if line.begins_with("[ext_resource "):
			var ext_type := _extract_attr(line, "type")
			var ext_path := _extract_attr(line, "path")
			var ext_id := _extract_attr(line, "id")
			if ext_type == "Script" and ext_id != "" and ext_path != "":
				ext_script_map[ext_id] = ext_path

		elif line.begins_with("[node "):
			current_node_name = _extract_attr(line, "name")
			current_node_type = _extract_attr(line, "type")
			current_node_parent = _extract_attr(line, "parent")

			result["node_count"] += 1

			if result["root_name"] == "":
				result["root_name"] = current_node_name
				result["root_type"] = current_node_type

			var depth := 0
			if current_node_parent != "":
				depth = current_node_parent.split("/").size()

			var indent := ""
			for i in range(depth):
				indent += "  "

			var node_line := "%s- %s (%s)" % [indent, current_node_name, current_node_type]
			nodes.append(node_line)

		elif line.begins_with("script = ExtResource("):
			var id := _extract_extresource_id(line)
			if id != "" and ext_script_map.has(id):
				script_refs[ext_script_map[id]] = true

	var script_list: Array[String] = []
	for key in script_refs.keys():
		script_list.append(str(key))
	script_list.sort()

	result["script_refs"] = _limit_array(script_list, 30)
	result["nodes"] = _limit_array(nodes, 80)

	return result

func _extract_attr(line: String, attr_name: String) -> String:
	var token := attr_name + "=\""
	var start := line.find(token)
	if start == -1:
		return ""
	start += token.length()
	var end := line.find("\"", start)
	if end == -1:
		return ""
	return line.substr(start, end - start)

func _extract_extresource_id(line: String) -> String:
	var token := "ExtResource(\""
	var start := line.find(token)
	if start == -1:
		return ""
	start += token.length()
	var end := line.find("\")", start)
	if end == -1:
		return ""
	return line.substr(start, end - start)

func _extract_res_paths_from_line(line: String) -> Array[String]:
	var results: Array[String] = []
	var start := 0

	while true:
		var idx := line.find("res://", start)
		if idx == -1:
			break

		var end := idx
		while end < line.length():
			var ch := line[end]
			if ch == "\"" or ch == "'" or ch == ")" or ch == "]" or ch == " " or ch == ",":
				break
			end += 1

		var path := line.substr(idx, end - idx)
		if path != "" and not path in results:
			results.append(path)

		start = end + 1

	return results

func _limit_array(arr: Array, max_items: int) -> Array:
	if arr.size() <= max_items:
		return arr

	var limited := []
	for i in range(max_items):
		limited.append(arr[i])
	limited.append("...(+%d more)" % (arr.size() - max_items))
	return limited

func _strip_large_packed_arrays(content: String) -> String:
	var regex := RegEx.new()
	var err := regex.compile('Packed[A-Za-z0-9_]+Array\\(".*?"\\)')
	if err == OK:
		content = regex.sub(content, 'PackedByteArray("<binary_data_omitted>")', true)
	return content

func _strip_arraymesh_subresources(content: String) -> String:
	var lines := content.split("\n")
	var result: Array[String] = []

	var i := 0
	while i < lines.size():
		var line := lines[i]

		if line.begins_with('[sub_resource type="ArrayMesh"'):
			var id := _extract_attr(line, "id")
			if id == "":
				id = "<unknown_mesh>"

			result.append('[sub_resource type="ArrayMesh" id="%s"]' % id)
			result.append("; <procedural ArrayMesh data omitted from export for AI context>")
			result.append("")

			i += 1
			while i < lines.size():
				var next_line := lines[i]
				if next_line.begins_with("[sub_resource ") \
				or next_line.begins_with("[node ") \
				or next_line.begins_with("[ext_resource ") \
				or next_line.begins_with("[connection ") \
				or next_line.begins_with("[editable ") \
				or next_line.begins_with("[gd_scene"):
					break
				i += 1

			continue

		result.append(line)
		i += 1

	return "\n".join(result)
