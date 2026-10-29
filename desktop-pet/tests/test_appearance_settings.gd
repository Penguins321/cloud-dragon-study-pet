extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var panel = preload("res://ui/settings_panel.tscn").instantiate()
	var window := Window.new()
	window.size = Vector2i(360,640)
	root.add_child(window)
	window.add_child(panel)
	window.show()
	panel.size = Vector2(360,640)
	var emissions: Array = []
	panel.appearance_requested.connect(func(style: String, color: String): emissions.append([style,color]))
	await process_frame
	await process_frame
	_check(panel._style_buttons.size() == 5 and not panel._style_buttons.has("flame"),"Crystal materials remain available; fire is removed")
	_check(panel._color_buttons.size() == 7 and not panel._color_buttons.has("gold") and not panel._color_buttons.has("bluefire"),"Retired gold and blue-fire entries must be removed")
	panel.set_appearance("glass","rose")
	_check(emissions.is_empty(),"Restoring appearance must not emit a user request")
	_check(panel._appearance_title.text == "澄透水晶 · 蔷薇","Selected appearance names must be shown")
	_check(panel._style_buttons.glass.button_pressed,"Restored style must be selected")
	_check(panel._color_buttons.rose.button_pressed,"Restored color must be selected")
	panel._color_buttons.ice.pressed.emit()
	_check(emissions == [["glass","ice"]],"One color click must request the selected pair once")
	panel._style_buttons.opal.pressed.emit()
	_check(emissions.size() == 2 and emissions[1] == ["opal","ice"],"Style click must preserve color")
	panel._color_buttons.ember.pressed.emit()
	_check(emissions[-1] == ["opal","ember"],"Colors still apply to the selected crystal")
	panel._style_buttons.lightning.pressed.emit()
	_check(emissions[-1] == ["lightning","ember"] and panel.appearance_preview.actor.appearance_style == "lightning","Lightning selects its own renderer")
	panel._style_buttons.snow.pressed.emit()
	_check(emissions[-1] == ["snow","ember"] and panel.appearance_preview.actor.appearance_style == "snow","Snow selects its own renderer")
	await process_frame
	await process_frame
	_check(panel._sections.size.x <= panel._sections.get_parent().size.x,"Cards must not overflow the horizontal scroll area")
	_check(panel.get_combined_minimum_size().x <= 360,"Settings content must fit a 360 px window")
	var preview = panel.appearance_preview
	_check(preview.actor != null,"Preview must instantiate the real jade rig")
	await create_timer(0.08).timeout
	var before: float = preview.actor.phase
	await create_timer(0.08).timeout
	_check(preview.actor.phase > before,"Visible preview must animate")
	panel.hide()
	await process_frame
	before = preview.actor.phase
	await create_timer(0.08).timeout
	_check(is_equal_approx(preview.actor.phase,before),"Hidden panel must suspend preview animation")
	_check(preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden preview must disable rendering")
	panel.show()
	window.hide()
	await process_frame
	before = preview.actor.phase
	await create_timer(0.08).timeout
	_check(is_equal_approx(preview.actor.phase,before),"Hidden containing window must suspend preview animation")
	window.queue_free()
	await process_frame
	print("Appearance settings checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
