extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app._set_appearance("jade","jade")
	app._set_renderer_mode("3d")
	app.pet.set_process(false)
	var actor = app.pet.actor
	var clip_ok := true
	var empty_background := true
	var maximum_regions := 0
	for growth in [0.0,1.0]:
		actor.set_growth(growth)
		for action in app.pet.CLICK_ACTIONS:
			app.pet.select_action(action)
			for phase in [0.0,0.5,0.95]:
				app.pet.player.seek(app.pet.player.current_animation_length*phase,true)
				actor.phase = phase*3
				actor.sync_pose()
				for i in range(2):
					actor._refresh_effects()
					await process_frame
					await RenderingServer.frame_post_draw
				var image: Image = actor._view_3d.viewport.get_texture().get_image()
				empty_background = empty_background and image.get_pixel(0,0).a < 0.001
				var regions: Array = actor.render_regions()
				maximum_regions = maxi(maximum_regions,regions.size())
				for y in range(4,image.get_height(),12):
					for x in range(4,image.get_width(),12):
						if image.get_pixel(x,y).a < 0.04: continue
						var point := Vector2(x-100,y-360)
						var covered := false
						for region in regions:
							if Geometry2D.is_point_in_polygon(point,region):
								covered = true
								break
						if clip_ok and not covered: printerr("3D CLIP ",action," ",growth," ",point)
						clip_ok = clip_ok and covered
	check(empty_background,"3D viewport has opaque background")
	check(clip_ok,"3D action pixels escape desktop clipping masks")
	check(maximum_regions==3,"3D crystal masks must contain only the three stones; actual "+str(maximum_regions))
	check(actor._use_3d,"3D unexpectedly fell back during action test")
	app._set_renderer_mode("2d")
	check(not actor._use_3d,"2D fallback toggle did not deactivate 3D")
	app.free()
	print("PRODUCTION 3D ACTION/ALPHA CHECK: ",failures," failures")
	quit(0 if failures == 0 else 1)
