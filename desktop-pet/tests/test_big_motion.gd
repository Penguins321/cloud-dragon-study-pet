extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view = load("res://pet/pet_view.gd").new()
	root.add_child(view)
	assert(view.apply_skin(load("res://pet/skins/warm_jade/skin.tres")) == OK)
	view.set_process(false)
	for action in [&"walk", &"laugh", &"jump", &"hop", &"spin", &"sway"]:
		assert(view.skin.action_map.has(action), "large motion is available: " + action)
		view.select_action(action)
		var actor = view.actor
		var min_y := 1000.0
		var min_x := 1000.0
		var max_x := -1000.0
		var crossings := 0
		var previous := 0.0
		var phase: float = actor.phase
		for frame in range(420):
			view._process(1.0/60.0)
			min_y = minf(min_y, actor.parts[1].origin.y)
			min_x = minf(min_x, actor.parts[1].origin.x)
			max_x = maxf(max_x, actor.parts[1].origin.x)
			if actor.lean * previous < 0.0: crossings += 1
			if absf(actor.lean) > 0.01: previous = actor.lean
			for part in actor.parts:
				assert(is_equal_approx(part.x.length(), 1.0) and is_equal_approx(part.y.length(), 1.0), "rigid jade geometry")
			for side in [0,2]:
				var core_outline: PackedVector2Array = actor.parts[1] * actor.CORE
				var side_outline: PackedVector2Array = actor.parts[side] * actor.SHARD
				assert(Geometry2D.intersect_polygons(core_outline, side_outline).is_empty(), "separate stones: " + action)
			for vertex in actor.CORE:
				var point: Vector2 = actor.parts[1] * (vertex * 0.99)
				var covered := false
				for polygon in actor.render_regions():
					if Geometry2D.is_point_in_polygon(point, polygon): covered = true
				assert(covered, "rotating core stays inside native mask")
		assert(actor.phase > phase + 6.9, "continuous hover phase")
		assert(view.current_action == &"idle", "large motion returns to hover")
		assert(absf(actor.lean) < 0.01 and absf(actor.lift) < 0.01)
		if action == &"jump": assert(min_y < 0.0, "jump rises more than 133 pixels")
		if action == &"walk": assert(max_x-min_x > 100.0, "walking travels in visible steps")
		if action == &"laugh": assert(crossings >= 6, "laugh has repeated shaking")
	view.free()
	print("BIG MOTION: distinct movement, rigid separation, native coverage and hover return passed")
	quit()
