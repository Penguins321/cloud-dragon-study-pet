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
	root.size = Vector2i(1100,760)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e9e5dc"))
	var times := [0.15,0.65,1.4,3.2,5.35,5.6]
	var titles := ["蓄光", "牵引", "成笺", "阅读", "收光", "回到悬浮"]
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
		effect.set_frame(view.position+view.map_skin_point(view.skin.breath_anchor),0.66,times[index],"学习单例模式")
		var label := Label.new()
		label.text = titles[index]
		label.position = Vector2(index%3*365+105,index/3*375+330)
		label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",Color("536453"))
		root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/jade-guiding-light.png")
	quit()
