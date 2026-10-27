extends RefCounted

static func run(check: Callable) -> void:
	var Model = load("res://pet/companionship.gd")
	check.call(Model != null, "companionship model exists")
	if Model == null:
		return
	var model = Model.new()
	check.call(model.progress() == 0.0, "new companion starts without accumulated time")
	for invalid in [null, "3600", true, -1.0, INF, NAN, {}]:
		model.restore(invalid)
		check.call(model.active_seconds == 0.0, "invalid stored companionship time is ignored")
	model.restore(72000)
	check.call(model.progress() == 0.5, "twenty restored active hours give half growth")
	for delta in [-1.0, 0.0, INF, NAN, 2.01, 3600.0]:
		check.call(model.advance(delta, true) == 0.0, "invalid or suspended frame adds no companionship")
	model.advance(1.0, false)
	check.call(model.active_seconds == 72000.0, "hidden companion and invalid frames preserve time without penalty")
	check.call(model.advance(2.0, true) == 2.0 and model.progress() > 0.5, "visible active runtime increases growth monotonically")
	var restored = Model.new()
	restored.restore(model.active_seconds)
	check.call(restored.active_seconds == model.active_seconds and restored.progress() == model.progress(), "saved active time restores exactly without offline gains")
	restored.restore(144000.0)
	check.call(restored.progress() == 1.0, "forty active hours mature companion")
	restored.advance(1.0, true)
	check.call(restored.progress() == 1.0 and restored.active_seconds == 144001.0, "growth remains normalized while lifetime time continues")
