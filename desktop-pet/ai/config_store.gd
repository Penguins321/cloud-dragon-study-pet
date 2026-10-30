extends RefCounted

# Separate private file: never pass this dictionary to ordinary preferences/backups.
static func defaults() -> Dictionary:
	return {"enabled":false,"provider":"deepseek","model":"deepseek-flash","api_key":"","bubbles":true}

static func validate(config: Dictionary) -> bool:
	for key in defaults():
		if not config.has(key) or typeof(config[key]) != typeof(defaults()[key]):
			return false
	if config.provider not in ["deepseek","openai"]:
		return false
	if config.model.length() > 128 or config.api_key.length() > 512:
		return false
	for value in [config.model,config.api_key]:
		for index in value.length():
			if value.unicode_at(index) < 32 or value.unicode_at(index) == 127:
				return false
	return true

static func load_config(path: String) -> Dictionary:
	var fallback := defaults()
	if not FileAccess.file_exists(path):
		return {"error":OK,"config":fallback}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return {"error":FileAccess.get_open_error(),"config":fallback}
	if file.get_length() > 8192:
		return {"error":ERR_FILE_CORRUPT,"config":fallback}
	# JSON.parse_string/ConfigFile.load can produce diagnostics; parse silently.
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary or not validate(json.data):
		return {"error":ERR_FILE_CORRUPT,"config":fallback}
	var result := defaults()
	for key in result:
		result[key] = json.data[key]
	return {"error":OK,"config":result}

static func save_config(path: String, config: Dictionary) -> Error:
	if not validate(config):
		return ERR_INVALID_PARAMETER
	var safe := defaults()
	for key in safe:
		safe[key] = config[key]
	var absolute := ProjectSettings.globalize_path(path)
	var error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if error != OK:
		return error
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if OS.has_feature("linux") or OS.has_feature("macos") or OS.has_feature("bsd"):
		error = FileAccess.set_unix_permissions(temporary,FileAccess.UNIX_READ_OWNER | FileAccess.UNIX_WRITE_OWNER)
		if error != OK:
			file.close()
			DirAccess.remove_absolute(temporary)
			return error
	file.store_string(JSON.stringify(safe))
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary,absolute)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error
