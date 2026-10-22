extends RefCounted

static func run(tree: SceneTree) -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Smoke tests require isolated CLOUD_DRAGON_DATA_DIR")
		tree.quit(1)
		return
	# Each run owns fresh data so repeat verification never mutates old progress.
	OS.set_environment("CLOUD_DRAGON_DATA_DIR", OS.get_environment("CLOUD_DRAGON_DATA_DIR").path_join(str(Time.get_ticks_usec())))
	var app = load("res://main.tscn").instantiate()
	tree.root.add_child(app)
	await tree.create_timer(0.5).timeout
	if app.pet.skin == null or app.plan.data.tasks.size() != 4:
		printerr("SMOKE FAIL: skin or isolated default plan missing")
		tree.quit(1)
		return
	app.desktop.pet_clicked.emit()
	if not app.panel_window.visible:
		printerr("SMOKE FAIL: click did not open study panel")
		tree.quit(1)
		return
	await _capture(tree, app.panel_window, "study-plan")
	var first_id: String = app.plan.data.current_id
	app.panel.action_button.pressed.emit()
	if app.plan.data.current_id != first_id or not app.plan.data.tasks[0].completed:
		printerr("SMOKE FAIL: completion advanced or failed")
		tree.quit(1)
		return
	await _capture(tree, app.panel_window, "study-completed")
	app.panel.action_button.pressed.emit()
	if app.plan.data.tasks[1].id != app.plan.data.current_id:
		printerr("SMOKE FAIL: explicit next did not advance")
		tree.quit(1)
		return
	app.panel.settings_requested.emit()
	await _capture(tree, app.settings_window, "settings")
	app.settings.display_scale_requested.emit(0.75)
	if app.pet.scale != Vector2(0.75, 0.75):
		printerr("SMOKE FAIL: display scaling not wired")
		tree.quit(1)
		return
	app.settings_window.hide()
	app.desktop.hide_pet()
	if DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR) and tree.root.mode != Window.MODE_MINIMIZED:
		printerr("SMOKE FAIL: main window was not minimized to tray")
		tree.quit(1)
		return
	app.desktop.show_pet()
	if DisplayServer.get_name() != "headless" and tree.root.mode != Window.MODE_WINDOWED:
		printerr("SMOKE FAIL: tray restore did not restore main window mode")
		tree.quit(1)
		return
	await _capture(tree, tree.root, "desktop-pet")
	print("SMOKE TEST PASSED: click, complete, explicit next, settings, scale, hide/show")
	tree.quit()

static func _capture(tree: SceneTree, window: Window, title: String) -> void:
	var directory := OS.get_environment("CLOUD_DRAGON_SCREENSHOTS")
	if DisplayServer.get_name() == "headless" or directory.is_empty():
		return
	await tree.process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	var image := window.get_texture().get_image()
	var error := image.save_png(directory.path_join(title + ".png"))
	if error != OK:
		printerr("Screenshot save failed: ", error)
