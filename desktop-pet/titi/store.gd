extends RefCounted

var path: String
var blocked := false
var message := ""
var data := {"version": 1, "tasks": [], "quiet": false, "size": 210, "large_font": false, "topmost": true, "position": [-1, -1]}

func _init() -> void:
	var directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	path = ("user://" if directory.is_empty() else directory).path_join("titi-v1.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())

func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1 or not value.get("tasks") is Array: return false
	if value.tasks.size() > 500: return false
	var ids := {}
	for task in value.tasks:
		if not task is Dictionary or not task.get("id") is String or ids.has(task.id): return false
		if not task.get("text") is String or task.text.strip_edges().is_empty() or task.text.length() > 200 or not task.get("done") is bool: return false
		ids[task.id] = true
	for key in ["quiet", "large_font", "topmost"]:
		if not value.get(key) is bool: return false
	if value.get("menu_style", "shadow") not in ["shadow", "translucent"]: return false
	var pet_size: Variant = value.get("size")
	if not (pet_size is int or pet_size is float): return false
	if pet_size != 170 and pet_size != 210 and pet_size != 250: return false
	var position: Variant = value.get("position")
	if not position is Array or position.size() != 2: return false
	for number in position:
		if not (number is float or number is int) or not is_finite(float(number)): return false
	return true

func read_data(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path): return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 2097152: return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK: return null
	var result: Variant = json.data
	return result if valid(result) else null

func load_data() -> void:
	var result: Variant = read_data(path)
	if result != null:
		data = result
	elif FileAccess.file_exists(path):
		result = read_data(path + ".bak")
		if result != null:
			data = result
			message = "已恢复上次备份。"
		else:
			blocked = true
			message = "数据无法读取，已保留原文件并暂停保存。"

func commit(candidate: Dictionary) -> Error:
	if blocked: return ERR_FILE_CORRUPT
	if not valid(candidate): return ERR_INVALID_DATA
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(candidate))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return error
	if read_data(path) != null:
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK: return error
	elif FileAccess.file_exists(path):
		error = DirAccess.copy_absolute(path, path + ".corrupt-" + str(Time.get_unix_time_from_system()))
		if error != OK: return error
	return DirAccess.rename_absolute(path + ".tmp", path)
