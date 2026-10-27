extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	if DisplayServer.get_name() == "headless" or directory.is_empty():
		printerr("Frame measurement needs real rendering and isolated CLOUD_DRAGON_DATA_DIR")
		quit(1)
		return
	OS.set_environment("CLOUD_DRAGON_DATA_DIR", directory.path_join(str(Time.get_ticks_usec())))
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	var fire_spirit := OS.get_cmdline_user_args().has("--fire-spirit")
	var element := "flame" if fire_spirit else ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--element="): element = argument.trim_prefix("--element=")
	if element in ["flame","lightning","snow"]:
		app._set_appearance(element,{"flame":"ember","lightning":"violet","snow":"ice"}[element])
		app.companionship.restore(144000.0)
		app._apply_growth()
		if not OS.get_cmdline_user_args().has("--no-preview"): app._show_settings()
		if OS.get_cmdline_user_args().has("--hold-mask"):
			app.pet.geometry_changed.disconnect(app._update_geometry)
	await create_timer(3.0).timeout
	var breath := OS.get_cmdline_user_args().has("--breath")
	if breath:
		app.pet.select_action(&"breath")
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in range(360):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		samples.append(float(now - previous) / 1000.0)
		previous = now
	var total := 0.0
	for value in samples:
		total += value
	samples.sort()
	print("ANIMATION_METRICS ", JSON.stringify({
		"mode": element+"-with-preview" if not element.is_empty() else ("breath" if breath else "idle"), "frames": samples.size(), "seconds": total / 1000.0,
		"settings_preview":not OS.get_cmdline_user_args().has("--no-preview"),
		"average_fps": 360000.0 / total,
		"p95_frame_ms": samples[341], "maximum_frame_ms": samples[-1]
	}))
	quit()
