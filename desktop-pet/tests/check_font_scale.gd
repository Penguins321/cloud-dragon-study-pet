extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var scene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	if not app.has_method("_set_font_level"):
		printerr("Font level integration missing")
		app.free()
		quit(1)
		return
	var base: int = app.settings.startup_status.get_theme_font_size("font_size")
	var plan_base: int = app.panel.current_label.get_theme_font_size("font_size")
	var editor_base: int = app.panel._titles_input.get_theme_font_size("font_size")
	var dialog_base: int = app.panel._confirm.get_ok_button().get_theme_font_size("font_size")
	var menu_base: int = app.desktop._menu.get_theme_font_size("font_size")
	check(app.font_level == 0,"default is normal")
	check(app.settings.font_buttons.size() == 4,"four font levels")
	for level in range(4):
		app.settings.font_level_requested.emit(level)
		check(app.font_level == level,"selection updates level")
		check(app.settings.font_buttons[level].button_pressed,"selected level highlighted")
		if level > 0:
			check(app.panel.current_label.get_theme_font_size("font_size") > plan_base,"plan page shares the selected font level")
			check(app.panel._titles_input.get_theme_font_size("font_size") > editor_base,"editor shares the selected font level")
			check(app.panel._confirm.get_ok_button().get_theme_font_size("font_size") > dialog_base,"confirmation dialog shares font level")
			check(app.settings.startup_status.get_theme_font_size("font_size") > base,"settings font grows")
			check(app.desktop._menu.get_theme_font_size("font_size") > menu_base,"menu font grows")
			check(not app.desktop._menu.is_native_menu(),"large menu is app rendered")
	var largest: int = app.settings.startup_status.get_theme_font_size("font_size")
	await process_frame
	check(app.settings_window.min_size.x >= ceili(app.settings.get_combined_minimum_size().x),"large font prevents clipping in narrow settings window")
	app._set_font_level(3)
	check(app.settings.startup_status.get_theme_font_size("font_size") == largest,"repeated apply never compounds")
	app.free()
	await process_frame
	app = scene.instantiate()
	root.add_child(app)
	check(app.font_level == 3,"restart restores level")
	check(app.settings.startup_status.get_theme_font_size("font_size") == largest,"restart restores font size")
	check(app.panel.current_label.get_theme_font_size("font_size") > plan_base,"restart restores plan page font")
	app._render()
	check(app.panel._list.get_child(0).get_theme_font_size("font_size") > editor_base,"new task rows inherit current font after refresh")
	app._set_font_level(0)
	check(app.settings.startup_status.get_theme_font_size("font_size") == base,"normal restores original sizes")
	check(app.desktop._menu.get_theme_font_size("font_size") == menu_base,"normal restores menu size")
	check(app.panel.current_label.get_theme_font_size("font_size") == plan_base,"normal restores plan font size")
	app._set_font_level(99)
	check(app.font_level == 0,"invalid preference falls back to normal")
	app.free()
	print("FONT SCALE failures: ",failures)
	quit(0 if failures == 0 else 1)
