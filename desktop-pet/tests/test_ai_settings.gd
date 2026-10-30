extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not ResourceLoader.exists("res://ui/ai_settings_panel.gd"):
		check(false, "AI settings card must exist")
		quit(1)
		return
	var panel = load("res://ui/ai_settings_panel.gd").new()
	check(panel.model_input is OptionButton,"Model selection uses a dropdown, never free text")
	panel.theme = load("res://ui/study_theme.tres")
	root.add_child(panel)
	panel.size.x = 410
	var saves: Array = []
	var tests: Array = []
	var chats: Array = []
	panel.chat_requested.connect(func(): chats.append(true))
	panel.chat_button.pressed.emit()
	check(chats.size() == 1,"Chat opens independently of autonomous AI setting")
	panel.save_requested.connect(func(config: Dictionary): saves.append(config))
	panel.test_requested.connect(func(config: Dictionary): tests.append(config))
	panel.save_button.pressed.emit()
	check(saves.back() == {"enabled":false,"provider":"deepseek","model":"deepseek-flash","api_key":"","bubbles":true}, "DeepSeek ready model still requires private credentials")
	check(panel.key_input.secret, "Persisted key remains masked")
	var config := {"enabled":true,"provider":"openai","model":"user-selected-model","api_key":"fake-local-only-key","bubbles":false}
	panel.set_config(config)
	check(saves.size() == 1 and tests.is_empty(), "Restoring config never emits requests")
	panel.save_button.pressed.emit()
	check(saves.back() == config, "Restored provider retains its own model and key on save")
	if panel.model_input is OptionButton:
		panel.model_input.add_item("edited-model")
		panel.model_input.set_item_metadata(panel.model_input.item_count-1,"edited-model")
		panel.model_input.select(panel.model_input.item_count-1)
	else:
		panel.model_input.text = "edited-model"
	panel.key_input.text = "edited-fake-key"
	panel.test_button.pressed.emit()
	check(tests.back() == {"enabled":true,"provider":"openai","model":"edited-model","api_key":"edited-fake-key","bubbles":false}, "Test emits current unsaved form for save-and-test")
	check(panel.test_button.text == "保存并测试连接", "Test explains that credentials will be saved")
	panel.provider.select(0)
	panel.provider.item_selected.emit(0)
	check(panel.model_input.text == "deepseek-flash" and panel.key_input.text.is_empty(), "Provider change resets model and clears previous provider credentials")
	panel.test_button.pressed.emit()
	check(tests.back().provider == "deepseek" and tests.back().api_key == "", "Test never sends former provider's key")
	var pending: Array[Callable] = []
	panel.catalog.transport = func(_url,_headers,done):
		pending.append(done)
		return OK
	panel.key_input.text = "fake-discovery-key"
	panel.refresh_models_button.pressed.emit()
	check(panel.refresh_models_button.disabled,"Model refresh prevents repeated requests")
	pending.back().call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"data":[{"id":"deepseek-flash"},{"id":"deepseek-v4-pro"}]}).to_utf8_buffer())
	check(not panel.refresh_models_button.disabled and panel._form_config().model == "deepseek-flash","Official list refresh preserves current selection")
	panel.model_input.select(1)
	panel.save_button.pressed.emit()
	check(saves.back().model == "deepseek-v4-pro","Save uses selected API ID")
	panel.refresh_models_button.pressed.emit()
	var stale: Callable = pending.back()
	panel.provider.item_selected.emit(1)
	stale.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"data":[{"id":"deepseek-flash"}]}).to_utf8_buffer())
	check(panel._form_config().model.is_empty() and panel.model_input.disabled,"Provider change invalidates in-flight discovery and clears old list")
	panel.key_input.text = "fake-openai-key"
	panel.refresh_models_button.pressed.emit()
	stale = pending.back()
	panel.key_input.text = "different-key"
	panel.key_input.text_changed.emit(panel.key_input.text)
	stale.call(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"data":[{"id":"gpt-4o"}]}).to_utf8_buffer())
	check(panel.model_input.disabled and not panel.refresh_models_button.disabled,"Key edit drops a stale account model response")
	panel.set_status("正在测试连接…",true)
	check(panel.test_button.disabled and panel.status_label.text == "正在测试连接…", "Busy status disables repeated connection tests")
	panel.set_status("连接失败，请检查网络或配置")
	check(not panel.test_button.disabled and panel.status_label.text.contains("连接失败"), "Failure is visible and releases test control")
	panel.key_input.text = "fake-secret-for-redaction"
	panel.set_status("连接失败：fake-secret-for-redaction")
	check(not panel.status_label.text.contains("fake-secret-for-redaction"), "Status never displays the entered key")
	for level in range(4):
		load("res://ui/font_scale.gd").apply(panel,level)
		panel.size.x = 410
		await process_frame
		await process_frame
		check(panel.get_combined_minimum_size().x <= 410, "AI form fits 410px at font level %d" % level)
		for child in panel.get_children():
			if child is Control:
				check(child.position.x >= 0 and child.position.x + child.size.x <= 411, "AI control stays inside narrow card at font level %d" % level)
	panel.free()
	print("AI SETTINGS: ",failures," failures")
	quit(0 if failures == 0 else 1)
