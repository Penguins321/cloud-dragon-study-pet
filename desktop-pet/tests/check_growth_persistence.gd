extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	if directory.is_empty():
		printerr("Growth integration check requires isolated data")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("preferences.cfg")
	var saved := ConfigFile.new()
	saved.set_value("companionship","active_seconds",72000.0)
	saved.set_value("sentinel","untouched","keep")
	if saved.save(path) != OK:
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_process(false)
	var okay: bool = app.companionship.active_seconds == 72000.0 and app.pet.actor.particle_count() == 50
	app._process(1.0)
	app._save_preferences()
	saved.load(path)
	okay = okay and saved.get_value("companionship","active_seconds") == 72001.0 and saved.get_value("sentinel","untouched") == "keep"
	app.pet.set_active(false)
	app._process(1.0)
	okay = okay and app.companionship.active_seconds == 72001.0
	app.pet.set_active(true)
	app._last_growth_tick = Time.get_ticks_msec()-5000
	app._process(0.1)
	okay = okay and app.companionship.active_seconds == 72001.0
	if not okay: printerr("FAIL: actual preference restore/save, untouched keys or hidden/suspend growth")
	else: print("Growth persistence: actual app restores 20h/50 motes, saves time, preserves unrelated settings, ignores hidden/suspend time")
	app.free()
	quit(0 if okay else 1)
