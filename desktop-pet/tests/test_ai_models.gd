extends SceneTree
var failures := 0
var done: Callable
var sent_url := ""
var models: Array = []
var errors: Array[String] = []
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://ai/model_catalog.gd"):
		check(false,"Official model discovery must exist")
		quit(1)
		return
	var catalog = load("res://ai/model_catalog.gd").new()
	root.add_child(catalog)
	catalog.models_ready.connect(func(value): models.append(value))
	catalog.failed.connect(func(value): errors.append(value))
	catalog.transport = func(url, _headers, callback):
		sent_url = url
		done = callback
		return OK
	check(catalog.request_models("deepseek","") == ERR_UNCONFIGURED,"No unauthenticated discovery")
	check(catalog.request_models("other","fake-key") == ERR_INVALID_PARAMETER,"Only official providers accepted")
	check(catalog.request_models("deepseek","fake-key") == OK,"Discovery starts")
	check(sent_url == "https://api.deepseek.com/models","DeepSeek official discovery URL")
	done.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"data":[{"id":"deepseek-flash","name":"DeepSeek-V4.1-Flash"},{"id":"deepseek-v4-pro"},{"id":"deepseek-flash"},{"id":"fake-key"},{"id":"bad\nmodel"},{}]}).to_utf8_buffer())
	check(models == [["deepseek-flash","deepseek-v4-pro"]],"Use API ID, discard duplicates/malformed IDs and key echoes")
	catalog.request_models("openai","fake-key")
	check(sent_url == "https://api.openai.com/v1/models","OpenAI official discovery URL")
	done.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"data":[{"id":"gpt-4.1"},{"id":"text-embedding-3-small"},{"id":"gpt-image-1"},{"id":"gpt-4o-realtime-preview"},{"id":"gpt-4o-transcribe"},{"id":"gpt-4o-mini"}]}).to_utf8_buffer())
	check(models.back() == ["gpt-4.1","gpt-4o-mini"],"Discovery excludes known non-chat models")
	catalog.request_models("deepseek","fake-key")
	var stale := done
	catalog.cancel()
	stale.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"data":[{"id":"wrong-provider"}]}).to_utf8_buffer())
	check(models.size() == 2,"Canceled discovery cannot overwrite provider selection")
	catalog.request_models("deepseek","fake-key")
	done.call(HTTPRequest.RESULT_SUCCESS,401,PackedStringArray(),"fake-key".to_utf8_buffer())
	check(errors.size() == 1 and "密钥" in errors.back() and not "fake-key" in errors.back(),"Fixed authentication error never echoes provider payload")
	catalog.request_models("deepseek","fake-key")
	done.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),"{\"data\":42}".to_utf8_buffer())
	check(errors.size() == 2 and not catalog.busy,"Malformed list releases discovery state")
	catalog.free()
	print("AI MODELS: ",failures," failures")
	quit(0 if failures == 0 else 1)
