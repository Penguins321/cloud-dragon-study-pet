extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	view.apply_skin(load("res://pet/skins/cloud_dragon/skin.tres"))
	for action in [&"idle", &"curious", &"sleepy", &"celebrate", &"dragging"]:
		check.call(view.skin.action_map.has(action), "cloud dragon supplies motion: " + action)
		if not view.skin.action_map.has(action):
			continue
		view.play_action(&"idle")
		view.play_action(action)
		view.player.advance(0.0)
		var before: Transform2D = view.actor.transform
		view.player.advance(0.45)
		check.call(not view.actor.transform.is_equal_approx(before), "motion visibly changes transform: " + action)
		var geometry: Dictionary = view.get_visual_geometry()
		var point: Vector2 = view.skin.hit_polygon[0]
		check.call(geometry.hit_polygon[0].is_equal_approx(view.map_skin_point(point)), "motion transforms native region with artwork: " + action)
	view.play_action(&"idle")
	view.play_action(&"celebrate")
	view.player.advance(2.0)
	check.call(view.current_action == &"idle", "real celebration returns to idle")
	view.set_active(false)
	check.call(not view.player.is_playing(), "hidden pet stops animation")
	view.set_active(true)
	check.call(view.player.is_playing() and view.current_action == &"idle", "restored pet resumes idle")
	view.player.advance(0.3)
	view.player.seek(1.0, true)
	var transition_start: Transform2D = view.actor.transform
	view.play_action(&"curious")
	view.player.advance(0.0)
	check.call(view.actor.transform.is_equal_approx(transition_start), "action transition starts at existing pose without snapping")
	view.player.advance(1.0 / 60.0)
	check.call(view.actor.position.distance_to(transition_start.origin) < 1.0, "first transition frame has bounded displacement")
	view.play_action(&"idle")
	view.player.advance(0.3)
	view.player.seek(0.0001, true)
	var loop_start: Transform2D = view.actor.transform
	view.player.seek(3.9999, true)
	check.call(view.actor.position.distance_to(loop_start.origin) < 0.01 and absf(view.actor.rotation - loop_start.get_rotation()) < 0.001, "idle loop closes continuously")
	view.player.seek(0.0, true)
	view._notify_geometry_changed()
	var region_updates: Array[int] = [0]
	view.geometry_changed.connect(func(): region_updates[0] += 1)
	for frame in range(60):
		view._process(1.0 / 60.0)
	check.call(region_updates[0] > 0 and region_updates[0] <= 60, "joint animation refreshes native regions at most once per frame")
	view.free()
