extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if app.get("ai_brain") == null:
		check(false,"Application must integrate AI config, decision and bubble components")
		app.free()
		quit(1)
		return
	check(not app.ai_config.enabled,"AI is off until explicitly enabled")
	var key := "integration-placeholder-not-a-real-key"
	var config := {"enabled":true,"provider":"deepseek","model":"test-model","api_key":key,"bubbles":true}
	check(app._save_ai_settings(config) == OK,"AI settings save in isolated private file")
	check(FileAccess.file_exists(app.ai_config_path),"AI private configuration persists")
	check(not key in app.preferences.encode_to_text(),"Normal preference backups must not contain API key")
	check(not key in JSON.stringify(app.plan.to_dict()),"Learning data must not contain API key")
	app.panel_window.hide()
	app.settings_window.hide()
	app.pet.play_action(&"idle")
	app._ai_request_skin = app.selected_skin
	app._on_ai_decision({"action":&"look","text":"慢慢来，我在这里。","test":false,"intent":"想四处逛逛","plan":["walk","rest"]})
	if DisplayServer.get_name() != "headless":
		check(app.pet.current_action == &"look","Valid AI decision uses existing animation")
		check(app.ai_bubble.visible,"AI can show short speech")
		check(app._mind().context().remaining_plan == [&"walk",&"rest"],"AI episode is retained for follow-up execution")
		check(app.settings.ai_panel.intention_label.text.contains("想四处逛逛"),"Companion intention is visible")
	app._show_settings()
	check(app._mind().context().remaining_plan.is_empty(),"Opening settings interrupts the old plan")
	check(not app.ai_bubble.visible,"Settings immediately silence AI bubble")
	app._ai_request_skin = app.selected_skin
	app._on_ai_decision({"action":&"dance","text":"不应显示","test":false})
	check(not app.ai_bubble.visible and app.pet.current_action != &"dance","Late result cannot interrupt an open panel")
	app.panel_window.hide()
	app.settings_window.hide()
	app.pet.play_action(&"idle")
	app._ai_request_skin = "wrong-old-skin"
	app._on_ai_decision({"action":&"look","text":"不应显示","test":false})
	check(app.pet.current_action == &"idle" and not app.ai_bubble.visible,"Old role response is discarded")
	app._ai_request_skin = app.selected_skin
	app.companion_mode = "quiet"
	app._on_ai_decision({"action":&"dance","text":"不应显示","test":false})
	check(not app.ai_bubble.visible,"Quiet mode blocks generated speech")
	app.companion_mode = "natural"
	app._ai_request_skin = app.selected_skin
	app._on_ai_decision({"action":&"dragging","text":"不应显示","test":false})
	check(app.pet.current_action == &"idle","Injected invalid action cannot play")
	var state: Dictionary = app._ai_context()
	check(not "goal" in state and not "title" in state and not key in JSON.stringify(state),"Only anonymous companion state is sent")
	app.free()
	await process_frame
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	check(app.ai_config.enabled and app.ai_config.api_key == key,"Private key/settings restore after restart")
	check(app.settings.ai_panel.key_input.secret,"Settings masks the persisted API key")
	app.free()
	print("AI INTEGRATION: ",failures," failures")
	quit(0 if failures == 0 else 1)
