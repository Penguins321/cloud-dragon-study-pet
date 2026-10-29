extends SceneTree

# Run from a fresh scratch project and inspect the actual final ZIP's PCK.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not ProjectSettings.load_resource_pack(OS.get_environment("INSPECT_PCK")):
		quit(1)
		return
	var scene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	if app.settings == null:
		printerr("Packaged application could not initialize")
		app.free()
		quit(1)
		return
	app._set_font_level(0)
	app._set_appearance("jade","jade")
	app._set_renderer_mode("3d")
	var renderer_ok: bool = app.renderer_mode == "3d" and app.pet.actor.render_mode == "3d"
	for action in [&"orbit",&"helix",&"cross_orbit",&"refract_turn"]:
		renderer_ok = renderer_ok and app.pet.skin.action_map.has(action)
	if OS.get_cmdline_user_args().has("--render-check"):
		for frame in range(4):
			await process_frame
			await RenderingServer.frame_post_draw
		renderer_ok = renderer_ok and app.pet.actor._use_3d and app.pet.actor._view_3d._validated
		if renderer_ok:
			var pixels: Image = app.pet.actor._view_3d.viewport.get_texture().get_image()
			renderer_ok = pixels.get_pixel(0,0).a < 0.001
			var core = app.pet.actor._view_3d.stones[1]
			renderer_ok = renderer_ok and core.get_child_count()==1 and core.material_override.get_shader_parameter("core_energy")>0.0
			renderer_ok = renderer_ok and core.material_override.get_shader_parameter("refraction_index")>1.1
			app.pet.set_process(false)
			app.pet.select_action(&"orbit")
			for frame in range(120): app.pet._process(1.0/60)
			renderer_ok = renderer_ok and absf(app.pet.actor._view_3d.stones[0].position.z)>0.5
	app._set_renderer_mode("2d")
	renderer_ok = renderer_ok and not app.pet.actor._use_3d
	app._set_renderer_mode("3d")
	var names: Array[String] = []
	for button in app.settings.font_buttons: names.append(button.text)
	var base: int = app.panel.current_label.get_theme_font_size("font_size")
	var editor_base: int = app.panel._titles_input.get_theme_font_size("font_size")
	var dialog_base: int = app.panel._confirm.get_ok_button().get_theme_font_size("font_size")
	app.settings.font_level_requested.emit(3)
	await process_frame
	var large: int = app.panel.current_label.get_theme_font_size("font_size")
	var ok: bool = names == ["正常","大一点","戴眼镜","老年人"] and large > base and app.settings.FONT_SETTINGS_REVISION == "0.14.2-font-sync"
	ok = ok and app.panel._titles_input.get_theme_font_size("font_size") > editor_base
	ok = ok and app.panel._confirm.get_ok_button().get_theme_font_size("font_size") > dialog_base
	var appearance = load("res://pet/appearance.gd")
	ok = ok and appearance.selection("flame","ember") == ["jade","jade"] and not app.settings._style_buttons.has("flame")
	app._render()
	ok = ok and app.panel._list.get_child(0).get_theme_font_size("font_size") > editor_base
	app.free()
	await process_frame
	app = scene.instantiate()
	root.add_child(app)
	ok = ok and app.font_level == 3 and app.panel.current_label.get_theme_font_size("font_size") == large and app.renderer_mode == "3d" and renderer_ok
	app.free()
	print("MAC PACKAGE ALL-PAGE FONT SYNC: ","PASS" if ok else "FAIL"," ",names," plan ",base," -> ",large)
	print("MAC PACKAGE RENDERER STATE/GPU: ",renderer_ok," graphics=",OS.get_cmdline_user_args().has("--render-check"))
	quit(0 if ok else 1)
