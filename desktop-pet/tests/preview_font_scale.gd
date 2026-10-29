extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(480,720)
	root.transparent_bg = false
	var panel = load("res://ui/settings_panel.tscn").instantiate()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for level in range(4):
		panel.set_font_level(level)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.tools/font-level-%d.png" % level)
		print("FONT level ",level," panel minimum ",panel.get_combined_minimum_size())
	quit()
