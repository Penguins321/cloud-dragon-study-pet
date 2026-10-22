extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	view.apply_skin(load("res://pet/skins/cloud_dragon/skin.tres"))
	var image: Image = load("res://pet/skins/cloud_dragon/dragon.png").get_image()
	var geometry: Dictionary = view.get_visual_geometry()
	var outlines: Array = geometry.get("render_polygons", [geometry.hit_polygon])
	var missing := 0
	var visible_samples := 0
	var pixel_to_local := Vector2(440.0, 178.86179) / Vector2(image.get_size())
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			if image.get_pixel(x, y).a < 0.05:
				continue
			visible_samples += 1
			var point := (Vector2(x, y) + Vector2(0.5, 0.5)) * pixel_to_local
			var inside := false
			for outline in outlines:
				if _inside_outline(point, outline):
					inside = true
					break
			if not inside:
				missing += 1
	check.call(visible_samples > 1000, "coverage test samples actual opaque character pixels")
	check.call(missing == 0, "native rendering region covers all visible dragon samples; clipped=%d" % missing)
	# Sample poses across every animation, scale and native integer quantization.
	# A separate half-open ray oracle avoids the engine predicate's edge degeneracy.
	var samples: Array[Vector2] = []
	for y in range(0, image.get_height(), 32):
		for x in range(0, image.get_width(), 32):
			if image.get_pixel(x, y).a >= 0.05:
				samples.append((Vector2(x, y) + Vector2(0.5, 0.5)) * pixel_to_local)
	var animated_missing := 0
	var outside_bounds := 0
	for size in [0.5, 0.75, 1.0, 1.25]:
		view.set_display_scale(size)
		for action in view.skin.action_map:
			view.play_action(&"idle")
			view.play_action(action)
			var duration: float = view.player.get_animation(view.skin.action_map[action]).length
			for step in range(5):
				view.player.seek(duration * step / 5.0, true)
				view.actor.phase = TAU * step / 5.0
				geometry = view.get_visual_geometry()
				var quantized: Array[PackedVector2Array] = []
				for outline in geometry.render_polygons:
					var native := PackedVector2Array()
					for point in outline:
						native.append(point.floor())
					quantized.append(native)
				for point in samples:
					var transformed: Vector2 = view.map_skin_point(point)
					if not geometry.bounds.has_point(transformed):
						outside_bounds += 1
					var covered := false
					for outline in quantized:
						if _inside_outline(transformed, outline):
							covered = true
							break
					if not covered:
						animated_missing += 1
	check.call(animated_missing == 0, "all motion/scale samples survive integer window regions; clipped=%d" % animated_missing)
	check.call(outside_bounds == 0, "stable skin bounds contain motion at every scale")
	view.free()
	var settings = load("res://ui/settings_panel.tscn").instantiate()
	tree.root.add_child(settings)
	var tiny: Button = _find_tiny(settings)
	check.call(tiny != null, "settings provide smaller-than-small scale")
	if tiny != null:
		var values: Array[float] = []
		settings.display_scale_requested.connect(func(value: float): values.append(value))
		tiny.pressed.emit()
		check.call(values == [0.5], "extra-small option requests 50 percent scale")
	settings.free()

static func _find_tiny(node: Node) -> Button:
	if node is Button and node.text == "更小":
		return node
	for child in node.get_children():
		var found := _find_tiny(child)
		if found != null:
			return found
	return null

static func _inside_outline(point: Vector2, outline: PackedVector2Array) -> bool:
	var inside := false
	var previous := outline.size() - 1
	for index in outline.size():
		var a := outline[index]
		var b := outline[previous]
		if (a.y > point.y) != (b.y > point.y):
			var crossing := (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
			if point.x < crossing:
				inside = not inside
		previous = index
	return inside
