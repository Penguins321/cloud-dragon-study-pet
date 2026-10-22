extends RefCounted

var path: String

func _init(file_path: String = "user://plan.json") -> void:
	path = file_path

func load_plan() -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var value: Variant = _read(candidate)
		if preload("res://study/study_plan.gd").validate(value):
			return {"error": OK, "plan": value, "recovered": candidate != path}
	var missing := not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak")
	return {"error": ERR_FILE_NOT_FOUND if missing else ERR_FILE_CORRUPT, "plan": null, "recovered": false}

func save_plan(plan: Dictionary) -> Error:
	if not preload("res://study/study_plan.gd").validate(plan):
		return ERR_INVALID_DATA
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(plan, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Never replace a valid backup with a corrupt primary recovered on startup.
	if preload("res://study/study_plan.gd").validate(_read(path)):
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)

func _read(candidate: String) -> Variant:
	if not FileAccess.file_exists(candidate):
		return null
	var file := FileAccess.open(candidate, FileAccess.READ)
	if file == null or file.get_length() > 2_000_000:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data
