extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var path := "res://pet/skins/jade_dragon/skin.tres"
	var available := ResourceLoader.exists(path)
	check.call(available, "selected jade dragon has a runtime skin")
	if not available:
		return
	var skin = load(path)
	check.call(skin.id == &"jade_dragon", "runtime skin identifies the selected jade dragon")
	var defaults: Dictionary = load("res://main.gd").get_script_constant_map()
	check.call(defaults.has("DEFAULT_SKIN") and defaults.DEFAULT_SKIN == skin, "application starts with jade dragon instead of the archived cloud dragon")
	var image: Image = skin.render_texture.get_image()
	check.call(image.detect_alpha() == Image.ALPHA_BLEND and image.get_pixel(0, 0).a < 0.01 and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a < 0.01, "jade artwork has real transparent background")
	check.call(absf(skin.render_rect.size.x / skin.render_rect.size.y - float(image.get_width()) / image.get_height()) < 0.001, "jade artwork preserves its source aspect ratio")
	var actor = skin.scene.instantiate()
	tree.root.add_child(actor)
	actor.swim_strength = 1.0
	actor.neck_lift = 1.0
	var rigid := true
	for step in range(16):
		actor.phase = TAU * step / 16.0
		actor.sync_pose()
		var head_inverse: Transform2D = actor.skin_matrices[9].affine_inverse()
		for point in [Vector2(404,61), Vector2(418,70), Vector2(340,20), Vector2(365,28)]:
			rigid = rigid and (head_inverse * actor.deform_point(point)).distance_to(point) < 0.05
	check.call(rigid, "jade eyes, muzzle and antlers remain rigid while the neck moves")
	actor.free()
	var old = load("res://pet/skins/cloud_dragon/view.tscn").instantiate()
	check.call(old.JOINTS[0][2] == Vector2(331,115), "jade bind coordinates do not mutate the archived cloud skin")
	old.free()
	await load("res://tests/test_flexible.gd").run(tree, check, path)
	await load("res://tests/test_coverage.gd").run(tree, check, path)
