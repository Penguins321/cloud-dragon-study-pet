extends SceneTree
## Run with the full Godot engine --main-pack <exported exe> --script <absolute path>.
var failures := 0

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("Package verification timed out"); quit(1))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Isolated data directory required")
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	for id in ["corgi", "duck", "jellyfish"]:
		app._set_skin(id)
		check(app.selected_skin == id, "Export selects " + id)
		check(app.pet.actor.native_player != null, "Export includes native skeletal clips for " + id)
		app.pet.select_action(&"jump")
		for frame in 12: await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = app.pet.actor.viewport.get_texture().get_image()
		var opaque := 0
		if image:
			for y in range(0, image.get_height(), 4):
				for x in range(0, image.get_width(), 4):
					if image.get_pixel(x,y).a > 0.1: opaque += 1
		check(opaque > 100, "Export renders textured animal " + id)
	app._set_skin("warm_jade")
	check(app.pet.CLICK_ACTIONS.size() == 23, "Export includes all jade actions")
	app.free()
	await process_frame
	print("COMPANION PACKAGE: ", failures, " failures")
	quit(0 if failures == 0 else 1)
