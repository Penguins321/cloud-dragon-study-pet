extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("WARM_JADE_LIVE_ICON_CHECK") != "1":
		printerr("Live read-only desktop check requires explicit test opt-in")
		quit(1)
		return
	var reader = load("res://desktop/icon_awareness.gd").new()
	root.add_child(reader)
	reader.cache_directory = OS.get_environment("WARM_JADE_TEST_CACHE")
	if reader.cache_directory.is_empty(): reader.cache_directory = ProjectSettings.globalize_path("res://../.tools/icon-reader-runtime")
	reader.set_active(true)
	await create_timer(6.0).timeout
	var pid: int = reader._pid
	var count: int = reader.icons.size()
	var okay: bool = pid > 0 and reader.available and reader.fresh(Time.get_ticks_msec())
	var path: String = reader._snapshot_path
	reader.set_enabled(false)
	await create_timer(0.3).timeout
	okay = okay and not OS.is_process_running(pid) and not FileAccess.file_exists(path)
	if okay: print("LIVE ICON READER: ",count," icon rectangles; actual Godot background launch, fresh snapshot, disable and child/cache cleanup passed")
	else: printerr("FAIL: live Godot icon reader lifecycle, status: ",reader.status)
	reader.free()
	quit(0 if okay else 1)
