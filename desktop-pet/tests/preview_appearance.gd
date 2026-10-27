extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var elements := OS.get_cmdline_user_args().has("--elements") or OS.get_cmdline_user_args().has("--flame-only")
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e7ece5"))
	var catalog = load("res://pet/appearance.gd")
	root.size = Vector2i(1000,540) if elements else Vector2i(40+200*catalog.COLORS.size(),20+320*catalog.STYLES.size())
	var styles: Array = [catalog.STYLES[3],catalog.STYLES[4],catalog.STYLES[5]] if elements else catalog.STYLES
	var colors: Array = catalog.COLORS
	for row in range(1 if elements else styles.size()):
		for column in range(3 if elements else colors.size()):
			var style: Dictionary = styles[column] if elements else styles[row]
			var color: Dictionary = colors[[6,2,1][column]] if elements else colors[column]
			var origin := Vector2(20+column*(326 if elements else 200),20+row*320)
			var dark := row in [1,3,4,5] or elements
			var background := ColorRect.new()
			background.position = origin
			background.size = Vector2(308,500) if elements else Vector2(188,304)
			background.color = Color("233d43") if dark else Color("faf9f1")
			root.add_child(background)
			var actor = load("res://pet/skins/warm_jade/view.tscn").instantiate()
			root.add_child(actor)
			var is_flame: bool = style.id == "flame"
			actor.scale = Vector2.ONE*(0.85 if elements else (0.44 if style.id in ["flame","snow"] else 0.62))
			actor.position = origin+(Vector2(154,275) if elements else Vector2(94,175 if is_flame else 152))-Vector2(220,133)*actor.scale
			actor.set_appearance(style.id,color.id)
			actor.advance_pose(1.8)
			var label := Label.new()
			label.position = origin+Vector2(12,12)
			label.text = style.name+"\n"+color.name
			label.add_theme_font_size_override("font_size",16)
			label.add_theme_color_override("font_color",Color("e2eee5") if dark else Color("35564a"))
			root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/element-spirits-v0.14.png" if elements else "res://docs/screenshots/appearance-catalog-v0.14.png")
	quit()
