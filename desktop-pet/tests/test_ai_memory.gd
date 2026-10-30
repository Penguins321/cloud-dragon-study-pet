extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_standalone")

func _standalone() -> void:
	await run(self, func(ok: bool, message: String):
		if not ok:
			failures += 1
			printerr("FAIL: ", message))
	print("AI MEMORY failures: ", failures)
	quit(0 if failures == 0 else 1)

static func run(_tree: SceneTree, check: Callable) -> void:
	var store = load("res://ai/memory_store.gd")
	check.call(store != null and store.can_instantiate(), "memory store implementation exists and parses")
	if store == null or not store.can_instantiate():
		return
	var path := ProjectSettings.globalize_path("res://../.tools/ai-memory-tests/%s/ai_memory.json" % Time.get_ticks_usec())
	var data: Dictionary = store.defaults()
	check.call(store.load_data(path) == {"error":OK,"data":data}, "missing memory starts empty")
	var original := data.duplicate(true)
	data = store.append_exchange(data, "corgi", "你好", "你好呀", ["我喜欢安静", "我喜欢安静"] as Array[String])
	check.call(original == store.defaults(), "append never mutates caller data")
	check.call(data.preferences == ["我喜欢安静"], "explicit preferences are deduplicated")
	check.call(store.recent_messages(data, "corgi") == [{"role":"user","content":"你好"},{"role":"assistant","content":"你好呀"}], "exchange stores only user and assistant content")
	check.call(store.recent_messages(data, "duck").is_empty(), "companion histories stay independent")
	check.call(store.save_data(path, data) == OK, "private memory saves atomically")
	var restarted: Dictionary = store.load_data(path)
	check.call(restarted.error == OK and restarted.data == data, "restart restores memory")
	check.call(not FileAccess.file_exists(path + ".tmp") and not FileAccess.file_exists(path + ".bak"), "save leaves no temporary file or backup")
	for index in range(25):
		data = store.append_exchange(data, "corgi", "用户%d" % index, "伙伴%d" % index, [] as Array[String])
	check.call(data.histories.corgi.size() == 40 and data.histories.corgi[0].content == "用户5", "history trims oldest complete pairs to forty messages")
	var recent: Array = store.recent_messages(data, "corgi")
	check.call(recent.size() == 12 and recent[0].content == "用户19", "request context is last twelve messages")
	recent[0].content = "修改副本"
	check.call(data.histories.corgi[28].content == "用户19", "recent context cannot mutate persisted history")
	data = store.append_exchange(data, "duck", "嘎", "嘎嘎", [] as Array[String])
	data = store.clear_history(data, "corgi")
	check.call(store.recent_messages(data, "corgi").is_empty() and store.recent_messages(data, "duck").size() == 2, "clear affects selected companion only")
	var values: Array[String] = []
	for index in range(25): values.append("偏好%d" % index)
	values.append("很".repeat(200))
	data = store.set_preferences(data, values)
	check.call(data.preferences.size() == 20, "preference count is bounded")
	for value in data.preferences: check.call(value.length() <= 160, "each preference is bounded")
	data = store.set_preferences(data, [] as Array[String])
	check.call(data.preferences.is_empty(), "explicit edit can delete all preferences")
	var roles := ["warm_jade", "corgi", "duck", "jellyfish"]
	var personas: Array[String] = []
	for role in roles:
		var persona: String = store.default_persona(role)
		check.call(not persona.is_empty() and persona == store.default_persona(role), "default persona is stable for " + role)
		personas.append(persona)
	check.call(personas[0] != personas[1] and personas[1] != personas[2] and personas[2] != personas[3], "four companions have distinct personalities")
	data = store.set_persona(data, "corgi", "保持好奇".repeat(200))
	check.call(data.personas.corgi.length() == 600, "persona override is capped")
	check.call(store.save_data(path, data) == OK and store.load_data(path).data.personas == data.personas, "persona override survives restart")
	data = store.set_persona(data, "corgi", " ")
	check.call(not data.personas.has("corgi"), "empty persona restores the built-in personality")
	check.call(store.append_exchange(data, "unknown", "x", "y", [] as Array[String]) == data, "unknown companion cannot create history")
	data = store.append_exchange(data, "duck", "长".repeat(1200), "答".repeat(1200), [] as Array[String])
	check.call(data.histories.duck[-1].content.length() == 1000 and data.histories.duck[-2].content.length() == 1000, "message content is capped")
	check.call(data.preferences.is_empty(), "chat text never becomes a preference without an explicit memory")
	var malformed := data.duplicate(true)
	malformed.histories.duck[0].role = "system"
	var before := FileAccess.get_file_as_string(path)
	check.call(store.save_data(path, malformed) == ERR_INVALID_PARAMETER, "malformed role cannot be saved")
	check.call(FileAccess.get_file_as_string(path) == before, "rejected save preserves original private file")
	var extra := data.duplicate(true)
	extra.unexpected = "unrecognized data"
	check.call(store.save_data(path, extra) == ERR_INVALID_PARAMETER, "private schema rejects extra fields")
	if OS.has_feature("linux") or OS.has_feature("macos") or OS.has_feature("bsd"):
		check.call(FileAccess.get_unix_permissions(path) == (FileAccess.UNIX_READ_OWNER | FileAccess.UNIX_WRITE_OWNER), "private memory is owner readable and writable only")
	var bad_records := ["not JSON", '{"preferences":[],"personas":{},"histories":{"unknown":[]}}', '{"preferences":[1],"personas":{},"histories":{}}', JSON.stringify(malformed), "x".repeat(512 * 1024 + 1)]
	for contents in bad_records:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(contents)
		file.close()
		var result: Dictionary = store.load_data(path)
		check.call(result.error == ERR_FILE_CORRUPT and result.data == store.defaults(), "corrupt or oversized memory safely returns empty defaults")
		check.call(FileAccess.get_file_as_string(path) == contents, "corrupt memory is preserved without rewrite")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_base_dir())
