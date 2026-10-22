extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var path := "res://pet/effects/goal_breath.gd"
	check.call(ResourceLoader.exists(path), "goal breath is an independent appearance effect")
	if not ResourceLoader.exists(path):
		return
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	view.apply_skin(load("res://pet/skins/jade_dragon/skin.tres"))
	check.call(view.actor.scale.x < 0.0, "jade dragon faces left for anatomically consistent breath")
	var actions: Array[StringName] = []
	for click in range(6):
		actions.append(view.cycle_action())
	check.call(actions == [&"swim",&"look",&"stretch",&"rest",&"celebrate",&"breath"], "breath is the sixth click action")
	check.call(view.player.has_animation(view.skin.action_map.get(&"breath",&"missing")), "breath supplies its own animation timeline")
	view.free()
	var effect = load(path).new()
	tree.root.add_child(effect)
	var mouth := Vector2(250,280)
	effect.set_frame(mouth,1.0,0.2,"单例模式")
	check.call(not effect.goal_label.visible, "goal text waits for breath to form")
	effect.set_frame(mouth,1.0,1.4,"单例模式")
	var direction: Vector2 = (effect.goal_rect.get_center()-mouth).normalized()
	check.call(direction.distance_to(Vector2(-1,-1).normalized()) < 0.001, "goal mist lies exactly 45 degrees above-left of mouth")
	check.call(effect.goal_label.visible and effect.goal_label.text == "单例模式", "formed breath displays the actual current goal")
	check.call(effect.contains_point(effect.goal_rect.get_center()) and not effect.contains_point(Vector2.ZERO), "goal cloud exposes a precise plan-entry region")
	check.call(effect.get_regions().size() >= 2, "native mask includes both stream and goal mist")
	effect.set_frame(mouth,0.5,1.4,"很长的今日学习目标也能保持可阅读")
	check.call(effect.goal_label.get_theme_font_size("font_size") >= 14, "smallest pet scale retains readable breath goal text")
	effect.free()
