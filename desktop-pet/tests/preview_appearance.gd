extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var flame_only := OS.get_cmdline_user_args().has("--flame-only")
	root.size = Vector2i(1000,480) if flame_only else Vector2i(1840,1300)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e7ece5"))
	var catalog = load("res://pet/appearance.gd")
	var styles: Array = [catalog.STYLES[3]] if flame_only else catalog.STYLES
	var colors: Array = catalog.COLORS.slice(6) if flame_only else catalog.COLORS
	for row in range(styles.size()):
		for column in range(colors.size()):
			var origin := Vector2(20+column*(326 if flame_only else 200),20+row*320)
			var dark := row in [1,3] or flame_only
			var background := ColorRect.new()
			background.position = origin
			background.size = Vector2(308,440) if flame_only else Vector2(188,304)
			background.color = Color("233d43") if dark else Color("faf9f1")
			root.add_child(background)
			var actor = load("res://pet/skins/warm_jade/view.tscn").instantiate()
			root.add_child(actor)
			actor.scale = Vector2.ONE*(0.95 if flame_only else 0.62)
			actor.position = origin+(Vector2(154,250) if flame_only else Vector2(94,152))-Vector2(220,133)*actor.scale
			actor.set_appearance(styles[row].id,colors[column].id)
			actor.advance_pose(1.8)
			var label := Label.new()
			label.position = origin+Vector2(12,12)
			label.text = styles[row].name+"\n"+colors[column].name
			label.add_theme_font_size_override("font_size",16)
			label.add_theme_color_override("font_color",Color("e2eee5") if dark else Color("35564a"))
			root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/flame-material-v0.13.png" if flame_only else "res://docs/screenshots/appearance-catalog-v0.13.png")
	quit()
