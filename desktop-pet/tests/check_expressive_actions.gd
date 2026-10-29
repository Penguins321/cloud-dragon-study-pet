extends SceneTree

const ACTIONS := [&"greet", &"nuzzle", &"startle", &"doze"]
const PROPERTIES := ["lean", "spread", "lift", "drift", "energy", "gait", "turn"]
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
	var skin = load("res://pet/skins/warm_jade/skin.tres")
	var signatures := {}
	for action in ACTIONS:
		check(skin.action_map.has(action), "semantic action available: " + action)
		if not skin.action_map.has(action): continue
		for hz in [30, 60, 120]:
			var actor = skin.scene.instantiate()
			root.add_child(actor)
			var player: AnimationPlayer = actor.get_node("AnimationPlayer")
			player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var animation: Animation = player.get_animation(skin.action_map[action])
			check(animation != null, "animation exists: " + action)
			if animation == null:
				actor.free()
				continue
			check(animation.length <= 6.5, action + " finishes before the existing seven second cycle")
			for property in PROPERTIES:
				var track := animation.find_track(NodePath(".:" + property), Animation.TYPE_VALUE)
				check(track >= 0, action + " has pose track " + property)
				if track < 0: continue
				check(absf(animation.track_get_key_value(track, 0)) < 0.001, action + " begins at hover: " + property)
				check(absf(animation.track_get_key_value(track, animation.track_get_key_count(track)-1)) < 0.001, action + " ends at hover: " + property)
			var finished := [false]
			player.animation_finished.connect(func(_name): finished[0] = true)
			player.play(skin.action_map[action])
			player.advance(0.0)
			var previous: Vector2 = actor.parts[1].origin
			var maximum_speed := 0.0
			var minimum := Vector2(INF, INF)
			var maximum := Vector2(-INF, -INF)
			var gait_min := 0.0
			var gait_max := 0.0
			var early_dip := 0.0
			var energy_low := 0.0
			for frame in range(ceili((animation.length+0.5)*hz)):
				var delta: float = 1.0 / hz
				player.advance(delta)
				actor.advance_pose(delta)
				var center: Vector2 = actor.parts[1].origin
				maximum_speed = maxf(maximum_speed, center.distance_to(previous)/delta)
				previous = center
				minimum = minimum.min(Vector2(actor.drift, actor.lift))
				maximum = maximum.max(Vector2(actor.drift, actor.lift))
				gait_min = minf(gait_min, actor.gait)
				gait_max = maxf(gait_max, actor.gait)
				energy_low = minf(energy_low, actor.energy)
				if frame*delta < animation.length*0.2: early_dip = maxf(early_dip, actor.lift)
				var core: PackedVector2Array = actor.parts[1]*actor.CORE
				for side in [0,2]:
					check(Geometry2D.intersect_polygons(core, actor.parts[side]*actor.SHARD).is_empty(), action + " keeps rigid stones separate")
				for part in actor.parts:
					check(is_equal_approx(part.x.length(),1.0) and is_equal_approx(part.y.length(),1.0), action + " preserves rigid geometry")
				if hz == 60:
					for polygon in actor.render_regions():
						for point in polygon: check(skin.visual_bounds.has_point(point), action + " fits the visual bounds")
			check(finished[0], "%s finishes at %d Hz" % [action,hz])
			check(maximum_speed < 650.0, "%s stays smooth at %d Hz: %.1f px/s" % [action,hz,maximum_speed])
			check(absf(actor.lean)+absf(actor.spread)+absf(actor.lift)+absf(actor.drift)+absf(actor.gait) < 0.01, action + " settles to hover")
			if action == &"greet": check(gait_min < -13.0 and gait_max > 13.0, "greeting alternates the two shards")
			if action == &"nuzzle": check(maximum.x > 12.0 and minimum.x < -3.0, "nuzzle gathers back then reaches affectionately")
			if action == &"startle": check(early_dip > 6.0 and minimum.y < -50.0 and maximum.y > 7.0, "startle anticipates, recoils, and lands")
			if action == &"doze": check(maximum.y > 16.0 and energy_low < -0.25, "doze lowers softly and dims")
			# The companions are part of the silhouette: a wave is distinguished
			# by alternating shard travel, while dozing is also a dimmer posture.
			if hz == 60: signatures[action] = Vector4(maximum.x-minimum.x,maximum.y-minimum.y,gait_max-gait_min,-energy_low*100.0)
			actor.free()
	for first in signatures:
		for second in signatures:
			if first != second: check(signatures[first].distance_to(signatures[second]) > 12.0, "distinct trajectory: %s / %s" % [first,second])
	var staged_actor = skin.scene.instantiate()
	root.add_child(staged_actor)
	var staged_player: AnimationPlayer = staged_actor.get_node("AnimationPlayer")
	for action in [&"look", &"stretch", &"rest"]:
		var staged: Animation = staged_player.get_animation(skin.action_map[action])
		var lift_track := staged.find_track(NodePath(".:lift"),Animation.TYPE_VALUE)
		var lean_track := staged.find_track(NodePath(".:lean"),Animation.TYPE_VALUE)
		var preparation: float = staged.value_track_interpolate(lift_track,staged.length*0.15)
		var emphasis: float = staged.value_track_interpolate(lift_track,staged.length*0.4)
		if action == &"rest":
			check(preparation < -2.0 and emphasis > 20.0, "rest rises slightly before folding down")
		elif action == &"stretch":
			check(preparation > 6.0 and emphasis < -25.0, "stretch gathers before its held opening")
		else:
			check(preparation > 2.0 and emphasis < -5.0, "look gathers before its first held glance")
			check(staged.value_track_interpolate(lean_track,staged.length*0.36) < -0.20 and staged.value_track_interpolate(lean_track,staged.length*0.66) > 0.15, "look inspects both sides with readable holds")
	staged_actor.free()
	print("EXPRESSIVE ACTIONS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
