extends SceneTree

# Opt in explicitly. Never consume the user's saved conversation or print secrets.
var brain: Node
var result: Dictionary = {}
var failure := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var config_path := OS.get_environment("AI_LIVE_CONFIG")
	var data_dir := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	if config_path.is_empty() or data_dir.is_empty():
		printerr("Set AI_LIVE_CONFIG and isolated CLOUD_DRAGON_DATA_DIR to opt in.")
		quit(1)
		return
	var loaded: Dictionary = load("res://ai/config_store.gd").load_config(config_path)
	if loaded.error != OK or loaded.config.provider != "deepseek":
		printerr("A valid private DeepSeek config is required.")
		quit(1)
		return
	brain = load("res://ai/companion_brain.gd").new()
	root.add_child(brain)
	var catalog = load("res://ai/model_catalog.gd").new()
	root.add_child(catalog)
	catalog.models_ready.connect(func(models): result = {"models":models})
	catalog.failed.connect(func(message): failure = message)
	if catalog.request_models("deepseek",loaded.config.api_key) != OK:
		printerr("LIVE discovery could not start.")
		quit(1)
		return
	while catalog.busy: await process_frame
	if not failure.is_empty() or not result.get("models",[]).has(loaded.config.model):
		printerr("LIVE selected model not available in official catalog.")
		quit(1)
		return
	print("LIVE official model discovery: OK; models=",JSON.stringify(result.models))
	catalog.free()
	result = {}
	brain.configure(loaded.config)
	brain.failed.connect(func(message): failure = message)
	brain.decision_ready.connect(func(value): result = value)
	brain.chat_ready.connect(func(reply, memories): result = {"reply":reply,"memories":memories})
	var actions: Array[StringName] = [&"idle", &"look", &"greet"]
	var started := Time.get_ticks_msec()
	var request: int = brain.request_decision({"companion":"warm_jade","event":"idle","mind":{"energy":0.8,"curiosity":0.9,"social_need":0.2,"intention":"想探索一下","recent_actions":[],"remaining_plan":[]}},actions,true)
	await wait_result(request)
	if not failure.is_empty(): return
	print("LIVE decision: OK; action=",result.action,"; elapsed_ms=",Time.get_ticks_msec()-started)
	if result.get("plan",[]).is_empty() or str(result.get("intent","")).is_empty():
		printerr("LIVE autonomous episode did not include intention and follow-up plan.")
		quit(1)
		return
	print("LIVE autonomous episode: OK; follow-ups=",result.plan.size())
	result = {}
	var messages: Array = [{"role":"user","content":"我喜欢简短的回复。请记住这个偏好，也请问我一个问题来了解我的兴趣。"}]
	var preferences: Array[String] = []
	var persona := "温柔、沉静的温玉灵核伙伴，简短自然地聊天。"
	started = Time.get_ticks_msec()
	request = brain.request_chat(messages,preferences,persona,"warm_jade")
	await wait_result(request)
	if not failure.is_empty(): return
	print("LIVE chat: OK; reply_chars=",result.reply.length(),"; memories=",result.memories.size(),"; elapsed_ms=",Time.get_ticks_msec()-started)
	if "？" not in result.reply and "?" not in result.reply:
		printerr("LIVE companion did not ask the requested question.")
		quit(1)
		return
	print("LIVE getting-to-know-you question: OK")
	if result.memories.is_empty():
		printerr("LIVE explicit preference was not extracted.")
		quit(1)
		return
	var store = load("res://ai/memory_store.gd")
	var data: Dictionary = store.append_exchange(store.defaults(),"warm_jade",messages[0].content,result.reply,result.memories)
	var memory_path := data_dir.path_join("ai_memory.json")
	if store.save_data(memory_path,data) != OK:
		printerr("LIVE synthetic memory save failed.")
		quit(1)
		return
	data = store.load_data(memory_path).data
	messages = store.recent_messages(data,"warm_jade")
	preferences.assign(data.preferences)
	messages.append({"role":"user","content":"我刚才说过喜欢哪种回复？用一句话回答。"})
	result = {}
	await create_timer(2.1).timeout
	request = brain.request_chat(messages,preferences,persona,"warm_jade")
	await wait_result(request)
	if not failure.is_empty(): return
	if "简短" not in result.reply:
		printerr("LIVE context recall did not match synthetic preference.")
		quit(1)
		return
	print("LIVE context + persisted preference: OK")
	brain.free()
	print("AI LIVE: 0 failures (3 generations + 1 model-list request, synthetic messages only)")
	quit(0)

func wait_result(request: int) -> void:
	if request != OK:
		failure = "request could not start"
	while brain.busy:
		await process_frame
	if not failure.is_empty():
		printerr("AI LIVE failed: ",failure)
		quit(1)
