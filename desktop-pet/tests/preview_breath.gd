extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output := OS.get_environment("CLOUD_DRAGON_PREVIEW_DIR")
	var data := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	if output.is_empty() or data.is_empty() or DisplayServer.get_name() == "headless":
		printerr("Breath preview requires real rendering, output directory and isolated data")
		quit(1)
		return
	OS.set_environment("CLOUD_DRAGON_DATA_DIR",data.path_join(str(Time.get_ticks_usec())))
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if app.pet.skin == null:
		printerr("Breath preview could not acquire its isolated instance scope")
		quit(1)
		return
	app.set_process(false)
	app.pet.set_process(false)
	app.pet.set_display_scale(0.75)
	app.pet.select_action(&"breath")
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e7f0ef"))
	for frame in range(168):
		var fraction := frame/167.0
		app.pet.player.seek(5.6*fraction,true)
		app.pet.actor.phase = TAU*2.0*fraction
		app.pet.actor.head_time = 3.1+5.6*fraction
		app.pet.actor.advance_pose(0.0)
		app._update_geometry()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(output.path_join("frame-%03d.png" % frame))
		if frame in [18,27,45,90]:
			image.save_png(output.path_join("breath-phase-%03d.png" % frame))
	print("BREATH PREVIEW FRAMES SAVED ",output)
	quit()
