extends SceneTree
func _initialize() -> void:
	if not ResourceLoader.exists("res://ai/autonomous_mind.gd"):
		printerr("Continuous companion state is missing")
		quit(1)
		return
	var mind = load("res://ai/autonomous_mind.gd").new(42)
	if not mind.has_method("set_hour"):
		printerr("Local circadian rhythm is missing")
		quit(1)
		return
	mind.set_hour(2)
	assert(mind.context().rhythm == "night")
	mind.advance(1.0,true)
	assert(mind.context().sleep_pressure > 0)
	mind.set_hour(8)
	assert(mind.context().rhythm == "morning")
	mind.set_hour(14)
	assert(mind.context().rhythm == "day")
	mind.set_hour(20)
	assert(mind.context().rhythm == "evening")
	for i in 12: mind.observe(&"dance")
	assert(mind.context().energy < 0.4)
	for i in 10: mind.observe(&"rest")
	assert(mind.context().energy > 0.7)
	mind.interact()
	assert(mind.context().social_need < 0.3)
	var actions: Array[StringName] = [&"walk",&"look",&"rest",&"dance"]
	mind.accept_plan(["look","walk"],"想四处看看",actions)
	assert(mind.choose(actions) == &"look")
	assert(mind.choose(actions) == &"walk")
	mind.accept_plan(["dragging","unknown","rest"],"",actions)
	assert(mind.choose(actions) == &"rest")
	mind.accept_plan(["walk"],"",actions)
	mind.clear_plan()
	for i in 20: assert(mind.choose(actions) in actions)
	print("AUTONOMOUS MIND: PASS")
	quit(0)
