extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600,780)
	root.transparent_bg = false
	var titles := ["收息 · 能量收敛","悬浮 · 内光平稳","共鸣 · 能量凝聚","侧视 · 内部层次"]
	var rigs: Array[Node2D] = []
	for index in range(4):
		var background := ColorRect.new()
		background.position.x = index*400
		background.size = Vector2(400,780)
		background.color = Color("ecece3") if index < 2 else Color("19383b")
		root.add_child(background)
		var rig = load("res://pet/skins/warm_jade/rig.gd").new()
		root.add_child(rig)
		rig.position = Vector2(200+index*400,430)-Vector2(220,133)*1.30
		rig.scale = Vector2.ONE*1.30
		rig.set_appearance("jade","jade")
		rig.set_render_mode("3d")
		rig.phase = 1.25
		rig.energy = [-0.45,0.0,1.0,0.0][index]
		rig.sync_pose()
		rig._refresh_effects()
		if index == 3:
			var rotation := Basis(Vector3.UP,deg_to_rad(35))
			var center: Vector3 = rig._view_3d.stones[1].position
			for stone in rig._view_3d.stones:
				stone.position = center+rotation*(stone.position-center)
				stone.basis = rotation*stone.basis
		rigs.append(rig)
		var label := Label.new()
		label.text = titles[index]
		label.position = Vector2(index*400+55,65)
		label.add_theme_font_size_override("font_size",25)
		label.add_theme_color_override("font_color",Color("37544a") if index<2 else Color("e3ece1"))
		root.add_child(label)
	for frame in range(5):
		for rig in rigs: rig._view_3d.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/energy-core-v0.15.1.png")
	quit()
