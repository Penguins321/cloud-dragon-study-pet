extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(560,900)
	root.transparent_bg = false
	var panel = load("res://ui/plan_panel.tscn").instantiate()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.render_plan({"goal":"全页面字号同步检查","current_id":"one","tasks":[{"id":"one","title":"学习计划与确认弹窗均使用老年人档位","completed":false}]})
	panel.set_font_level(3)
	for page in ["plan","editor","confirm"]:
		if page == "editor": panel._open_editor()
		if page == "confirm": panel._request_replace()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.tools/font-sync-%s.png" % page)
	quit()
