extends SceneTree

const Model = preload("res://pet/social_interaction.gd")
var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var model = Model.new()
	check(model.step(0.01, Vector2.ZERO).action == &"", "first sample never startles")
	model.reset()
	model.step(0.1, Vector2(250, 0))
	check(model.step(0.1, Vector2.ZERO).action == &"startle", "fast entry startles")
	check(model.step(0.1, Vector2(20, 0)).action == &"", "shared cooldown")
	model.reset()
	model.step(0.1, Vector2.ZERO)
	for frame in range(11):
		check(model.step(0.1, Vector2.ZERO).action == &"", "hover waits full dwell")
	check(model.step(0.1, Vector2.ZERO).action == &"greet", "stationary hover greets")
	for frame in range(80):
		check(model.step(0.1, Vector2.ZERO).action == &"", "stationary hover greets once")
	model.step(0.5, Vector2(240, 0))
	model.step(0.5, Vector2.ZERO)
	var greeted_again := false
	for frame in range(13):
		greeted_again = greeted_again or model.step(0.1, Vector2.ZERO).action == &"greet"
	check(greeted_again, "exit rearms greeting")
	model.reset()
	model.step(0.1, Vector2.ZERO)
	for frame in range(10):
		check(model.step(0.02, Vector2(1 if frame % 2 == 0 else -1, 0)).action == &"", "tiny jitter never strokes")
	var nuzzled := false
	for x in [10, 20, 30, 20, 10, 0, -10, 0, 10, 20, 30]:
		nuzzled = nuzzled or model.step(0.1, Vector2(x, 0)).action == &"nuzzle"
	check(nuzzled, "natural horizontal stroking nuzzles")
	model.reset()
	model.step(0.1, Vector2.ZERO)
	model.step(1.0, Vector2.ZERO)
	check(model.step(0.1, Vector2.ZERO, false).action == &"", "blocked interaction is quiet")
	check(model.step(0.3, Vector2.ZERO).action == &"", "blocked time does not accumulate")
	check(model.step(10.0, Vector2.ZERO).action == &"", "long gap does not burst")
	check(model.step(0.3, Vector2.ZERO).action == &"", "long gap resets dwell")
	check(model.step(0.1, Vector2(NAN, 0)).attention == Vector2.ZERO, "nonfinite point is safe")
	check(model.step(NAN, Vector2.ZERO).action == &"", "nonfinite delta is safe")
	check(model.step(-0.1, Vector2.ZERO).action == &"", "negative delta is safe")
	for point in [Vector2.ZERO, Vector2(30, 0), Vector2(100, 100), Vector2(220, 0), Vector2(1000, 0)]:
		var attention: Vector2 = model.step(0.1, point).attention
		check(attention.is_finite() and attention.length() <= 0.55001, "attention is restrained")
	check(model.step(0.1, Vector2(250, 0)).attention == Vector2.ZERO, "far pointer has no attention")
	model.reset()
	model.step(0.016, Vector2.ZERO)
	var smooth_nuzzle := false
	for x in range(31):
		smooth_nuzzle = smooth_nuzzle or model.step(0.016, Vector2(x, 0)).action == &"nuzzle"
	for x in range(30, -31, -1):
		smooth_nuzzle = smooth_nuzzle or model.step(0.016, Vector2(x, 0)).action == &"nuzzle"
	for x in range(-30, 31):
		smooth_nuzzle = smooth_nuzzle or model.step(0.016, Vector2(x, 0)).action == &"nuzzle"
	check(smooth_nuzzle, "smooth small frame deltas accumulate into natural strokes")
	var positive: Vector2 = Model.new().step(0.01,Vector2(1,0)).attention
	var negative: Vector2 = Model.new().step(0.01,Vector2(-1,0)).attention
	check(positive.distance_to(negative) < 0.02, "subpixel cursor jitter around the core does not flip head pose")
	print("SOCIAL_INTERACTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
