extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1200,800)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("19383b"))
	var rigs: Array[Node2D] = []
	for index in range(2):
		var rig = load("res://pet/skins/warm_jade/view.tscn").instantiate()
		root.add_child(rig)
		rig.process_mode = Node.PROCESS_MODE_DISABLED
		rig.position = Vector2(300+index*600,440)-Vector2(220,133)*1.3
		rig.scale = Vector2.ONE*1.3
		rig.set_appearance("jade","jade")
		rig.set_growth(float(index))
		rig.set_render_mode("3d")
		rig.phase = 1.25
		rig.sync_pose()
		rig._refresh_effects()
		rigs.append(rig)
	for i in range(4):
		for rig in rigs: rig._refresh_effects()
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/production-3d.png")
	quit()
