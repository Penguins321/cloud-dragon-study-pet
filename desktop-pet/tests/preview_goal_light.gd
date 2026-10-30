extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + detail)

func run() -> void:
	load("res://tests/test_goal_light.gd").run(self,check)
	if failures > 0 or DisplayServer.get_name() == "headless":
		quit(0 if failures == 0 else 1)
		return
	await _verify_light_pixels()
	if failures > 0:
		quit(1)
		return
	root.size = Vector2i(1100,760)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e9e5dc"))
	var times := [0.15,0.5,0.85,1.3,1.8,3.2]
	var titles := ["轻轻回应", "一点柔光", "短短光粒", "柔光散去", "安静下来", "回到悬浮"]
	for index in range(6):
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
		view.set_process(false)
		view.position = Vector2(index%3*365+6,index/3*375+146)
		view.scale = Vector2.ONE*0.66
		view.select_action(&"breath")
		view.player.advance(times[index])
		view.actor.advance_pose(times[index])
		var effect = load("res://pet/effects/goal_light.gd").new()
		root.add_child(effect)
		effect.set_frame(view.position+view.map_skin_point(view.skin.breath_anchor),0.66,times[index],"")
		var label := Label.new()
		label.text = titles[index]
		label.position = Vector2(index%3*365+105,index/3*375+330)
		label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",Color("536453"))
		root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/jade-greeting-light.png")
	quit()

func _verify_light_pixels() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var effect = load("res://pet/effects/goal_light.gd").new()
	viewport.add_child(effect)
	var visible_pixels := 0
	var outside := 0
	for time in [0.16, 0.35, 0.5, 0.7, 1.0, 1.5, 1.85]:
		effect.set_frame(Vector2(128, 128), 1.0, time, "这段文本绝不能绘制")
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered: Image = viewport.get_texture().get_image()
		var regions: Array = effect.get_regions()
		for y in rendered.get_height():
			for x in rendered.get_width():
				if rendered.get_pixel(x, y).a <= 0.001:
					continue
				visible_pixels += 1
				var covered := false
				for polygon in regions:
					if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
						covered = true
						break
				if not covered:
					outside += 1
	check(visible_pixels > 0, "breath light renders visible pixels")
	check(outside == 0, "native regions cover every rendered light pixel")
	viewport.free()
