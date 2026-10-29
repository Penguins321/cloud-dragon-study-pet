extends SceneTree

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("Companion settings preview timed out"); quit(1))
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Companion settings preview needs GPU rendering and isolated data")
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app._set_skin("corgi")
	app._set_font_level(0)
	app._show_settings()
	app.settings_window.size = Vector2i(540,1000)
	app.settings.category_tabs.current_tab = 0
	for frame in 12:
		await process_frame
		await RenderingServer.frame_post_draw
	var actor = app.settings.appearance_preview.actor
	var image: Image = actor.viewport.get_texture().get_image()
	var visible_pixels := 0
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			if image.get_pixel(x,y).a > 0.1: visible_pixels += 1
	if actor.model == null or actor.native_player == null or visible_pixels < 100:
		printerr("Actual imported animal must be visible in settings preview")
		app.free()
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/v0.17")
	var path := "res://docs/screenshots/v0.17/companion-settings.png"
	var error: Error = app.settings_window.get_texture().get_image().save_png(path)
	print("COMPANION_SETTINGS_GPU: ", error, "; animal samples: ", visible_pixels, "; ", path)
	app.settings_window.hide()
	app.pet.set_active(false)
	for frame in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	app.free()
	quit(error)
