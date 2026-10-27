extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Use an isolated CLOUD_DRAGON_DATA_DIR")
		quit(1)
		return
	var scene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	check(app.has_method("_set_appearance"),"main connects appearance to saving")
	if not app.has_method("_set_appearance"):
		app.free()
		quit(1)
		return
	app.pet.select_action(&"jump")
	var actor = app.pet.actor
	app.settings.appearance_requested.emit("opal","violet")
	check(app.pet.actor == actor and app.pet.current_action == &"jump","switching appearance preserves current action")
	check(app.pet.actor.appearance_style == "opal" and app.pet.actor.appearance_color == "violet","settings choice applies to desktop")
	var saved := ConfigFile.new()
	check(saved.load(app.preferences_path) == OK,"appearance saves immediately")
	check(saved.get_value("pet","appearance_style","") == "opal" and saved.get_value("pet","appearance_color","") == "violet","saved choice contains both identifiers")
	app.settings.appearance_requested.emit("flame","bluefire")
	app.companionship.restore(144000.0)
	app._apply_growth()
	check(app.settings.appearance_preview.actor.flame_particle_count() == app.pet.actor.flame_particle_count(),"preview matches current growth density")
	app.free()
	await process_frame
	app = scene.instantiate()
	root.add_child(app)
	check(app.pet.actor.appearance_style == "flame" and app.pet.actor.appearance_color == "bluefire","restart restores selected appearance")
	check(app.settings.appearance_preview.actor.appearance_color == "bluefire","restart restores matching settings preview")
	app._set_appearance("unknown","unknown")
	check(app.pet.actor.appearance_style == "jade" and app.pet.actor.appearance_color == "jade","invalid choices restore safe default")
	app.free()
	print("Appearance persistence failures: ",failures)
	quit(0 if failures == 0 else 1)
