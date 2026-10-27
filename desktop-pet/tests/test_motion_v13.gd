extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view = load("res://pet/pet_view.gd").new()
	root.add_child(view)
	check(view.apply_skin(load("res://pet/skins/warm_jade/skin.tres")) == OK, "skin loads")
	view.set_process(false)
	for action in [&"bow", &"roll", &"dance"]:
		check(view.skin.action_map.has(action), "new action available: " + action)
		check(action in view.CLICK_ACTIONS, "new action participates in click cycle: " + action)
		if not view.skin.action_map.has(action): continue
		view.select_action(action)
		var animation: Animation = view.player.get_animation(view.skin.action_map[action])
		var peaks := {}
		for property in ["lean", "spread", "lift", "drift", "energy", "gait", "turn"]:
			var track := animation.find_track(NodePath(".:" + property), Animation.TYPE_VALUE)
			check(track >= 0, "pose track exists: " + property)
			if track < 0: continue
			check(absf(animation.track_get_key_value(track, 0)) < 0.001, action + " begins at hover: " + property)
			check(absf(animation.track_get_key_value(track, animation.track_get_key_count(track)-1)) < 0.001, action + " ends at hover: " + property)
			var low := 0.0
			var high := 0.0
			for key in animation.track_get_key_count(track):
				var value: float = animation.track_get_key_value(track, key)
				low = minf(low, value)
				high = maxf(high, value)
			peaks[property] = Vector2(low, high)
		if action == &"bow":
			check(peaks.lean.y > 0.65 and peaks.lift.y > 20.0, "bow inclines deeply and lowers respectfully")
		if action == &"roll":
			check(peaks.turn.y >= TAU-0.01 and peaks.lift.x < -65.0, "roll makes a complete airborne turn")
		if action == &"dance":
			check(peaks.drift.x < -35.0 and peaks.drift.y > 35.0 and peaks.gait.length() > 25.0, "dance has opposing steps and independent shard accents")
		for frame in range(420):
			view._process(1.0/60.0)
			for part in view.actor.parts:
				check(is_equal_approx(part.x.length(),1.0) and is_equal_approx(part.y.length(),1.0), "motion preserves rigid geometry")
			var core: PackedVector2Array = view.actor.parts[1] * view.actor.CORE
			for side in [0,2]:
				var shard: PackedVector2Array = view.actor.parts[side] * view.actor.SHARD
				check(Geometry2D.intersect_polygons(core,shard).is_empty(), action + " keeps stones separate")
			for vertex in view.actor.CORE:
				var point: Vector2 = view.actor.parts[1] * (vertex*0.99)
				var covered := false
				for region in view.actor.render_regions():
					if Geometry2D.is_point_in_polygon(point,region): covered = true
				check(covered, action + " remains within native rendering coverage")
		check(view.current_action == &"idle", action + " returns automatically to hover")
	for action in [&"walk", &"laugh"]:
		var animation: Animation = view.player.get_animation(view.skin.action_map[action])
		var track := animation.find_track(NodePath(".:lift"),Animation.TYPE_VALUE)
		var anticipation := 0.0
		for key in animation.track_get_key_count(track):
			if animation.track_get_key_time(track,key) < animation.length*0.2:
				anticipation = maxf(anticipation,animation.track_get_key_value(track,key))
		check(anticipation > 9.0, action + " gathers downwards before the main gesture")
	for appearance in ["jade","flame"]:
		view.actor.set_appearance(appearance,"ember" if appearance == "flame" else "jade")
		view.actor.set_growth(1.0)
		for action in view.CLICK_ACTIONS:
			view.select_action(action)
			var minimum := Vector2(INF,INF)
			var maximum := Vector2(-INF,-INF)
			var fits := true
			for frame in range(420):
				view._process(1.0/60.0)
				for polygon in view.actor.render_regions():
					for point in polygon:
						minimum = minimum.min(point)
						maximum = maximum.max(point)
						if not view.skin.visual_bounds.has_point(point): fits = false
			check(fits, "%s / %s effect exceeds fixed visual bounds: %s .. %s" % [appearance,action,minimum,maximum])
			print("BOUNDS ",appearance," / ",action,": ",minimum," .. ",maximum)
	view.free()
	print("MOTION V13: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
