extends SceneTree

var failures := 0
var now := 1000000
var completion: Callable
var sent: Dictionary
var decisions: Array[Dictionary] = []
var errors: Array[String] = []
var transport_error := OK
var chats: Array[Dictionary] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void: call_deferred("run")

func fake_request(url: String, headers: PackedStringArray, body: String, done: Callable) -> Error:
	sent = {"url":url,"headers":headers,"body":JSON.parse_string(body)}
	completion = done
	return transport_error

func response(action: Variant = "look", text: Variant = "你好", finish: String = "stop") -> PackedByteArray:
	return JSON.stringify({"choices":[{"finish_reason":finish,"message":{"content":JSON.stringify({"action":action,"text":text})}}]}).to_utf8_buffer()

func run() -> void:
	if not FileAccess.file_exists("res://ai/config_store.gd") or not FileAccess.file_exists("res://ai/companion_brain.gd"):
		check(false, "AI core modules must exist")
		quit(1)
		return
	var store = load("res://ai/config_store.gd")
	var path := ProjectSettings.globalize_path("res://../.tools/ai-core-tests/ai_private.cfg")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	DirAccess.remove_absolute(path)
	var cfg: Dictionary = store.defaults()
	check(cfg == {"enabled":false,"provider":"deepseek","model":"deepseek-flash","api_key":"","bubbles":true}, "safe defaults with ready DeepSeek model")
	check(store.load_config(path).config == cfg, "missing config loads defaults")
	cfg.merge({"enabled":true,"model":"my-model","api_key":"fake-secret-test-key"},true)
	check(store.save_config(path,cfg) == OK, "save private config")
	check(store.load_config(path).config == cfg,"restart restores key")
	cfg.model = "updated-model"
	check(store.save_config(path,cfg) == OK and store.load_config(path).config == cfg,"atomic replacement overwrites existing file")
	check(not FileAccess.file_exists(path+".tmp") and not FileAccess.file_exists(path+".bak"),"no temporary/backup key copies")
	for bad in [123, "bad\r\nInjected: header", "x".repeat(513)]:
		var invalid := cfg.duplicate()
		invalid.api_key = bad
		check(not store.validate(invalid),"invalid key rejected")
	for entry in [{"enabled":"true"},{"provider":"other"},{"model":32},{"bubbles":0},{"model":"x".repeat(129)}]:
		var invalid := cfg.duplicate()
		invalid.merge(entry,true)
		check(not store.validate(invalid),"invalid settings types/provider/length rejected")
	check(store.save_config(path,{}) == ERR_INVALID_PARAMETER and store.load_config(path).config == cfg,"invalid save preserves existing private settings")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("[invalid\n")
	file.close()
	check(store.load_config(path).error != OK,"corrupt config reports error")
	check(FileAccess.get_file_as_string(path) == "[invalid\n","corrupt original preserved")
	var brain = load("res://ai/companion_brain.gd").new()
	root.add_child(brain)
	brain.transport = fake_request
	brain.clock_msec = func(): return now
	brain.decision_ready.connect(func(d): decisions.append(d))
	brain.failed.connect(func(s): errors.append(s))
	brain.configure(cfg)
	var actions: Array[StringName] = [&"idle",&"look",&"dragging",&"breath"]
	check(brain.request_decision({"companion":"jade","event":"idle","idle_band":"short","focus":false,"recent_actions":["look"],"title":"PRIVATE-TASK"},actions) == OK,"auto accepted")
	check(brain.busy and brain.next_allowed_msec == now+120000,"single flight and cooldown begin at request")
	check(sent.url == "https://api.deepseek.com/chat/completions","fixed DeepSeek endpoint")
	check(sent.body.max_tokens == 256 and sent.body.thinking.type == "disabled","DeepSeek token/thinking controls")
	var payload := JSON.stringify(sent.body)
	check(not "PRIVATE-TASK" in payload and not "dragging" in payload,"context and actions whitelist")
	check("json" in payload.to_lower() and sent.body.response_format.type == "json_object","JSON explicitly requested")
	check(brain.request_decision({},actions,true) == ERR_BUSY,"manual cannot overlap auto")
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),response())
	check(not brain.busy and decisions.size() == 1 and decisions[0].action == &"look","valid response emitted")
	brain.cancel()
	brain.configure(cfg)
	check(brain.request_decision({},actions) != OK,"configure/cancel retain auto cooldown")
	cfg.enabled = false
	cfg.provider = "openai"
	brain.configure(cfg)
	check(brain.request_decision({},actions,true) == OK,"manual allowed disabled")
	check(sent.url == "https://api.openai.com/v1/chat/completions" and sent.body.max_completion_tokens == 256 and not sent.body.has("max_tokens"),"OpenAI request settings")
	var stale := completion
	brain.cancel()
	stale.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),response())
	check(decisions.size() == 1,"cancel drops stale response")
	check(brain.request_decision({},actions,true) != OK,"manual cooldown retained on cancel")
	for invalid in [response("dragging"),response("look",12),response("look","hi\nthere"),response("look","https://evil.test"),response("look","example.com"),response("look","[b]hello[/b]"),response("look","safe","length"),"[]".to_utf8_buffer(),"{".to_utf8_buffer()]:
		now += 10000
		check(brain.request_decision({},actions,true) == OK,"next manual request")
		var count := errors.size()
		completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),invalid)
		check(errors.size() == count+1 and decisions.size() == 1,"invalid provider output rejected")
	now += 10000
	brain.request_decision({},actions,true)
	completion.call(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray())
	check(not brain.busy,"timeout clears busy")
	now += 10000
	brain.request_decision({},actions,true)
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),"x".repeat(65537).to_utf8_buffer())
	check(not brain.busy and decisions.size() == 1,"oversized response rejected")
	now += 10000
	brain.request_decision({},actions,true)
	completion.call(HTTPRequest.RESULT_SUCCESS,401,PackedStringArray(),cfg.api_key.to_utf8_buffer())
	check(not cfg.api_key in JSON.stringify(errors),"provider error body never leaks key")
	check("密钥" in errors.back(),"Authentication error explains how to fix credentials")
	for item in [[402,"余额"],[429,"频繁"],[400,"模型"],[503,"繁忙"]]:
		now += 10000
		brain.request_decision({},actions,true)
		completion.call(HTTPRequest.RESULT_SUCCESS,item[0],PackedStringArray(),cfg.api_key.to_utf8_buffer())
		check(item[1] in errors.back() and not cfg.api_key in errors.back(),"HTTP error offers actionable safe reason")
	now += 10000
	brain.request_decision({},actions,true)
	completion.call(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray())
	check("超时" in errors.back(),"Timeout can be distinguished from invalid configuration")
	now += 10000
	brain.request_decision({},actions,true)
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),response("look",cfg.api_key))
	check(not cfg.api_key in JSON.stringify(decisions),"response text cannot echo credential")
	now += 10000
	transport_error = ERR_CANT_CONNECT
	check(brain.request_decision({},actions,true) == ERR_CANT_CONNECT and not brain.busy,"request start error clears busy")
	check(brain.request_decision({},actions,true) == ERR_BUSY,"request start error retains test limit")
	cfg.enabled = true
	brain.configure(cfg)
	now += 120000
	check(brain.request_decision({},actions) == ERR_CANT_CONNECT,"auto start failure")
	check(brain.next_allowed_msec == now+120000 and brain.request_decision({},actions) == ERR_BUSY,"failed auto calls retain 120 second cooldown")
	transport_error = OK
	now += 120000
	brain.request_decision({},actions)
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),response("idle","好".repeat(30)))
	check(decisions.back().text.length() == 24 and not decisions.back().test,"long safe speech truncated to 24 chars")
	now += 120000
	brain.request_decision({},actions)
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),response("idle",""))
	check(decisions.back().text == "","silent action accepted")
	now += 120000
	brain.request_decision({"mind":{"energy":0.2,"curiosity":0.7,"social_need":0.4,"intention":"想休息","recent_actions":["dance"],"remaining_plan":["look"],"private_task":"not sent"}},actions)
	check(sent.body.messages[1].content.contains("energy") and not sent.body.messages[1].content.contains("not sent"),"Only bounded simulated needs enter autonomous context")
	var planned := {"choices":[{"finish_reason":"stop","message":{"content":JSON.stringify({"action":"idle","text":"我歇一会儿","intent":"玩累了想休息","plan":["look","dragging","look","breath"]})}}]}
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify(planned).to_utf8_buffer())
	check(decisions.back().plan == ["look","breath"] and decisions.back().intent == "玩累了想休息","Short plans retain valid unique follow-ups and a safe intention")
	test_chat(brain,cfg,actions)
	brain.free()
	DirAccess.remove_absolute(path)
	print("AI CORE: ",failures," failures")
	quit(0 if failures == 0 else 1)

func chat_response(reply: Variant = "我在这里。\n慢慢说。", memories: Variant = [], finish: String = "stop", refusal: Variant = null) -> PackedByteArray:
	return JSON.stringify({"choices":[{"finish_reason":finish,"message":{"content":JSON.stringify({"reply":reply,"memories":memories}),"refusal":refusal}}]}).to_utf8_buffer()

func test_chat(brain: Node, config: Dictionary, actions: Array[StringName]) -> void:
	if not brain.has_method("request_chat"):
		check(false,"conversation API must exist")
		return
	brain.chat_ready.connect(func(reply,memories): chats.append({"reply":reply,"memories":memories}))
	var cfg := config.duplicate()
	var empty_memories: Array[String] = []
	cfg.enabled = false
	brain.configure(cfg)
	var history: Array = [{"role":"system","content":"INJECTED-SYSTEM"}]
	for i in 15:
		history.append({"role":"user" if i % 2 else "assistant","content":"a".repeat(1100)})
	history.append({"role":"user","content":"我喜欢安静。"})
	var memories: Array[String] = []
	for i in 25:
		memories.append("喜".repeat(200))
	check(brain.request_chat(history,memories,"温柔".repeat(400),"jade") == OK,"chat allowed while autonomous disabled")
	check(sent.body.max_completion_tokens == 1200,"chat OpenAI token budget")
	check(brain.request_decision({},actions,true) == ERR_BUSY and brain.request_chat(history,memories,"","jade") == ERR_BUSY,"chat shares single flight with decisions")
	check(not "INJECTED-SYSTEM" in JSON.stringify(sent.body),"only user/assistant history accepted")
	check(sent.body.messages.size() <= 14,"chat history bounded")
	for message in sent.body.messages:
		if message.role in ["user","assistant"]:
			if message.role == "assistant":
				var parsed := JSON.new()
				var parsed_ok := parsed.parse(message.content) == OK and parsed.data is Dictionary
				check(parsed_ok,"Assistant history preserves JSON reply protocol across turns")
				if parsed_ok:
					check(parsed.data.get("reply","").length() <= 1000 and parsed.data.get("memories") == [],"Historical replies are bounded without re-extracting old memories")
			else:
				check(message.content.length() <= 1000,"each user history message bounded")
	var metadata: Dictionary = JSON.parse_string(sent.body.messages[1].content)
	check(metadata.persona.length() <= 600 and metadata.memories.size() <= 20 and metadata.memories[0].length() <= 160,"persona/memory context bounded")
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),chat_response("好的。",["我喜欢安静。","我喜欢吵闹。",42,"我喜欢安静。", "sk-example-secret"]))
	check(chats.size() == 1 and chats[0].memories == ["我喜欢安静。"],"only explicit quoted preference suggestions retained")
	check(brain.request_chat(history,memories,"","jade") == ERR_BUSY,"chat two second throttle")
	brain.configure(cfg)
	check(brain.request_chat(history,memories,"","jade") == ERR_BUSY,"configure preserves chat throttle")
	now += 2000
	brain.request_chat(history,memories,"","jade")
	var stale := completion
	brain.cancel()
	stale.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),chat_response())
	check(chats.size() == 1 and not brain.busy,"cancel discards late chat")
	check(brain.request_chat(history,memories,"","jade") == ERR_BUSY,"cancel preserves chat throttle")
	for bytes in [chat_response(12),chat_response("ok",{}),chat_response("hello","bad"),chat_response("x".repeat(801)),chat_response("https://evil.test"),chat_response("[b]bad[/b]"),chat_response(cfg.api_key),chat_response("safe",[],"length"),chat_response("safe",[],"stop","refused")]:
		now += 2000
		brain.request_chat(history,memories,"","jade")
		var count := errors.size()
		completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),bytes)
		check(errors.size() == count+1 and chats.size() == 1,"invalid chat rejected")
	now += 2000
	brain.request_chat([{"role":"user","content":"今天做作业"}],empty_memories,"","jade")
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),chat_response("我在这里。\n慢慢来。",["我喜欢安静。","请记住今天做作业"]))
	check(chats.back().reply.contains("\n") and chats.back().memories.is_empty(),"newlines accepted and no inferred/transient memories")
	now += 2000
	cfg.provider = "deepseek"
	brain.configure(cfg)
	brain.request_chat([{"role":"user","content":"请记住我的身份证号码123456789"}],empty_memories,"","jade")
	check(sent.body.max_tokens == 1200 and sent.body.thinking.type == "disabled","chat DeepSeek settings")
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),chat_response("好的。",["请记住我的身份证号码123456789"]))
	check(chats.back().memories.is_empty(),"sensitive IDs never suggested as memory")
	check(not cfg.api_key in JSON.stringify(chats),"chat never echoes configured key")
	now += 2000
	brain.request_chat([{"role":"user","content":"不要记住这个 "+cfg.api_key}],empty_memories,cfg.api_key,"jade")
	check(not cfg.api_key in JSON.stringify(sent.body),"credential redacted from chat payload metadata/history")
	var before := chats.size()
	completion.call(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray())
	check(not brain.busy and chats.size() == before,"chat timeout clears busy without partial reply")
	check(brain.request_chat(history,memories,"","jade") == ERR_BUSY,"failed chat retains throttle")
	now += 2000
	transport_error = ERR_CANT_CONNECT
	check(brain.request_chat(history,memories,"","jade") == ERR_CANT_CONNECT and not brain.busy,"chat start error clears busy")
	transport_error = OK
	now += 2000
	brain.request_chat(history,memories,"","jade")
	completion.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),chat_response("好的。",["我喜欢安静。",null,{},"我喜欢不存在的事。"]))
	check(chats.back().memories == ["我喜欢安静。"],"partially malformed memory candidates cannot discard safe reply or introduce inferred facts")
	var context: Dictionary = brain._safe_context({"preferences":["我喜欢安静。"],"persona":"温柔","title":"PRIVATE"})
	check(context.get("preferences") == ["我喜欢安静。"] and context.get("persona") == "温柔" and not context.has("title"),"decisions may use approved personality/preferences only")
