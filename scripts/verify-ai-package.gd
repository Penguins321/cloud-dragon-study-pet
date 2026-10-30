extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Isolated data directory required")
		quit(1)
		return
	var failures := 0
	for path in ["res://ai_private.cfg","res://ai_private.cfg.tmp","res://ai_memory.json","res://ai_memory.json.tmp"]:
		if FileAccess.file_exists(path):
			failures += 1
			printerr("Private AI file unexpectedly present in exported package")
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if app.ai_brain == null or app.chat_panel == null or app.ai_bubble == null: failures += 1
	app._set_skin("corgi")
	app._show_ai_chat()
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	if app.chat_window.get_texture().get_image().is_empty(): failures += 1
	app.free()
	await process_frame
	print("AI PACKAGE: ",failures," failures")
	quit(0 if failures == 0 else 1)
