extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1080,740)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e9e5dc"))
	var actions := [&"idle", &"look", &"stretch", &"rest", &"celebrate", &"breath"]
	var titles := ["悬浮 · 初始 / 回归", "感知", "舒展", "收息", "共鸣", "引光"]
	for index in range(6):
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
		view.set_process(false)
		view.position = Vector2(index%3*360+4,index/3*360+30)
		view.scale = Vector2.ONE*0.8
		view.select_action(actions[index])
		for frame in range(105): view._process(1.0/60.0)
		var label := Label.new()
		label.text = titles[index]
		label.position = Vector2(index%3*360+80,index/3*360+283)
		label.add_theme_font_size_override("font_size",22)
		label.add_theme_color_override("font_color",Color("536453"))
		root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/warm-jade-poses.png")
	quit()
