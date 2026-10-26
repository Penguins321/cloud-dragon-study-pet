extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "res://pet/skins/warm_jade/skin.tres"
	if not ResourceLoader.exists(path):
		printerr("FAIL: warm jade replacement skin is missing")
		quit(1)
		return
	var view = load("res://pet/pet_view.gd").new()
	root.add_child(view)
	assert(view.apply_skin(load(path)) == OK)
	view.set_process(false)
	assert(view.current_action == &"idle")
	var actor = view.actor
	for action in view.CLICK_ACTIONS:
		view.select_action(action)
		for frame in range(420):
			view._process(1.0 / 60.0)
			for polygon in actor.render_regions():
				for point in polygon:
					assert(view.skin.visual_bounds.has_point(point), "effect exceeds full animation bounds")
			assert(actor.parts[0].origin.x < actor.parts[1].origin.x)
			assert(actor.parts[1].origin.x < actor.parts[2].origin.x)
		assert(view.current_action == &"idle", "action must return to hovering")
		assert(absf(actor.spread) < 0.01 and absf(actor.lean) < 0.01 and absf(actor.lift) < 0.01)
		var phase: float = actor.phase
		view.select_action(&"stretch")
		view._process(0.001)
		assert(actor.phase > phase, "action switch must preserve hover phase")
	view.free()
	print("WARM JADE: hover return, phase continuity, rigid side order and effect bounds passed")
	quit()

