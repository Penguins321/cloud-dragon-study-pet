extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var panel = load("res://ui/settings_panel.tscn").instantiate()
	root.add_child(panel)
	check(panel.has_method("set_skin_selection"), "Settings must offer companion selection")
	if failures:
		panel.free()
		quit(1)
		return
	var requests: Array = []
	panel.skin_requested.connect(func(id: String): requests.append(id))
	check(panel._skin_buttons.size() == 4, "Four companions are available")
	for id in ["corgi", "duck", "jellyfish"]:
		panel.set_skin_selection(id)
		check(requests.is_empty(), "Restoring companion must not emit user changes")
		check(panel._skin_buttons[id].button_pressed, "Selected companion button matches " + id)
		check(not panel._jade_controls.visible, "Animals hide crystal-only material and color controls")
		check(panel.renderer_button.disabled, "Animal renderer cannot be changed to 2D")
		check(panel.renderer_status.text.contains("3D"), "Animal renderer requirement is explained")
		var skin = load("res://pet/skin_catalog.gd").load_skin(id)
		check(not panel._motion_buttons.is_empty(), "Animal has previewable actions")
		for action in panel._motion_buttons:
			check(skin.action_map.has(action), "Preview offers an implemented action for " + id)
		check(panel.appearance_preview._skin_id == id, "Live preview follows selected companion")
		var preview = panel.appearance_preview
		var before: float = preview._player.current_animation_position
		preview._process(0.04)
		check(preview._player.current_animation_position > before, "Visible animal preview advances animation")
		panel.hide()
		before = preview._player.current_animation_position
		preview._process(0.04)
		check(is_equal_approx(preview._player.current_animation_position,before), "Hidden animal preview pauses animation")
		panel.show()
	panel._skin_buttons.corgi.pressed.emit()
	check(requests == ["corgi"], "One companion click emits one selection")
	var actions: Array = []
	panel.action_preview_requested.connect(func(action: StringName): actions.append(action))
	var first_action: StringName = panel._motion_buttons.keys()[0]
	panel._motion_buttons[first_action].pressed.emit()
	check(actions == [first_action], "Action button emits its selected companion's semantic action")
	panel.set_font_level(3)
	panel.set_skin_selection("duck")
	for button in panel._motion_buttons.values():
		check(button.get_theme_font_size("font_size") == 22, "Switching companions preserves the chosen action font size")
	panel.set_skin_selection("warm_jade")
	check(panel._jade_controls.visible and not panel.renderer_button.disabled, "Returning to jade restores material controls")
	check(panel._motion_buttons.size() == 23, "Jade offers its original nineteen and four expressive actions")
	panel.set_appearance("glass", "rose")
	check(panel._appearance_title.text == "澄透水晶 · 蔷薇", "Jade appearance selection remains intact")
	panel.free()
	print("COMPANION UI: ", failures, " failures")
	quit(0 if failures == 0 else 1)
