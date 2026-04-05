class_name DeveloperEnvironmentPersistence
extends RefCounted

const SETTINGS_PATH := "user://developer_environment_settings.cfg"
const SETTINGS_SECTION := "developer_environment"

static func save_values(values: Dictionary, path: String = SETTINGS_PATH, section: String = SETTINGS_SECTION) -> int:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value(section, str(key), values[key])
	return config.save(path)

static func load_values(keys: Array, path: String = SETTINGS_PATH, section: String = SETTINGS_SECTION) -> Dictionary:
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		return {}

	var values := {}
	for key in keys:
		if config.has_section_key(section, str(key)):
			values[key] = config.get_value(section, str(key))
	return values

static func get_file_signature(path: String = SETTINGS_PATH) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()
