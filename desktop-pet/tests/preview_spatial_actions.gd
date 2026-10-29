extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(900,740)
	root.title = "温玉灵核 · 3D 动作"
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("19383b"))
	var view = load("res://pet/pet_view.gd").new()
	root.add_child(view)
	view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
	view.position = Vector2(450,425)-Vector2(220,133)*1.5
	view.scale = Vector2.ONE*1.5
	view.actor.set_appearance("jade","jade")
	view.actor.set_render_mode("3d")
	var title := Label.new()
	title.text = "温玉灵核 · 灵片环绕"
	title.position = Vector2(290,35)
	title.add_theme_font_size_override("font_size",28)
	root.add_child(title)
	var row := HBoxContainer.new()
	row.position = Vector2(190,90)
	row.add_theme_constant_override("separation",12)
	root.add_child(row)
	for entry in [["双片环绕",&"orbit"],["螺旋升降",&"helix"],["交错环绕",&"cross_orbit"],["核心巡光",&"refract_turn"]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(func(): view.select_action(entry[1]); title.text="温玉灵核 · "+entry[0])
		row.add_child(button)
	view.select_action(&"orbit")
	if not OS.get_cmdline_user_args().has("--capture"): return
	view.set_process(false)
	row.hide()
	var directory := ProjectSettings.globalize_path("res://../.tools/spatial-orbit-frames")
	DirAccess.make_dir_recursive_absolute(directory)
	for frame in range(240):
		for tick in range(2): view._process(1.0/60)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("%03d.png"%frame))
	quit()
