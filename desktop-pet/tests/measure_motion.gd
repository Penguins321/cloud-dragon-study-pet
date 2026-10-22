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
	root.add_child(load("res://main.tscn").instantiate())
	await create_timer(3.0).timeout
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
		"frames": samples.size(), "seconds": total / 1000.0,
		"average_fps": 360000.0 / total,
		"p95_frame_ms": samples[341], "maximum_frame_ms": samples[-1]
	}))
	quit()
