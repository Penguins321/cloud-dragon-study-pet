extends SceneTree

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("Preview timed out"); quit(1))
	call_deferred("run")

func capture(window: Window, filename: String) -> void:
	for frame in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	window.get_texture().get_image().save_png("res://../.tools/v016-"+filename+".png")

func run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app._set_companion_mode("quiet")
	app._focus_action("start", 25)
	app._show_plan()
	app.panel_window.size = Vector2i(500,850)
	await capture(app.panel_window, "plan")
	app._show_settings()
	app.settings_window.size = Vector2i(520,820)
	for tab in range(4):
		app.settings.category_tabs.current_tab = tab
		await capture(app.settings_window, "settings-"+str(tab))
	app._set_font_level(3)
	for tab in [1,3]:
		app.settings.category_tabs.current_tab = tab
		await capture(app.settings_window, "large-"+str(tab))
	app.data_dialog.confirm_import("计划备份\n目标："+"很长但完整可读的学习方向".repeat(10)+"\n500 项任务，260 项已完成。\n保留覆盖前检查点。")
	await capture(app.data_dialog.confirmation, "import-large")
	app.data_dialog.confirmation.hide()
	app._show_plan()
	await capture(app.panel_window, "plan-large")
	app._set_font_level(0)
	app.panel_window.hide()
	await capture(root, "pet-focus")
	app.free()
	print("V016 UI GPU PREVIEWS SAVED")
	quit()
