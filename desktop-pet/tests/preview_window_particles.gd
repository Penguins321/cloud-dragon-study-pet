extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app._show_settings()
	app.settings.appearance_preview.set_growth(1.0)
	var scroll: Node = app.settings.appearance_preview.get_parent()
	while not scroll is ScrollContainer: scroll = scroll.get_parent()
	await process_frame
	scroll.scroll_vertical = 405
	for i in range(15):
		await process_frame
		await RenderingServer.frame_post_draw
	app.settings_window.get_texture().get_image().save_png("res://../.tools/jade-settings-chrome.png")
	app._show_plan()
	app.panel._open_details()
	for i in range(5):
		await process_frame
		await RenderingServer.frame_post_draw
	app.panel._details_dialog.get_texture().get_image().save_png("res://../.tools/jade-dialog-chrome.png")
	var dialog: Window = app.panel._details_dialog
	var chrome: Control = dialog.find_child("WindowChrome",true,false)
	print("DIALOG BODY ",app.panel._details_goal.get_global_rect()," HEADER ",chrome.get_global_rect())
	assert(app.panel._details_goal.get_global_rect().position.y >= 40)
	app.free()
	quit()
