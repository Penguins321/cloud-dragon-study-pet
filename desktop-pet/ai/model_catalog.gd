extends Node

signal models_ready(models: Array[String])
signal failed(message: String)

const ENDPOINTS := {"deepseek":"https://api.deepseek.com/models","openai":"https://api.openai.com/v1/models"}
const DEEPSEEK_MODELS: Array[String] = ["deepseek-flash","deepseek-v4-pro"]
var busy := false
var transport: Callable
var _http: HTTPRequest
var _generation := 0
var _completion: Callable

func cancel() -> void:
	_generation += 1
	busy = false
	if is_instance_valid(_http):
		if _completion.is_valid() and _http.request_completed.is_connected(_completion):
			_http.request_completed.disconnect(_completion)
		_http.cancel_request()

func request_models(provider: String, key: String) -> Error:
	if not ENDPOINTS.has(provider): return ERR_INVALID_PARAMETER
	if key.strip_edges().is_empty(): return ERR_UNCONFIGURED
	for i in key.length():
		if key.unicode_at(i) < 32 or key.unicode_at(i) == 127: return ERR_INVALID_PARAMETER
	if key.length() > 512: return ERR_INVALID_PARAMETER
	if busy: return ERR_BUSY
	_generation += 1
	busy = true
	var done := _finish.bind(_generation,provider,key)
	var headers := PackedStringArray(["Authorization: Bearer " + key])
	var error: Error
	if transport.is_valid():
		error = transport.call(ENDPOINTS[provider],headers,done)
	else:
		if not is_instance_valid(_http):
			_http = HTTPRequest.new()
			_http.timeout = 15.0
			_http.max_redirects = 0
			_http.body_size_limit = 262144
			add_child(_http)
		_completion = done
		_http.request_completed.connect(done,CONNECT_ONE_SHOT)
		error = _http.request(ENDPOINTS[provider],headers)
	if error != OK:
		cancel()
		failed.emit("无法连接模型服务，请检查网络后重试。")
	return error

func _finish(result: int, code: int, _headers: PackedStringArray, bytes: PackedByteArray, generation: int, provider: String, key: String) -> void:
	if generation != _generation or not busy: return
	busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or bytes.size() > 262144:
		failed.emit("密钥无效或无权限，请检查当前服务商的密钥。" if code in [401,403] else "模型列表获取失败，请稍后重试；已保留当前选择。")
		return
	var parsed := JSON.new()
	if parsed.parse(bytes.get_string_from_utf8()) != OK or not parsed.data is Dictionary or not parsed.data.get("data") is Array:
		failed.emit("模型列表格式无效；已保留当前选择。")
		return
	var models: Array[String] = []
	var pattern := RegEx.new()
	pattern.compile("^[a-zA-Z0-9][a-zA-Z0-9._:/-]{0,127}$")
	for entry in parsed.data.data:
		if not entry is Dictionary or not entry.get("id") is String: continue
		var id: String = entry.id
		if pattern.search(id) == null or key in id or id in models: continue
		if provider == "openai" and not _chat_candidate(id): continue
		models.append(id)
		if models.size() >= 256: break
	models.sort()
	if models.is_empty():
		failed.emit("当前账户未返回可用的聊天模型；已保留当前选择。")
	else:
		models_ready.emit(models)

func _chat_candidate(id: String) -> bool:
	# /models provides no Chat Completions compatibility flag. Filter known other
	# modalities; saving/testing still verifies the selected model's JSON support.
	if not (id.begins_with("gpt-") or id.begins_with("chatgpt-") or id.begins_with("o1") or id.begins_with("o3") or id.begins_with("o4") or id.begins_with("ft:gpt-")): return false
	for excluded in ["image","audio","realtime","transcribe","tts","search","instruct","codex","deep-research","-pro"]:
		if excluded in id: return false
	return true
