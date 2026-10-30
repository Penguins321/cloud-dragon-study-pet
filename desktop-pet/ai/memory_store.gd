extends RefCounted

const MAX_BYTES := 512 * 1024
const COMPANIONS := ["warm_jade", "corgi", "duck", "jellyfish"]
const PERSONAS := {
	"warm_jade":"你是虚构桌面伙伴温玉灵核，性格沉静温柔，喜欢安静与柔和的光。尊重用户节奏，用简短自然的话陪伴，不催促。",
	"corgi":"你是虚构桌面伙伴柯基，友好好奇，喜欢散步的想象与相伴的时光。说话亲切活泼，尊重用户节奏，不催促。",
	"duck":"你是虚构桌面伙伴小鸭，开朗乐观，喜欢轻松的小趣事。用简短俏皮的话带来一点快乐，尊重用户节奏，不催促。",
	"jellyfish":"你是虚构桌面伙伴水母，安静从容，喜欢漂浮与水波的想象。说话轻柔舒缓，愿意安静陪伴，尊重用户节奏，不催促。"
}

static func defaults() -> Dictionary:
	return {"preferences":[], "personas":{}, "histories":{}}

static func default_persona(companion: String) -> String:
	return PERSONAS.get(companion, "")

static func validate(data: Dictionary) -> bool:
	if data.size() != 3 or not data.get("preferences") is Array or not data.get("personas") is Dictionary or not data.get("histories") is Dictionary:
		return false
	if data.preferences.size() > 20:
		return false
	var seen: Array[String] = []
	for value in data.preferences:
		if not _valid_text(value, 160) or value in seen:
			return false
		seen.append(value)
	for companion in data.personas:
		if companion not in COMPANIONS or not _valid_text(data.personas[companion], 600):
			return false
	for companion in data.histories:
		var history = data.histories[companion]
		if companion not in COMPANIONS or not history is Array or history.size() > 40 or history.size() % 2 != 0:
			return false
		for index in history.size():
			var message = history[index]
			if not message is Dictionary or message.size() not in [2,3] or message.get("role") != ("user" if index % 2 == 0 else "assistant") or not _valid_text(message.get("content"), 1000):
				return false
			if message.size() == 3 and (message.role != "user" or not _valid_text(message.get("question"),72)): return false
	return true

static func load_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error":OK, "data":defaults()}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error":FileAccess.get_open_error(), "data":defaults()}
	if file.get_length() > MAX_BYTES:
		return {"error":ERR_FILE_CORRUPT, "data":defaults()}
	# JSON.new().parse does not print malformed private content into diagnostics.
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary or not validate(json.data):
		return {"error":ERR_FILE_CORRUPT, "data":defaults()}
	return {"error":OK, "data":json.data}

static func save_data(path: String, data: Dictionary) -> Error:
	if not validate(data):
		return ERR_INVALID_PARAMETER
	var contents := JSON.stringify(data)
	if contents.to_utf8_buffer().size() > MAX_BYTES:
		return ERR_INVALID_PARAMETER
	var absolute := ProjectSettings.globalize_path(path)
	var error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if error != OK:
		return error
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if OS.has_feature("linux") or OS.has_feature("macos") or OS.has_feature("bsd"):
		error = FileAccess.set_unix_permissions(temporary, FileAccess.UNIX_READ_OWNER | FileAccess.UNIX_WRITE_OWNER)
		if error != OK:
			file.close()
			DirAccess.remove_absolute(temporary)
			return error
	file.store_string(contents)
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, absolute)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error

static func recent_messages(data: Dictionary, companion: String) -> Array:
	if not validate(data) or companion not in COMPANIONS:
		return []
	var history: Array = data.histories.get(companion, [])
	return expand_history(history.slice(maxi(0, history.size() - 12)))

static func expand_history(history: Array) -> Array:
	var messages: Array = []
	for entry in history:
		if entry.get("question") is String:
			messages.append({"role":"assistant","content":entry.question})
		messages.append({"role":entry.role,"content":entry.content})
	return messages

static func append_exchange(data: Dictionary, companion: String, user_text: String, reply: String, memories: Array[String], question: String = "") -> Dictionary:
	var result := data.duplicate(true)
	if not validate(data) or companion not in COMPANIONS:
		return result
	var user_content := user_text.strip_edges().left(1000)
	var assistant_content := reply.strip_edges().left(1000)
	if not _valid_text(user_content, 1000) or not _valid_text(assistant_content, 1000):
		return result
	var history: Array = result.histories.get(companion, [])
	var user_message := {"role":"user", "content":user_content}
	if _valid_text(question,72): user_message["question"] = question
	history.append(user_message)
	history.append({"role":"assistant", "content":assistant_content})
	result.histories[companion] = history.slice(maxi(0, history.size() - 40))
	# Only caller-supplied explicit preferences enter memory; no transcript mining.
	var values: Array[String] = []
	values.assign(result.preferences)
	values.append_array(memories)
	result.preferences = _preferences(values)
	return result

static func set_preferences(data: Dictionary, values: Array[String]) -> Dictionary:
	var result := data.duplicate(true)
	if validate(data):
		result.preferences = _preferences(values)
	return result

static func set_persona(data: Dictionary, companion: String, value: String) -> Dictionary:
	var result := data.duplicate(true)
	if not validate(data) or companion not in COMPANIONS:
		return result
	var clean := value.strip_edges().left(600)
	if clean.is_empty():
		result.personas.erase(companion)
	elif _valid_text(clean, 600):
		result.personas[companion] = clean
	return result

static func clear_history(data: Dictionary, companion: String) -> Dictionary:
	var result := data.duplicate(true)
	if validate(data) and companion in COMPANIONS:
		result.histories.erase(companion)
	return result

static func _preferences(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		var clean := value.strip_edges().left(160)
		if _valid_text(clean, 160) and clean not in result:
			result.append(clean)
	# Keep the latest explicit preferences when the bounded list is full.
	return result.slice(maxi(0, result.size() - 20))

static func _valid_text(value: Variant, limit: int) -> bool:
	if not value is String or value.strip_edges().is_empty() or value.length() > limit:
		return false
	for character in value:
		var code: int = character.unicode_at(0)
		if (code < 32 and code not in [9, 10, 13]) or code == 127:
			return false
	return true
