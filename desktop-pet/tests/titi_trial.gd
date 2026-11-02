extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(not OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty())
	var store = preload("res://titi/store.gd").new()
	assert(store.valid(store.data))
	var candidate: Dictionary = store.data.duplicate(true)
	candidate.tasks = [{"id": "test", "text": "测试保存", "done": false}]
	assert(store.commit(candidate) == OK)
	store.load_data()
	assert(store.data.tasks[0].text == "测试保存")
	candidate.tasks[0].done = true
	assert(store.commit(candidate) == OK)
	assert(store.read_data(store.path + ".bak").tasks[0].done == false)
	assert(not store.valid({"version": 1}))
	var bad: Dictionary = candidate.duplicate(true)
	bad.tasks.append(bad.tasks[0].duplicate())
	assert(store.commit(bad) == ERR_INVALID_DATA)
	# Verify corruption recovery without touching actual user data.
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	store.load_data()
	assert(not store.blocked and store.data.tasks[0].done == false)
	assert(store.commit(candidate) == OK)
	var scene = load("res://titi/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._show_panel("todo")
	assert(scene.panel.size.x >= 600)
	assert(scene.panel.theme.default_font_size == 20)
	scene._add_task("试试轻松的一天")
	assert(scene.store.data.tasks.size() == 2)
	assert(scene.input.custom_minimum_size.y == 80)
	assert(scene.input.get_theme_font_size("font_size") == 24)
	for index in 6:
		scene._set_action(index)
		var image: Image = scene.textures[index].get_image()
		assert(image.get_pixel(0, 0).a < 0.01)
		assert(scene.polygons[index].size() > 3)
		assert(absf(scene.pet_rect.position.x + scene.pet_rect.size.x * scene.BODY_ANCHORS[index] - scene.PET_CENTER_X) < 0.01)
	for pose in 6:
		assert(scene.animation.clips[pose].size() == 4)
		var dimensions: Vector2 = scene.animation.clips[pose][0].get_size()
		for frame in scene.animation.clips[pose]: assert(frame.get_size() == dimensions)
		assert(scene.animation.clips[pose][0].get_image().get_data() != scene.animation.clips[pose][2].get_image().get_data())
		var visited := {}
		for step in 301: visited[scene.animation.frame_index(pose, step * 0.02)] = true
		assert(visited.size() == 4)
	for pet_size in [170, 210, 250]:
		scene._preference("size", pet_size)
		for pose in 6:
			scene._set_action(pose)
			var actual_head: float = scene.pet_rect.size.x / scene.textures[pose].get_width() * scene.animation.head_widths[pose]
			assert(absf(actual_head - pet_size / 210.0 * 104.0) < 0.01)
			assert(scene.pet_rect.position.x >= 0 and scene.pet_rect.end.x <= root.size.x)
			assert(scene.pet_rect.position.y >= 0 and scene.pet_rect.end.y < scene.toolbar.position.y)
	scene._preference("size", 210)
	assert(scene.animation.frame_index(1, 0.0) == 0)
	assert(scene.animation.frame_index(1, 2.8) == 2)
	assert(scene.animation.frame_index(4, 1.8) == 2)
	assert(scene.animation.frame_index(5, 1.8) == 2)
	for pose in [4, 5]:
		for tick in 320:
			var time := tick * 0.02
			assert(scene.animation.deformation(pose, Vector2(0.2, 1.0), time, Vector2(210, 180)).length() < 0.001)
			for uv in [Vector2(0.2,0.5), Vector2(0.65,0.35), Vector2(0.9,0.2)]:
				var delta: Vector2 = scene.animation.deformation(pose, uv, time + 1.0/30.0, Vector2(210,180)) - scene.animation.deformation(pose, uv, time, Vector2(210,180))
				assert(delta.length() < 0.15)
	assert(scene.animation.deformation(4, Vector2(0.2,0.5), 3.2, Vector2(210,180)) == Vector2.ZERO)
	assert(scene.animation.deformation(5, Vector2(0.6,0.3), 3.1, Vector2(210,180)) == Vector2.ZERO)
	scene._set_action(1)
	scene.set_process(false)
	scene._show_toolbar()
	await create_timer(1.0).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/titi-pet-preview.png")
		scene.panel.get_texture().get_image().save_png("res://build/titi-todo-preview.png")
	assert(scene.toolbar.visible and scene.toolbar.modulate.a > 0.99)
	if DisplayServer.get_name() != "headless":
		var comparison := Image.create(1200, 860, false, Image.FORMAT_RGBA8)
		comparison.fill(Color("f0edf4"))
		for pose in 6:
			scene._set_action(pose)
			await process_frame
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			comparison.blend_rect(capture, Rect2i(Vector2i.ZERO, capture.get_size()), Vector2i(pose % 3, int(pose / 3)) * Vector2i(400, 430))
			for frame_index in 4:
				scene.animation.clips[pose][frame_index].get_image().save_png("res://build/titi-frame-%d-%d.png" % [pose, frame_index])
		comparison.save_png("res://build/titi-six-actions.png")
		for pose in [4, 5]:
			scene._set_action(pose)
			var first: PackedByteArray
			for phase in 2:
				scene.animation_time = 0.0 if phase == 0 else (3.2 if pose == 4 else 1.5)
				scene.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var sample := root.get_texture().get_image()
				sample.save_png("res://build/titi-smooth-%d-%d.png" % [pose, phase])
				if phase == 0: first = sample.get_data()
				else: assert(first != sample.get_data())
		scene._set_action(1)
	assert(absf(scene.toolbar.get_rect().get_center().x - scene.PET_CENTER_X) < 0.01)
	assert(scene.toolbar.get_rect().end.y < root.size.y)
	scene._preference("menu_style", "translucent")
	scene._style_toolbar()
	assert(scene.toolbar.get_theme_stylebox("panel").bg_color.a < 0.8)
	await create_timer(0.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/titi-translucent-preview.png")
	scene._hide_toolbar()
	await create_timer(0.2).timeout
	assert(not scene.toolbar.visible)
	scene._show_toolbar()
	scene._hide_toolbar(true)
	assert(not scene.toolbar.visible)
	scene.set_process(true)
	scene._show_panel("settings")
	scene._preference("quiet", true)
	assert(scene.action == 4)
	scene._preference("large_font", true)
	scene._render_panel()
	await create_timer(0.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		scene.panel.get_texture().get_image().save_png("res://build/titi-settings-preview.png")
	scene._show_panel("todo")
	var row: HBoxContainer = scene.tasks_box.get_child(0)
	var edit: LineEdit = row.get_child(1)
	assert(edit.get_theme_font_size("font_size") == 24)
	scene.panel.size = scene.panel.min_size
	await create_timer(0.2).timeout
	assert(row.size.y >= 52)
	assert(row.get_child(2).get_global_rect().end.x <= scene.panel.size.x)
	edit.text = "编辑后仍然保存"
	edit.text_submitted.emit(edit.text)
	assert(scene.store.read_data(scene.store.path).tasks[1].text == edit.text)
	scene._preference("quiet", false)
	row.get_child(0).pressed.emit()
	assert(scene.store.data.tasks[1].done)
	assert(scene.celebration.burst_count == 1)
	assert(scene.celebration.pieces[0].origin.is_equal_approx(scene.celebration.size / 2.0))
	assert(scene.celebration.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	await create_timer(0.25).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		scene.panel.get_texture().get_image().save_png("res://build/titi-celebration-preview.png")
	scene.done_expanded = true
	scene._render_panel()
	scene.done_box.get_child(1).get_child(0).pressed.emit()
	assert(scene.celebration.burst_count == 1)
	scene._preference("quiet", true)
	scene.tasks_box.get_child(0).get_child(0).pressed.emit()
	assert(scene.celebration.burst_count == 1)
	scene.done_box.get_child(1).get_child(2).pressed.emit()
	assert(scene.store.data.tasks.size() == 1)
	assert(scene.store.read_data(scene.store.path).tasks.size() == 1)
	scene._preference("quiet", false)
	scene._set_action(2, 0.05)
	await create_timer(0.15).timeout
	assert(scene.action == 1)
	scene._preference("quiet", true)
	scene._set_action(3, 0.05)
	await create_timer(0.15).timeout
	assert(scene.action == 4)
	print("TITI_TRIAL_TESTS_PASSED")
	quit()
