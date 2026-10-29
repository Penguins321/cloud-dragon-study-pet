extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var scene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	if not app.has_method("_set_renderer_mode"):
		printerr("Missing production 3D renderer setting")
		app.free()
		quit(1)
		return
	app._set_appearance("jade","jade")
	app.settings.renderer_mode_requested.emit("3d")
	var ok: bool = app.renderer_mode == "3d" and app.pet.actor.render_mode == "3d"
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		ok = ok and app.pet.actor._use_3d and app.pet.actor._view_3d.viewport.transparent_bg
		var renderer = app.pet.actor._view_3d
		app.pet.actor.set_growth(0)
		app._set_appearance("jade","ice")
		ok = ok and renderer.stones[1].material_override.get_shader_parameter("core_tint") != null
		root.mode = Window.MODE_MINIMIZED
		app.pet.actor._refresh_effects()
		ok = ok and renderer.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED
		root.mode = Window.MODE_WINDOWED
		app.pet.actor._refresh_effects()
		app.pet.select_action(&"celebrate")
		for i in range(20): app.pet._process(0.1)
		ok = ok and app.pet.actor._use_3d
	app.free()
	await process_frame
	app = scene.instantiate()
	root.add_child(app)
	ok = ok and app.renderer_mode == "3d"
	app._set_renderer_mode("2d")
	ok = ok and not app.pet.actor._use_3d
	app.free()
	print("PRODUCTION RENDERER STATE: ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
