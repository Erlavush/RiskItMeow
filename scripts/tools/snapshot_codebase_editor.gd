@tool
extends EditorScript

## This wrapper allows you to right-click this file in the Godot FileSystem dock 
## and select "Run" to generate a fresh codebase snapshot without leaving the editor.
## It uses the headless CLI execute to avoid interfering with the editor's main loop.

func _run() -> void:
	print("--- Starting Codebase Snapshot via CLI ---")
	
	# Try to find the console executable in the project root
	var executable := ProjectSettings.globalize_path("res://Godot_v4.6.1-stable_win64_console.exe")
	var project_path := ProjectSettings.globalize_path("res://")
	var script_path := "scripts/tools/snapshot_codebase.gd"
	
	# Fallback check
	if not FileAccess.file_exists(executable):
		push_warning("Console executable not found at %s. Trying GUI executable..." % executable)
		executable = ProjectSettings.globalize_path("res://Godot_v4.6.1-stable_win64.exe")
	
	if not FileAccess.file_exists(executable):
		push_error("Godot executable not found in project root. Check LOCAL_TOOLING.md.")
		return

	var output = []
	var args := [
		"--path", project_path,
		"-s", script_path,
		"--headless"
	]
	
	var exit_code = OS.execute(executable, args, output, true)
	
	if exit_code == 0:
		print("Snapshot complete! Saved to codebase_snapshot.txt")
		# Print the last few lines of output which usually contains the success message
		if output.size() > 0:
			print(output[0])
	else:
		push_error("Snapshot failed with exit code %d" % exit_code)
		if output.size() > 0:
			for line in output[0].split("\n"):
				print(line)
