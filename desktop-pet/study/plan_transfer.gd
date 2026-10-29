extends RefCounted

const Plan = preload("res://study/study_plan.gd")
const MAX_BYTES := 2_000_000

static func encode_template(plan: Dictionary) -> Dictionary:
	if not Plan.validate(plan) or not _fits(plan):
		return {}
	var titles: Array[String] = []
	for task in plan.tasks:
		titles.append(task.title)
	return {"format": "warmjade-plan", "version": 1, "goal": plan.goal, "tasks": titles}

static func encode_backup(plan: Dictionary) -> Dictionary:
	if not Plan.validate(plan) or not _fits(plan):
		return {}
	var payload := {"format": "warmjade-plan-backup", "version": 1, "plan": plan.duplicate(true)}
	return payload if _fits(payload) else {}

static func decode(value: Variant) -> Dictionary:
	if not value is Dictionary or not _fits(value):
		return _failure(ERR_INVALID_DATA)
	if not (value.get("version") is int or value.get("version") is float) or value.version != 1:
		return _failure(ERR_INVALID_DATA)
	if value.get("format") == "warmjade-plan":
		if not value.get("goal") is String or not value.get("tasks") is Array or value.tasks.size() > 500:
			return _failure(ERR_INVALID_DATA)
		var titles: Array[String] = []
		for title in value.tasks:
			if not title is String:
				return _failure(ERR_INVALID_DATA)
			titles.append(title)
		var model = Plan.new()
		if model.replace_content(value.goal, titles) != OK:
			return _failure(ERR_INVALID_DATA)
		return {"error": OK, "plan": model.to_dict(), "kind": "template"}
	if value.get("format") == "warmjade-plan-backup" and Plan.validate(value.get("plan")):
		return {"error": OK, "plan": value.plan.duplicate(true), "kind": "backup"}
	return _failure(ERR_INVALID_DATA)

static func read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(FileAccess.get_open_error())
	if file.get_length() > MAX_BYTES:
		file.close()
		return _failure(ERR_INVALID_DATA)
	var content := file.get_as_text()
	var error := file.get_error()
	file.close()
	if error != OK and error != ERR_FILE_EOF:
		return _failure(error)
	var parser := JSON.new()
	if parser.parse(content) != OK:
		return _failure(ERR_PARSE_ERROR)
	return decode(parser.data)

static func write_file(path: String, payload: Dictionary) -> Error:
	if decode(payload).error != OK:
		return ERR_INVALID_DATA
	var content := JSON.stringify(payload, "\t")
	if content.to_utf8_buffer().size() > MAX_BYTES:
		return ERR_INVALID_DATA
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
	return DirAccess.rename_absolute(temporary, path)

static func _fits(value: Dictionary) -> bool:
	return JSON.stringify(value).to_utf8_buffer().size() <= MAX_BYTES

static func _failure(error: Error) -> Dictionary:
	return {"error": error, "plan": null, "kind": ""}
