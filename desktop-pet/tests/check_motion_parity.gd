extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var views: Array[Node2D] = []
	for mode in ["2d","3d"]:
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
		view.set_process(false)
		view.actor.set_appearance("jade","jade")
		view.actor.set_render_mode(mode)
		views.append(view)
	await process_frame
	await process_frame
	var maximum := 0.0
	var returns_idle := true
	var samples := 0
	for action in views[0].CLICK_ACTIONS:
		if action in [&"orbit",&"helix",&"cross_orbit",&"refract_turn"]: continue
		for view in views: view.select_action(action)
		for frame in range(480):
			for view in views: view._process(1.0/60)
			if frame%20 == 0:
				var renderer = views[1].actor._view_3d
				var camera: Camera3D = renderer.viewport.get_camera_3d()
				for index in range(3):
					var projected := camera.unproject_position(renderer.stones[index].global_position)-Vector2(100,360)
					maximum = maxf(maximum,projected.distance_to(views[0].actor.parts[index].origin))
					samples += 1
		returns_idle = returns_idle and views[0].current_action == &"idle" and views[1].current_action == &"idle"
	print("2D/3D MOTION PARITY: ",samples," center samples; max error ",maximum," px; idle return ",returns_idle)
	for view in views: view.free()
	quit(0 if maximum < 0.5 and returns_idle else 1)
