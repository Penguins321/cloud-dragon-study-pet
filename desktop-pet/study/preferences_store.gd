extends RefCounted

const MAX_BYTES := 2_000_000

static func load_config(path: String) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var config: ConfigFile = _read(candidate)
		if config != null:
			return {"error": OK, "config": config, "recovered": candidate != path}
	var missing := not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak")
	return {"error": ERR_FILE_NOT_FOUND if missing else ERR_FILE_CORRUPT, "config": ConfigFile.new(), "recovered": false}

static func save_config(path: String, config: ConfigFile) -> Error:
	if config == null:
		return ERR_INVALID_DATA
	var content := config.encode_to_text()
	if content.to_utf8_buffer().size() > MAX_BYTES:
		return ERR_INVALID_DATA
	var parsed := ConfigFile.new()
	if parsed.parse(content) != OK:
		return ERR_INVALID_DATA
	if load_config(path).error == ERR_FILE_CORRUPT:
		return ERR_FILE_CORRUPT
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Copy into a temporary backup so a failed copy cannot damage the old one.
	if _read(path) != null:
		error = DirAccess.copy_absolute(path, path + ".bak.tmp")
		if error != OK:
			return error
		error = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)

static func _read(path: String) -> ConfigFile:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	if file.get_length() > MAX_BYTES:
		file.close()
		return null
	var content := file.get_as_text()
	file.close()
	var config := ConfigFile.new()
	return config if config.parse(content) == OK else null
