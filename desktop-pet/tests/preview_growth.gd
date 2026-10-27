extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	load("res://tests/test_crystal_growth.gd").run(self,check)
	if failures > 0 or DisplayServer.get_name() == "headless":
		quit(0 if failures == 0 else 1)
		return
	root.size = Vector2i(1260,690)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e9eee8"))
	var names := ["初见 / 0 小时", "相伴 / 20 小时", "熟悉 / 40 小时"]
	for index in range(3):
		var background := ColorRect.new()
		background.position = Vector2(index*420+12,66)
		background.size = Vector2(396,530)
		background.color = Color("203d40")
		root.add_child(background)
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
		view.set_process(false)
		view.scale = Vector2.ONE*1.2
		view.position = Vector2(index*420+210-220*1.2,330-133*1.2)
		view.actor.set_growth(index/2.0)
		view._process(1.1)
		_label(names[index],Vector2(index*420+26,22),22)
		_label("%d 枚粒子" % view.actor.particle_count(),Vector2(index*420+150,610),18)
	_label("晶纹与通透层次直接增强 · 成长仅让粒子逐渐增多、明亮 · 玉核形体保持不变",Vector2(86,650),19)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/crystal-growth-v0.10.png")
	quit()

func _label(text: String, point: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("284942"))
	root.add_child(label)
