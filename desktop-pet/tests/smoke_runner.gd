extends RefCounted

static func run(tree: SceneTree) -> void:
	tree.create_timer(30.0).timeout.connect(func(): printerr("SMOKE FAIL: validation timed out"); tree.quit(1))
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("Smoke tests require isolated CLOUD_DRAGON_DATA_DIR")
		tree.quit(1)
		return
	# Each run owns fresh data so repeat verification never mutates old progress.
	OS.set_environment("CLOUD_DRAGON_DATA_DIR", OS.get_environment("CLOUD_DRAGON_DATA_DIR").path_join(str(Time.get_ticks_usec())))
	var app = load("res://main.tscn").instantiate()
	tree.root.add_child(app)
	await tree.create_timer(0.5).timeout
	if app.pet.skin == null or app.plan.data.tasks.size() != 4:
		printerr("SMOKE FAIL: skin or isolated default plan missing")
		tree.quit(1)
		return
	if app.pet.skin.id != &"warm_jade" or app.breath_effect.visible:
		printerr("SMOKE FAIL: energy core default missing or goal is permanently visible")
		tree.quit(1)
		return
	if not app.panel_window.visible:
		printerr("SMOKE FAIL: first-run learning welcome was not shown")
		tree.quit(1)
		return
	app.panel.dismiss_requested.emit()
	print("SMOKE STAGE: welcome dismissed")
	_pointer_click(app, app.pet.position + app.pet.map_skin_point(Vector2(380, 45)))
	if app.pet.current_action != &"swim" or app.panel_window.visible:
		printerr("SMOKE FAIL: left click did not select movement independently of plan")
		tree.quit(1)
		return
	# A quick drag must not consume the next action in the cycle.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = app.pet.position + Vector2(200, 100)
	app.desktop._input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = press.position + Vector2(100, 100)
	app.desktop._input(release)
	_pointer_click(app, app.pet.position + app.pet.map_skin_point(Vector2(380, 45)))
	if app.pet.current_action != &"look":
		printerr("SMOKE FAIL: rapid drag consumed a click action")
		tree.quit(1)
		return
	# Native menu presentation runs an OS modal loop. Do not open it from an
	# in-process coroutine that must also dismiss it. test_context_menu.gd checks
	# press/release/deferred sequencing; here verify the real menu's command route.
	if app.desktop._menu.get_item_index(4) < 0 or app.desktop._menu.get_item_index(6) < 0 or app.panel_window.visible:
		printerr("SMOKE FAIL: goal/focus context menu commands missing")
		tree.quit(1)
		return
	print("SMOKE STAGE: context menu commands checked")
	app.desktop._menu.id_pressed.emit(4)
	app.pet.player.seek(1.4,true)
	app.pet._process(0.0)
	app._update_geometry()
	if app.pet.current_action != &"breath" or not app.breath_effect.goal_label.visible or app.breath_effect.goal_label.text != "单例模式":
		printerr("SMOKE FAIL: menu breath did not reveal current goal")
		tree.quit(1)
		return
	await _capture(tree,tree.root,"goal-breath")
	app.pet.player.seek(5.58,true)
	app.pet._process(0.05)
	app._process(0.0)
	if app.pet.current_action != &"idle" or app.breath_effect.visible:
		printerr("SMOKE FAIL: completed breath left a permanent goal overlay")
		tree.quit(1)
		return
	app.pet.select_action(&"breath")
	app.pet.player.seek(1.4,true)
	app.pet._process(0.0)
	app._update_geometry()
	_pointer_click(app, app.breath_effect.goal_rect.get_center())
	if not app.panel_window.visible:
		printerr("SMOKE FAIL: goal mist click did not open study panel")
		tree.quit(1)
		return
	await _capture(tree, app.panel_window, "study-plan")
	var first_id: String = app.plan.data.current_id
	app.panel.action_button.pressed.emit()
	if app.plan.data.current_id != first_id or not app.plan.data.tasks[0].completed:
		printerr("SMOKE FAIL: completion advanced or failed")
		tree.quit(1)
		return
	await _capture(tree, app.panel_window, "study-completed")
	app.panel.action_button.pressed.emit()
	if app.plan.data.tasks[1].id != app.plan.data.current_id:
		printerr("SMOKE FAIL: explicit next did not advance")
		tree.quit(1)
		return
	app.panel.settings_requested.emit()
	print("SMOKE STAGE: plan progression checked")
	await _capture(tree, app.settings_window, "settings")
	app.settings.display_scale_requested.emit(0.5)
	if app.pet.scale != Vector2(0.5, 0.5):
		printerr("SMOKE FAIL: display scaling not wired")
		tree.quit(1)
		return
	app.settings.action_preview_requested.emit(&"curious")
	if app.pet.current_action != &"curious":
		printerr("SMOKE FAIL: action preview not wired")
		tree.quit(1)
		return
	await tree.create_timer(0.4).timeout
	await _capture(tree, tree.root, "desktop-pet-50")
	app.settings.display_scale_requested.emit(1.0)
	if not _native_region_covers_artwork(app):
		printerr("SMOKE FAIL: final installed window region clips artwork")
		tree.quit(1)
		return
	print("SMOKE STAGE: native contours checked")
	if DisplayServer.get_name() != "headless":
		for size in [0.5, 1.25]:
			app.pet.set_display_scale(size)
			for action in [&"swim", &"stretch", &"rest", &"breath"]:
				app.pet.select_action(action)
				app.pet.player.advance(0.3)
				app.pet.player.advance(0.0)
				var sample_times := [0.3]
				if action == &"breath":
					sample_times = [0.6, 1.4, 5.4]
				for sample_time in sample_times:
					app.pet.player.seek(sample_time,true)
					app.pet._process(0.0)
					app._update_geometry()
					await tree.process_frame
					await RenderingServer.frame_post_draw
					if not _rendered_pixels_inside_region(tree.root):
						printerr("SMOKE FAIL: GPU rendered pixels outside native mask: ", size, " / ", action, " at ", sample_time)
						printerr("EFFECT REGION ",app.breath_effect.goal_rect," label ",app.breath_effect.goal_label.get_rect()," caption ",app.breath_effect.caption.get_rect()," time ",app.breath_effect.elapsed," current ",app.pet.current_action)
						await _capture(tree,tree.root,"coverage-failure")
						tree.quit(1)
						return
	app.pet.set_display_scale(1.0)
	print("SMOKE STAGE: rendered coverage checked")
	app.settings_window.hide()
	app.desktop.hide_pet()
	if DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR) and tree.root.mode != Window.MODE_MINIMIZED:
		printerr("SMOKE FAIL: main window was not minimized to tray")
		tree.quit(1)
		return
	app.desktop.show_pet()
	if DisplayServer.get_name() != "headless" and tree.root.mode != Window.MODE_WINDOWED:
		printerr("SMOKE FAIL: tray restore did not restore main window mode")
		tree.quit(1)
		return
	await _capture(tree, tree.root, "desktop-pet")
	app._focus_action("start",5)
	app._focus_action("pause")
	if app.focus_session.state != "paused" or app.settings.category_tabs.get_tab_count() != 4:
		printerr("SMOKE FAIL: focus workflow or settings categories missing")
		tree.quit(1)
		return
	print("SMOKE TEST PASSED: energy core, first-run welcome, context menu, guiding goal, click/drag, manual progress, focus, scaling, GPU coverage, hide/show")
	tree.quit()

static func _pointer_click(app: Node, point: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	app.desktop._input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	app.desktop._input(release)

static func _rendered_pixels_inside_region(window: Window) -> bool:
	# Independent check of actual GPU output, before Windows applies its clipping region.
	# Scanline intervals avoid a point-in-polygon loop for every visible pixel.
	var image := window.get_texture().get_image()
	var outline := PackedVector2Array()
	for point in window.mouse_passthrough_polygon:
		outline.append(point.floor())
	for y in range(0, image.get_height(), 2):
		var row := y + 0.5
		var crossings: Array[float] = []
		for index in outline.size():
			var a := outline[index]
			var b := outline[(index + 1) % outline.size()]
			if (a.y > row) != (b.y > row):
				crossings.append(a.x + (b.x - a.x) * (row - a.y) / (b.y - a.y))
		crossings.sort()
		var cursor := 0
		var inside := false
		for x in range(0, image.get_width(), 2):
			while cursor < crossings.size() and crossings[cursor] <= x + 0.5:
				inside = not inside
				cursor += 1
			if not inside and image.get_pixel(x, y).a >= 0.05:
				printerr("GPU OUTSIDE REGION at ", Vector2i(x, y), " alpha ", image.get_pixel(x, y).a)
				return false
	return true

static func _native_region_covers_artwork(app: Node) -> bool:
	var membership = load("res://tests/test_coverage.gd")
	if app.pet.skin.render_texture == null:
		# Procedural energy-core artwork has no source bitmap. Independently
		# check every current render contour against the native region; actual
		# framebuffer coverage is checked below at multiple scales/action phases.
		for size in [0.5, 0.75, 1.0, 1.25]:
			app.pet.set_display_scale(size)
			app._update_geometry()
			var native: PackedVector2Array = app.get_window().mouse_passthrough_polygon
			for polygon in app.pet.get_visual_geometry().render_polygons:
				for point in polygon:
					if not membership._inside_outline(app.pet.position+point, native): return false
		app.pet.set_display_scale(1.0)
		return true
	var image: Image = app.pet.skin.render_texture.get_image()
	var factor: Vector2 = app.pet.skin.render_rect.size / Vector2(image.get_size())
	for size in [0.5, 0.75, 1.0, 1.25]:
		app.pet.set_display_scale(size)
		for action in app.pet.skin.action_map:
			app.pet.play_action(&"idle")
			app.pet.play_action(action)
			app.pet.player.advance(0.3)
			var length: float = app.pet.player.get_animation(app.pet.skin.action_map[action]).length
			app.pet.player.seek(length * 0.5, true)
			app._update_geometry()
			for frame in range(5):
				app.pet._process(1.0 / 60.0)
				var native := PackedVector2Array()
				for point in app.get_window().mouse_passthrough_polygon:
					native.append(point.floor())
				for y in range(0, image.get_height(), 64):
					for x in range(0, image.get_width(), 64):
						if image.get_pixel(x, y).a < 0.05:
							continue
						var local: Vector2 = app.pet.skin.render_rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * factor
						var window_point: Vector2 = app.pet.position + app.pet.map_skin_point(local)
						if not membership._inside_outline(window_point, native) or not Rect2(Vector2.ZERO, app.get_window().size).has_point(window_point):
							printerr("NATIVE SOURCE OUTSIDE ",size," / ",action," frame ",frame," source ",Vector2i(x,y)," window ",window_point," window size ",app.get_window().size)
							return false
	app.pet.set_display_scale(1.0)
	app.pet.play_action(&"idle")
	return true

static func _capture(tree: SceneTree, window: Window, title: String) -> void:
	var directory := OS.get_environment("CLOUD_DRAGON_SCREENSHOTS")
	if DisplayServer.get_name() == "headless" or directory.is_empty():
		return
	await tree.process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	var image := window.get_texture().get_image()
	var error := image.save_png(directory.path_join(title + ".png"))
	if error != OK:
		printerr("Screenshot save failed: ", error)
