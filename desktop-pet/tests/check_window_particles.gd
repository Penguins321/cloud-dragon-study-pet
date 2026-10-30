extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	check(app.settings_window.borderless and app.panel_window.borderless,"Application windows need shared custom chrome")
	check(app.settings_window.find_child("WindowChrome",true,false) != null,"Settings needs jade header")
	check(app.panel._details_dialog.borderless,"Maintenance dialog needs shared chrome")
	app.settings.appearance_preview.set_render_mode("2d")
	app.settings.appearance_preview.set_skin("corgi")
	app.settings.appearance_preview.set_skin("warm_jade")
	check(app.settings.appearance_preview.actor.render_mode == "2d","Preview replacement preserves fallback renderer")
	app.settings.appearance_preview.set_render_mode("3d")
	check(app.settings.appearance_preview.actor.render_mode == "3d","Preview returns to shared 3D renderer")
	var rig = app.pet.actor
	var motes = load("res://pet/energy_motes_3d.gd").new()
	rig.set_growth(0.0)
	rig.phase = 1.25
	motes.sync(rig)
	var near_size := 0.0
	var far_size := 1.0
	var max_depth := -10.0
	var min_depth := 10.0
	for field in motes.fields:
		for i in field.multimesh.visible_instance_count:
			var t: Transform3D = field.multimesh.get_instance_transform(i)
			max_depth = maxf(max_depth,t.origin.z)
			min_depth = minf(min_depth,t.origin.z)
			near_size = maxf(near_size,t.basis.x.length())
			far_size = minf(far_size,t.basis.x.length())
	print("DEPTH ",min_depth," ",max_depth," SIZE ",far_size," ",near_size)
	check(max_depth > 0.8 and min_depth < -0.8,"Motes must pass in front of and behind crystal volume")
	check(near_size-far_size > 0.05,"Near and far motes need distinct projected sizes")
	app._show_settings()
	await process_frame
	var chrome: Control = app.settings_window.find_child("WindowChrome",true,false)
	for level in range(4):
		app._apply_font_level(level)
		await process_frame
		check(chrome.size.y <= app.settings.offset_top,"Large header fonts must not overlap window content")
	for button in chrome.find_children("*","Button",true,false):
		if button.text == "−": button.pressed.emit()
	await process_frame
	check(app.settings_window.mode == Window.MODE_MINIMIZED,"Custom minimize button minimizes its host")
	app.settings_window.mode = Window.MODE_WINDOWED
	app.settings_window.close_requested.emit()
	check(not app.settings_window.visible,"Window close preserves hide behavior")
	app.panel._open_details()
	await process_frame
	check(app.panel._details_goal.get_global_rect().position.y >= 52,"Dialog body stays below custom header")
	var dialog_chrome: Control = app.panel._details_dialog.find_child("WindowChrome",true,false)
	for button in dialog_chrome.find_children("*","Button",true,false):
		if button.text == "×": button.pressed.emit()
	check(not app.panel._details_dialog.visible,"Dialog header close dismisses modal")
	motes.free()
	app.free()
	print("WINDOW/PARTICLES: ",failures," failures")
	quit(0 if failures == 0 else 1)
