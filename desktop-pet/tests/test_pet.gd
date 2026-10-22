extends RefCounted

static func make_skin(nested: bool, include_idle := true) -> Resource:
	var skin = load("res://pet/pet_skin.gd").new()
	skin.id = &"test_b" if nested else &"test_a"
	var actor := Node2D.new()
	actor.name = "DifferentRoot" if nested else "Root"
	var player := AnimationPlayer.new()
	player.name = "Player" if nested else "AnimationPlayer"
	if nested:
		var branch := Node.new()
		branch.name = "Inner"
		actor.add_child(branch)
		branch.owner = actor
		branch.add_child(player)
		player.owner = actor
		skin.player_path = ^"Inner/Player"
	else:
		actor.add_child(player)
		player.owner = actor
	var library := AnimationLibrary.new()
	for action in [&"idle", &"celebrate", &"curious", &"dragging"]:
		if action == &"idle" and not include_idle:
			continue
		var animation := Animation.new()
		animation.length = 0.2
		if action == &"idle" or action == &"dragging":
			animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(action, animation)
		skin.action_map[action] = action
	player.add_animation_library(&"", library)
	skin.scene = PackedScene.new()
	skin.scene.pack(actor)
	actor.free()
	skin.hit_polygon = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 50), Vector2(0, 50)])
	skin.visual_bounds = Rect2(0, 0, 100, 50)
	skin.bubble_anchor = Vector2(80, 0)
	return skin

static func run(tree: SceneTree, check: Callable) -> void:
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	var a = make_skin(false)
	var b = make_skin(true)
	check.call(view.apply_skin(a) == OK, "skin A loads")
	check.call(view.apply_skin(b) == OK, "different node layout skin B loads")
	if view.skin == null:
		view.free()
		return
	check.call(view.apply_skin(make_skin(false, false)) == ERR_INVALID_DATA, "skin without idle is rejected")
	check.call(view.skin.id == &"test_b", "invalid skin keeps previous actor")
	view.play_action(&"not_available")
	check.call(view.current_action == &"idle", "missing optional action falls back to idle")
	view.play_action(&"celebrate")
	view.play_action(&"curious")
	check.call(view.current_action == &"celebrate", "curious cannot interrupt celebration")
	await tree.create_timer(0.35).timeout
	check.call(view.current_action == &"idle", "completed celebration returns to idle")
	view.play_action(&"dragging")
	view.play_action(&"curious")
	check.call(view.current_action == &"dragging", "dragging blocks low priority action")
	view.play_action(&"sleepy")
	check.call(view.current_action == &"dragging", "missing low priority action cannot interrupt dragging")
	view.apply_skin(a)
	check.call(view.current_action == &"idle", "new skin resets action")
	view.play_action(&"celebrate")
	view.apply_skin(b)
	view.play_action(&"dragging")
	await tree.create_timer(0.35).timeout
	check.call(view.current_action == &"dragging", "old actor completion cannot overwrite new skin action")
	for value in [0.5, 0.75, 1.0, 1.25]:
		view.set_display_scale(value)
		var geometry: Dictionary = view.get_visual_geometry()
		check.call(geometry.get("bubble_anchor") == Vector2(80 * value, 0), "bubble anchor follows scale %s" % value)
		check.call(geometry.get("bounds") == Rect2(0, 0, 100 * value, 50 * value), "visual bounds follow scale %s" % value)
		check.call(geometry.get("hit_polygon", PackedVector2Array())[1] == Vector2(100 * value, 0), "hit region follows scale %s" % value)
	view.free()
