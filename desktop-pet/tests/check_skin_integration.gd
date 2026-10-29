extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	create_timer(40).timeout.connect(func(): printerr("Skin integration timed out"); quit(1))
	call_deferred("run")

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Isolated data directory required")
		quit(1)
		return
	var scene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	if not app.has_method("_set_skin"):
		printerr("FAIL: application must support persisted companion selection")
		app.free()
		quit(1)
		return
	var original: Dictionary = app.plan.to_dict()
	app._set_scale(0.75)
	app._set_appearance("opal", "violet")
	app._set_renderer_mode("2d")
	app._set_companion_mode("quiet")
	var original_actor_id: int = app.pet.actor.get_instance_id()
	for id in ["corgi", "duck", "jellyfish"]:
		app.settings.skin_requested.emit(id)
		check(app.pet.skin.id == StringName(id), "UI selects " + id)
		check(app.settings.appearance_preview.actor.get_script() == app.pet.actor.get_script(), "Preview uses matching renderer")
		check(app.plan.to_dict() == original, "Skin switch preserves learning plan")
		check(app.pet.scale == Vector2.ONE * 0.75, "Skin switch preserves display scale")
		app.pet.select_action(&"walk")
		app.pet.play_action(&"dragging")
		app.pet.play_action(&"look")
		check(app.pet.current_action == &"dragging", "Dragging retains priority")
		app.pet.play_action(&"idle")
	app._save_preferences()
	app._recover_skin_renderer("stale actor failure", original_actor_id)
	check(app.selected_skin == "jellyfish", "An old actor failure cannot replace the newly selected companion")
	app.free()
	await process_frame
	app = scene.instantiate()
	root.add_child(app)
	check(app.pet.skin.id == &"jellyfish", "Skin choice survives application restart")
	check(app.companion_mode == "quiet", "Companion settings survive skin restart")
	app._set_skin("warm_jade")
	check(app.pet.actor.appearance_style == "opal" and app.pet.actor.appearance_color == "violet", "Returning to jade restores material and color")
	check(app.renderer_mode == "2d", "Animal selection preserves jade renderer preference")
	app._set_skin("../unknown")
	check(app.pet.skin.id == &"warm_jade", "Unknown skin falls back to jade")
	app.free()
	await process_frame
	print("SKIN INTEGRATION: ", failures, " failures")
	quit(0 if failures == 0 else 1)
