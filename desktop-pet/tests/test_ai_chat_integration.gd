extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if app.get("chat_panel") == null:
		check(false,"Application must integrate conversation, private memory and persona")
		app.free()
		quit(1)
		return
	var config := {"enabled":false,"provider":"openai","model":"mock","api_key":"chat-placeholder-not-real","bubbles":true}
	check(app._save_ai_settings(config) == OK,"Chat can configure a key while autonomous mode is off")
	var pending: Array[Callable] = []
	var bodies: Array[String] = []
	app.ai_brain.transport = func(_url,_headers,body,done):
		pending.append(done)
		bodies.append(body)
		return OK
	app._show_ai_chat()
	app.chat_panel.message_input.text = "我喜欢安静，请记住。"
	app._send_ai_chat(app.chat_panel.message_input.text)
	check(app._ai_chat_pending and app.ai_brain.busy,"Chat request starts independently of auto toggle")
	var response := {"choices":[{"finish_reason":"stop","message":{"content":JSON.stringify({"reply":"好，我会轻轻陪着你。","memories":["我喜欢安静"]})}}]}
	pending[0].call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify(response).to_utf8_buffer())
	check(not app._ai_chat_pending and not app.ai_brain.busy,"Chat completes")
	check(app.ai_memory_data.preferences.has("我喜欢安静"),"Explicit preference becomes editable long-term memory")
	check(app.ai_memory_data.histories.warm_jade.size() == 2,"One successful exchange persists as a pair")
	check(app.chat_panel.message_input.text.is_empty(),"Successful send clears only its matching draft")
	check(not "chat-placeholder-not-real" in FileAccess.get_file_as_string(app.ai_memory_path),"API key never enters conversation file")
	app.ai_brain.clock_msec = func(): return 100000000
	app.chat_panel.message_input.text = "一次失败的追问"
	app._send_ai_chat(app.chat_panel.message_input.text)
	pending.back().call(HTTPRequest.RESULT_SUCCESS,429,PackedStringArray(),PackedByteArray())
	check(app.chat_panel.message_input.text == "一次失败的追问" and app.ai_memory_data.histories.warm_jade.size() == 2,"Failed follow-up preserves draft without creating a partial exchange")
	check("重试" in app.chat_panel.send_button.text and not app.chat_panel.send_button.disabled,"Failure offers explicit retry")
	check("频繁" in app.chat_panel.status_label.text,"Root preserves useful provider error guidance")
	app._send_ai_chat(app.chat_panel.message_input.text)
	check(app.chat_panel.message_input.text == "一次失败的追问" and not app._ai_chat_pending,"Immediate throttled retry preserves draft and releases pending state")
	app.ai_brain.clock_msec = func(): return 100003000
	app.chat_panel.send_button.pressed.emit()
	check(app._ai_chat_pending,"Retry after cooldown starts a new request")
	app._cancel_ai_chat()
	pending.back().call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify(response).to_utf8_buffer())
	check(app.ai_memory_data.histories.warm_jade.size() == 2 and app.chat_panel.message_input.text == "一次失败的追问","Cancel preserves draft and rejects late reply")
	app._save_ai_persona("沉静、温柔，喜欢柔和的光。")
	app._ai_chat_pending_text = "过期问题"
	app._ai_chat_pending_role = "warm_jade"
	app._ai_chat_pending = true
	app._apply_skin_id("corgi")
	var none: Array[String] = []
	app._on_ai_chat_ready("不应该存入新伙伴",none)
	check(not app.ai_memory_data.histories.has("corgi"),"Changing companion invalidates old chat")
	app._apply_skin_id("warm_jade")
	var memories: Array[String] = []
	app._save_ai_preferences(memories)
	check(app.ai_memory_data.preferences.is_empty(),"User can delete saved preferences")
	app.free()
	await process_frame
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	check(app.ai_memory_data.histories.warm_jade.size() == 2,"Conversation survives restart")
	check(app.ai_memory_data.personas.warm_jade == "沉静、温柔，喜欢柔和的光。","Persona survives restart")
	check(app.ai_memory_data.preferences.is_empty(),"Deleted preference stays deleted")
	check(app.ai_config.api_key == "chat-placeholder-not-real","Private key still restores")
	app._clear_ai_chat_history()
	check(not app.ai_memory_data.histories.has("warm_jade") and app.ai_memory_data.personas.has("warm_jade"),"Clearing dialogue preserves persona")
	app.free()
	print("AI CHAT INTEGRATION: ",failures," failures")
	quit(0 if failures == 0 else 1)
