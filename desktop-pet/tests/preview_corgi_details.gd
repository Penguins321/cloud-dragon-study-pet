extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1040,440)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("f1f3e9"))
	var actors := []
	for index in range(3):
		var texture: Texture2D
		if index == 0:
			texture = ImageTexture.create_from_image(Image.load_from_file("res://docs/screenshots/v0.17/corgi-before.png"))
		else:
			var actor = load("res://pet/skins/animals/corgi.tscn").instantiate()
			root.add_child(actor)
			actor.position = Vector2(-2000,0)
			actor.process_mode = Node.PROCESS_MODE_DISABLED
			actor.player.play("idle")
			if index == 2: actor.set_desktop_attention(Vector2(1,-0.3))
			for frame in (174 if index == 2 else 60): actor.advance_pose(1.0/60.0)
			actors.append(actor)
			texture = actor.viewport.get_texture()
		var art := TextureRect.new()
		art.texture = texture
		art.position = Vector2(10+index*345,30)
		art.size = Vector2(320,340)
		var composite := CanvasItemMaterial.new()
		composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		art.material = composite
		root.add_child(art)
		var label := Label.new()
		label.text = ["原版","细化 · 温暖毛色与接触影","细化 · 转头与眨眼"][index]
		label.position = Vector2(30+index*345,382)
		label.add_theme_color_override("font_color",Color("375b55"))
		label.add_theme_font_size_override("font_size",19)
		root.add_child(label)
	for frame in 5:
		await process_frame
		await RenderingServer.frame_post_draw
	for actor in actors:
		var image: Image = actor.viewport.get_texture().get_image()
		var visible_pixels := 0
		var clipped := 0
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x,y).a <= 0.05: continue
				visible_pixels += 1
				if x < 2 or y < 2 or x >= image.get_width()-2 or y >= image.get_height()-2: clipped += 1
		assert(visible_pixels > 500 and clipped == 0,"Corgi should render without clipping")
	var error := root.get_texture().get_image().save_png("res://docs/screenshots/v0.17/corgi-refinement.png")
	print("CORGI PREVIEW: ",error)
	quit(error)
