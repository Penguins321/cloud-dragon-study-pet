extends SceneTree

const ACTIONS := [&"orbit",&"helix",&"cross_orbit",&"refract_turn"]
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view = load("res://pet/pet_view.gd").new()
	root.add_child(view)
	view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
	view.set_process(false)
	for action in ACTIONS: check(view.skin.action_map.has(action) and action in view.CLICK_ACTIONS,"Missing true 3D action "+action)
	if failures:
		view.free()
		quit(1)
		return
	if DisplayServer.get_name()=="headless":
		view.free()
		quit()
		return
	view.actor.set_render_mode("3d")
	var renderer = view.actor._view_3d
	var maximum_step := 0.0
	for action in ACTIONS:
		view.select_action(action)
		var length: float = view.player.current_animation_length
		var low := 0.0
		var high := 0.0
		var minimum_gap := INF
		var previous: Vector3 = renderer.stones[0].position
		var maximum_yaw := 0.0
		var safe := true
		for frame in range(ceili(length*60)+60):
			view._process(1.0/60)
			low = minf(low,renderer.stones[0].position.z)
			high = maxf(high,renderer.stones[0].position.z)
			minimum_gap = minf(minimum_gap,renderer.stones[0].position.distance_to(renderer.stones[2].position))
			maximum_step = maxf(maximum_step,previous.distance_to(renderer.stones[0].position))
			previous = renderer.stones[0].position
			maximum_yaw = maxf(maximum_yaw,absf(renderer.stones[1].rotation.y))
			for index in [0,2]:
				var relative: Vector3 = renderer.stones[index].position-renderer.stones[1].position
				safe = safe and (absf(relative.x)>0.88 or absf(relative.z)>0.70 or absf(relative.y)>1.70)
		check(safe,action+" intersects the core clearance volume")
		check(minimum_gap>0.95,action+" allows satellite collisions")
		check(view.current_action==&"idle",action+" does not return to hover")
		check(high-low>1.0 if action!=&"refract_turn" else maximum_yaw>0.7,action+" has no actual spatial rotation")
		print("SPATIAL ",action," depth ",high-low,"; minimum gap ",minimum_gap,"; core yaw ",maximum_yaw)
	check(maximum_step<0.08,"3D action transition moves more than 8px per 60Hz frame")
	for interrupt in [&"helix",&"dragging"]:
		view.play_action(&"idle")
		view.select_action(&"orbit")
		for frame in range(240): view._process(1.0/60)
		var before: Vector3 = renderer.stones[0].position
		view.play_action(interrupt)
		view._process(1.0/60)
		check(renderer.stones[0].position.distance_to(before)<0.08,"Interrupting orbit with "+interrupt+" teleports a satellite")
		var separated := true
		var interrupt_step := 0.0
		var prior: Vector3 = renderer.stones[0].position
		for frame in range(180):
			view._process(1.0/60)
			separated = separated and renderer.stones[0].position.distance_to(renderer.stones[2].position)>0.95
			interrupt_step = maxf(interrupt_step,renderer.stones[0].position.distance_to(prior))
			prior = renderer.stones[0].position
		check(separated,"Interrupted orbit makes the satellites collide")
		check(interrupt_step<0.08,"Interrupted orbit has abrupt subsequent movement")
		print("INTERRUPT ",interrupt," maximum step ",interrupt_step*100," px")
	view.free()
	print("SPATIAL ACTIONS: ",failures," failures; maximum step ",maximum_step*100," px")
	quit(0 if failures==0 else 1)
