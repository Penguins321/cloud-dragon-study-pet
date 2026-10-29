extends RefCounted

const Plan = preload("res://study/study_plan.gd")
const MAX_BYTES := 2_000_000

var path: String

func _init(file_path: String = "user://plan.json") -> void:
	path = file_path

func load_plan() -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var value: Variant = _read(candidate)
		if Plan.validate(value):
			return {"error": OK, "plan": value, "recovered": candidate != path}
	var missing := not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak")
	return {"error": ERR_FILE_NOT_FOUND if missing else ERR_FILE_CORRUPT, "plan": null, "recovered": false}

func save_plan(plan: Dictionary) -> Error:
	if not Plan.validate(plan):
		return ERR_INVALID_DATA
	var content := JSON.stringify(plan, "\t")
	if content.to_utf8_buffer().size() > MAX_BYTES:
		return ERR_INVALID_DATA
	# Corrupt copies are recovery evidence; a normal save cannot erase them.
	if load_plan().error == ERR_FILE_CORRUPT:
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
	# Never replace a valid backup with a corrupt primary recovered on startup.
	if Plan.validate(_read(path)):
		error = DirAccess.copy_absolute(path, path + ".bak.tmp")
		if error != OK:
			return error
		error = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)

func preview_backup() -> Dictionary:
	var value: Variant = _read(path + ".bak")
	if Plan.validate(value):
		return {"error": OK, "plan": value, "recovered": true}
	return {"error": ERR_FILE_CORRUPT if FileAccess.file_exists(path + ".bak") else ERR_FILE_NOT_FOUND, "plan": null, "recovered": false}

func preview_checkpoint() -> Dictionary:
	var checkpoint := path + ".before-import"
	var value: Variant = _read(checkpoint)
	if Plan.validate(value):
		return {"error": OK, "plan": value, "recovered": true}
	return {"error": ERR_FILE_CORRUPT if FileAccess.file_exists(checkpoint) else ERR_FILE_NOT_FOUND, "plan": null, "recovered": false}

func import_plan(candidate: Dictionary, current: Dictionary) -> Error:
	if not Plan.validate(candidate) or not Plan.validate(current):
		return ERR_INVALID_DATA
	var content := JSON.stringify(current, "\t")
	if content.to_utf8_buffer().size() > MAX_BYTES or JSON.stringify(candidate, "\t").to_utf8_buffer().size() > MAX_BYTES:
		return ERR_INVALID_DATA
	var checkpoint := path + ".before-import"
	var file := FileAccess.open(checkpoint + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	error = DirAccess.rename_absolute(checkpoint + ".tmp", checkpoint)
	if error != OK:
		return error
	return save_plan(candidate)

func _read(candidate: String) -> Variant:
	if not FileAccess.file_exists(candidate):
		return null
	var file := FileAccess.open(candidate, FileAccess.READ)
	if file == null:
		return null
	if file.get_length() > MAX_BYTES:
		file.close()
		return null
	var parser := JSON.new()
	var content := file.get_as_text()
	file.close()
	if parser.parse(content) != OK:
		return null
	return parser.data
