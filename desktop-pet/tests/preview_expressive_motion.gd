extends SceneTree

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("Expressive preview timed out"); quit(1))
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1120,400)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("153b3c"))
	var directory := ProjectSettings.globalize_path("res://../.tools/expressive/frames").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	var rigs: Array[Node2D] = []
	var actions := ["greet", "nuzzle", "startle", "doze"]
	var names := ["招手 · 轻轻致意", "亲昵 · 靠近回应", "惊喜 · 轻盈回弹", "打盹 · 点头休憩"]
	for index in range(4):
		var rig = load("res://pet/skins/warm_jade/view.tscn").instantiate()
		root.add_child(rig)
		rig.process_mode = Node.PROCESS_MODE_DISABLED
		rig.scale = Vector2.ONE*0.53
		rig.position = Vector2(140+index*280,225)-Vector2(220,133)*rig.scale
		rig.set_render_mode("3d")
		rig.get_node("AnimationPlayer").callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		rig.get_node("AnimationPlayer").play(actions[index])
		rigs.append(rig)
		var label := Label.new()
		label.text = names[index]
		label.position = Vector2(index*280+24,28)
		label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",Color("e4efe3"))
		root.add_child(label)
	var note := Label.new()
	note.text = "实际 GPU 渲染 · 动作阶段按归一化时间对照，实际播放各有节奏"
	note.position = Vector2(24,365)
	note.add_theme_color_override("font_color",Color("a4c4b8"))
	root.add_child(note)
	for frame in range(73):
		for rig in rigs:
			var player: AnimationPlayer = rig.get_node("AnimationPlayer")
			player.seek(player.current_animation_length*float(frame)/72.0,true)
			rig.advance_pose(1.0/15.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(directory.path_join("frame-%03d.png" % frame))
		if error != OK:
			printerr("Cannot save expressive preview: ", error)
			quit(1)
			return
	print("EXPRESSIVE GPU PREVIEW: 73 frames")
	quit()
