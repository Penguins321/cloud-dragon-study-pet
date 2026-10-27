extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Growth rendering check requires isolated data")
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if app.pet.skin == null:
		quit(1)
		return
	app.set_process(false)
	app.pet.set_process(false)
	app.pet.actor.set_growth(1.0)
	var coverage = load("res://tests/smoke_runner.gd")
	for size in [0.5,1.25]:
		app.pet.set_display_scale(size)
		for action in app.pet.CLICK_ACTIONS:
			app.pet.select_action(action)
			app.pet.player.advance(0.3)
			var duration: float = app.pet.player.current_animation_length
			for fraction in [0.2,0.5,0.9]:
				app.pet.player.seek(duration*fraction,true)
				app.pet.actor.advance_pose(0.1)
				app._update_geometry()
				await process_frame
				await RenderingServer.frame_post_draw
				if not coverage._rendered_pixels_inside_region(root):
					printerr("Mature growth clipped: ",size," / ",action," / ",fraction)
					quit(1)
					return
	print("Mature growth: all ",app.pet.CLICK_ACTIONS.size()," actions at 50%/125%, 3 phases each, actual GPU alpha fits native region")
	quit()
