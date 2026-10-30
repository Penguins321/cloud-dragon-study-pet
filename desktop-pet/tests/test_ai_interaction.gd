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
	app.panel_window.hide()
	app.settings_window.hide()
	app.desktop.last_click_double = false
	app._handle_pet_click()
	check(app.chat_window.visible,"Single click directly opens conversation")
	check(app.pet.current_action != &"idle","Single click also changes performance action")
	var prior: StringName = app.pet.current_action
	app._handle_pet_click()
	check(app.pet.current_action != prior,"Consecutive clicks change the current action")
	app.chat_window.hide()
	app.desktop._on_menu(4)
	check(app.panel_window.visible,"Learning goal has its own menu route")
	app.panel_window.hide()
	app._set_skin("corgi")
	app.desktop.last_click_double = true
	app._handle_pet_click()
	check(app.pet.current_action == &"bow","Animal double click retains greeting")
	if DisplayServer.get_name() != "headless":
		app._set_skin("warm_jade")
		app.desktop.last_click_double = false
		for mode in ["quiet","reduced","focus"]:
			app.panel_window.hide()
			app.settings_window.hide()
			app.chat_window.hide()
			if mode == "quiet": app._set_companion_mode("quiet")
			if mode == "reduced": app._set_reduced_motion(true)
			if mode == "focus": app._focus_action("start",5)
			app._handle_pet_click()
			await process_frame
			await process_frame
			check(app.chat_window.visible,"Manual chat opens in " + mode)
			app.chat_window.hide()
			app._set_companion_mode("natural")
			app._set_reduced_motion(false)
			app._focus_action("cancel")
	app.free()
	print("AI INTERACTION: ",failures," failures")
	quit(0 if failures == 0 else 1)
