extends SceneTree

# Diagnostic only: run sequentially on an idle desktop with isolated user data.
# Keep startup, warmup, steady idle and action transitions separate. Do not read
# pixels during sampling: GPU readback itself would distort the timings.
var started_usec := Time.get_ticks_usec()

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func():
		printerr("Frame profiling timed out")
		quit(1)
	)
	call_deferred("run")

func summarize(samples: Array[Dictionary]) -> Dictionary:
	var times: Array[float] = []
	var total := 0.0
	var long_frames: Array[Dictionary] = []
	for sample in samples:
		var elapsed: float = sample.wall_ms
		times.append(elapsed)
		total += elapsed
		if elapsed > 50.0:
			long_frames.append(sample)
	times.sort()
	return {"frames": times.size(), "fps": times.size()*1000.0/total,
		"p95_ms": times[ceili(times.size()*0.95)-1], "max_ms": times[-1],
		"over_50_ms": long_frames}

func run() -> void:
	var data_dir := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	if DisplayServer.get_name() == "headless" or data_dir.is_empty():
		printerr("Frame profiling requires a GPU and isolated CLOUD_DRAGON_DATA_DIR")
		quit(1)
		return
	var mode := "2d" if OS.get_cmdline_user_args().has("--2d") else "3d"
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if app.settings == null:
		printerr("Profiling application failed to initialize")
		app.free()
		quit(1)
		return
	app._set_appearance("jade", "jade")
	app._set_renderer_mode(mode)
	# Measure the companion itself; the first-run learning panel is a separate UI.
	app.panel_window.hide()
	app.settings_window.hide()
	app._set_companion_mode("quiet")
	if OS.get_cmdline_user_args().has("--eco"): app._set_performance("eco")
	if OS.get_cmdline_user_args().has("--focus"): app._focus_action("start",25)
	# Keep the model mature too: main.gd refreshes the actor from it every frame.
	app.companionship.restore(app.companionship.MATURE_SECONDS)
	app._apply_growth()
	await process_frame
	await RenderingServer.frame_post_draw
	var report := {"mode": mode, "adapter": RenderingServer.get_video_adapter_name(),
		"first_draw_ms": (Time.get_ticks_usec()-started_usec)/1000.0, "fps_cap": Engine.max_fps,
		"focus": app.focus_session.state == "running", "phases": {}}
	for phase in ["warmup", "idle", "actions"]:
		var samples: Array[Dictionary] = []
		var previous := Time.get_ticks_usec()
		for frame in range(120 if phase == "warmup" else 360):
			var switched := ""
			if phase == "actions" and frame % 90 == 0:
				switched = ["orbit", "helix", "cross_orbit", "refract_turn"][frame/90]
				app.pet.select_action(StringName(switched))
			await process_frame
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			samples.append({"frame": frame, "wall_ms": (now-previous)/1000.0,
				"process_ms": Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
				"switch": switched})
			previous = now
		report.phases[phase] = summarize(samples)
	var renderer_ok: bool = mode == "2d" or (app.pet.actor._use_3d and app.pet.actor._view_3d._validated)
	report["renderer_ok"] = renderer_ok
	report["particle_count"] = app.pet.actor.particle_count()
	var output := FileAccess.open(data_dir.path_join("frame-profile.json"), FileAccess.WRITE)
	if output == null:
		printerr("Cannot save frame profile")
		app.free()
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("FRAME PROFILE: ", JSON.stringify(report))
	app.free()
	await process_frame
	quit(0 if renderer_ok and report.particle_count == 72 else 1)
