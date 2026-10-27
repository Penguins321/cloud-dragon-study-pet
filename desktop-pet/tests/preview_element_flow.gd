extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var output := OS.get_environment("CLOUD_DRAGON_PREVIEW_DIR")
	if output.is_empty():
		printerr("Use an isolated CLOUD_DRAGON_PREVIEW_DIR")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960,540)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("1c2b38"))
	var actors: Array[Node2D] = []
	var names := ["朱砂 · 火焰","黛紫 · 雷电","月白 · 冰雪"]
	for index in range(3):
		var actor = load("res://pet/skins/warm_jade/view.tscn").instantiate()
		root.add_child(actor)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.scale = Vector2.ONE*0.86
		actor.position = Vector2(160+index*320,292)-Vector2(220,133)*0.86
		actor.set_appearance(["flame","lightning","snow"][index],["ember","violet","ice"][index])
		actor.set_growth(0.45)
		actors.append(actor)
		var label := Label.new()
		label.text = names[index]
		label.position = Vector2(26+index*320,24)
		label.add_theme_font_size_override("font_size",23)
		label.add_theme_color_override("font_color",Color("eee1c5"))
		root.add_child(label)
	for frame in range(120):
		for actor in actors: actor.advance_pose(1.0/24.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var pixels := root.get_texture().get_image()
		if frame == 40:
			pixels.save_png("res://docs/screenshots/guofeng-elements-runtime-v0.14.png")
		pixels.resize(600,338,Image.INTERPOLATE_LANCZOS)
		pixels.save_png(output.path_join("frame-%03d.png" % frame))
	quit()
