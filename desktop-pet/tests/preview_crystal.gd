extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1260,660)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e7ece6"))
	var headings := ["浅色桌面 / 温润玉光", "深色桌面 / 水晶透光", "透明度检视 / 背景可透见"]
	for index in range(3):
		var background := ColorRect.new()
		background.position = Vector2(index*420+12,65)
		background.size = Vector2(396,530)
		background.color = Color("e9e5dc") if index == 0 else Color("223d40")
		root.add_child(background)
		if index == 2:
			for row in range(18):
				for col in range(14):
					var square := ColorRect.new()
					square.position = background.position+Vector2(col*28,row*28)
					square.size = Vector2(28,28)
					square.color = Color("506765") if (row+col)%2 == 0 else Color("748782")
					root.add_child(square)
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
		view.set_process(false)
		view.scale = Vector2.ONE*1.2
		view.position = Vector2(index*420+210-220*1.2,325-133*1.2)
		view._process(1.1)
		var label := Label.new()
		label.text = headings[index]
		label.position = Vector2(index*420+25,22)
		label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",Color("284942"))
		root.add_child(label)
	var note := Label.new()
	note.text = "半透明切面 · 青玉到冰蓝渐变 · 内层晶面 · 暖金内光 · 掠过表面的折光高光"
	note.position = Vector2(120,616)
	note.add_theme_font_size_override("font_size",21)
	note.add_theme_color_override("font_color",Color("284942"))
	root.add_child(note)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/jade-crystal-material.png")
	quit()
