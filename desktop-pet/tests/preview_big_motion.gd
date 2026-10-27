extends SceneTree

var views: Array[Node2D] = []
var elapsed := 0.0
var _capturing := false
const ACTIONS := [&"walk", &"laugh", &"jump", &"hop", &"spin", &"sway"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1200,760)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e7ece6"))
	var titles := ["行走 · 交替踏步", "捧腹大笑 · 欢快颤动", "跳跃 · 蓄力腾空", "连跳 · 轻盈三连", "回旋 · 玉核转动", "摇摆 · 左右荡漾"]
	for index in range(ACTIONS.size()):
		var origin := Vector2((index%3)*400,(index/3)*380)
		var background := ColorRect.new()
		background.position = origin+Vector2(8,8)
		background.size = Vector2(384,364)
		background.color = Color("e9e5dc") if index%2 == 0 else Color("294644")
		root.add_child(background)
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
		view.set_process(false)
		view.scale = Vector2.ONE*0.72
		view.position = origin+Vector2(200,250)-Vector2(220,133)*0.72
		view.select_action(ACTIONS[index])
		views.append(view)
		var label := Label.new()
		label.text = titles[index]
		label.position = origin+Vector2(26,20)
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",Color("284942") if index%2 == 0 else Color("edf4db"))
		root.add_child(label)
	if OS.get_cmdline_user_args().has("--snapshot"):
		_capturing = true
		var fractions := [0.28,0.38,0.49,0.5,0.16,0.3]
		for index in range(views.size()):
			var duration: float = views[index].player.current_animation_length
			for step in range(ceili(duration*fractions[index]*60)):
				views[index]._process(1.0/60)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/big-motion-v0.11.png")
		quit()

func _process(delta: float) -> bool:
	if _capturing: return false
	elapsed += delta
	for index in range(views.size()):
		views[index]._process(delta)
		if views[index].current_action == &"idle": views[index].select_action(ACTIONS[index])
	return false
