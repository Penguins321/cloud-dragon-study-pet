extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(480,660)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("eff4ef"))
	var panel = load("res://ui/settings_panel.tscn").instantiate()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.set_startup_state(true,true,"")
	panel.set_icon_awareness_state(true,"靠近图标时轻轻转向，遮挡时自动让开。")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/settings-jade-v0.11.png")
	root.size = Vector2i(360,420)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/settings-jade-compact-v0.11.png")
	root.size = Vector2i(480,660)
	panel.set_startup_state(false,false,"请在导出的程序中设置自启动，开发模式不修改系统配置。")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/settings-jade-disabled-v0.11.png")
	quit()
