extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(430,590)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("eff4ef"))
	var panel = load("res://ui/settings_panel.tscn").instantiate()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.set_startup_state(true,true,"")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/startup-settings.png")
	quit()
