extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	var requests: Array[String] = []
	app.desktop.quit_requested.connect(func(): requests.append("quit"))
	app.companionship.active_seconds = 12345.0
	app.desktop.hide_pet()
	var okay: bool = requests.is_empty()
	if app.desktop._tray != null:
		okay = okay and root.mode == Window.MODE_MINIMIZED
		if NativeMenu.has_feature(NativeMenu.FEATURE_POPUP_MENU): okay = okay and app.desktop._menu.is_native_menu()
	root.close_requested.emit()
	var saved := ConfigFile.new()
	okay = okay and requests == ["quit"] and saved.load(app.preferences_path) == OK
	okay = okay and saved.get_value("companionship","active_seconds",0) == 12345.0
	if okay: print("SYSTEM CLOSE: hide remains reversible; closing the minimized app requests quit and saves companionship")
	else: printerr("FAIL: minimized close did not quit/save correctly")
	quit(0 if okay else 1)
