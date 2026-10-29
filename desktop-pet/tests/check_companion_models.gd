extends SceneTree

var failures := 0
var checks := 0

func _init() -> void:
	var focus_script = load("res://study/focus_session.gd") if FileAccess.file_exists("res://study/focus_session.gd") else null
	var ambient_script = load("res://pet/ambient_scheduler.gd") if FileAccess.file_exists("res://pet/ambient_scheduler.gd") else null
	check(focus_script != null, "focus model exists")
	check(ambient_script != null, "ambient model exists")
	if focus_script != null:
		test_focus(focus_script)
		test_restore_totals(focus_script)
	if ambient_script != null:
		test_ambient(ambient_script)
	print("Companion models: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func test_focus(script) -> void:
	var focus = script.new()
	check(focus.state == "idle" and focus.duration_seconds == 1500.0, "default is idle 25 minutes")
	check(focus.start(4) == ERR_INVALID_PARAMETER and focus.start(121) == ERR_INVALID_PARAMETER, "duration bounds")
	check(focus.start(5, "Original task") == OK, "starts minimum duration")
	check(focus.task_title == "Original task" and focus.remaining_seconds == 300.0, "captures title and duration")
	var before_restart: Dictionary = focus.snapshot()
	check(focus.start(25, "Replacement") == ERR_BUSY and focus.snapshot() == before_restart, "running start rejected without losing time/title")
	check(not focus.advance(1.25) and is_equal_approx(focus.total_focus_seconds, 1.25), "credits actual running delta")
	check(focus.pause() == OK, "pauses running session")
	before_restart = focus.snapshot()
	check(focus.start(25) == ERR_BUSY and focus.snapshot() == before_restart, "paused start rejected without losing time/title")
	var saved: Dictionary = focus.snapshot()
	check(not focus.advance(1.0) and focus.snapshot() == saved, "paused session does not advance")
	check(focus.resume() == OK, "resumes paused session")
	check(not focus.advance(2.01) and focus.state == "paused" and focus.total_focus_seconds == 1.25, "long interruption pauses without credit")
	focus.resume()
	check(not focus.advance(0.5, false) and focus.state == "paused", "noncontinuous delta pauses")
	focus.resume()
	for invalid in [-1.0, NAN, INF]:
		saved = focus.snapshot()
		check(not focus.advance(invalid) and focus.snapshot() == saved, "invalid delta preserves session")
	check(focus.cancel() == OK and focus.state == "idle" and focus.total_focus_seconds == 1.25, "cancel keeps earned total")
	check(focus.completed_sessions == 0 and focus.remaining_seconds == focus.duration_seconds, "cancel resets remaining without completion")
	check(focus.start(5, "x".repeat(201)) == ERR_INVALID_PARAMETER, "oversized session title rejected")
	check(focus.start(120) == OK and focus.duration_seconds == 7200.0, "maximum duration")
	focus.cancel()
	focus.start(5)
	check(focus.task_title == "自由专注", "empty title uses free focus")
	var completions := 0
	for index in 151:
		if focus.advance(2.0):
			completions += 1
	check(completions == 1 and focus.completed_sessions == 1 and focus.state == "finished", "finish emitted and counted once")
	check(focus.remaining_seconds == 0.0 and focus.total_focus_seconds == 301.25, "completion caps earned duration")
	check(focus.resume() == ERR_UNAVAILABLE and focus.pause() == ERR_UNAVAILABLE, "invalid transitions reject")
	focus.start(5, "Persistent task")
	focus.advance(0.5)
	saved = focus.snapshot()
	check(saved.get("schema_version") == 1 and saved.size() == 7, "snapshot version and all six state fields")
	var restored = script.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved))), "JSON snapshot restores")
	check(restored.state == "paused" and restored.task_title == "Persistent task" and restored.remaining_seconds == 299.5, "running restores paused without offline credit")
	check(restored.total_focus_seconds == focus.total_focus_seconds and restored.completed_sessions == 1, "restore preserves statistics")
	var baseline: Dictionary = restored.snapshot()
	var malformed: Array = [null, [], {}, {"schema_version": 2}]
	for entry in [["state", "unknown"], ["duration_seconds", 299.0], ["duration_seconds", 301.0], ["remaining_seconds", -1.0], ["remaining_seconds", 301.0], ["total_focus_seconds", NAN], ["completed_sessions", 1.5], ["completed_sessions", -1], ["task_title", 3], ["task_title", "x".repeat(201)], ["schema_version", true]]:
		var candidate: Dictionary = saved.duplicate(true)
		candidate[entry[0]] = entry[1]
		malformed.append(candidate)
	var impossible: Dictionary = saved.duplicate(true)
	impossible.state = "finished"
	malformed.append(impossible)
	for candidate in malformed:
		check(not restored.restore(candidate) and restored.snapshot() == baseline, "malformed restore preserves existing state")
	focus.cancel()
	check(restored.restore(focus.snapshot()) and restored.state == "idle", "idle snapshot restores")
	focus.start(5)
	for index in 150:
		focus.advance(2.0)
	check(restored.restore(focus.snapshot()) and restored.state == "finished", "finished snapshot restores")
	check(not restored.advance(1.0) and restored.completed_sessions == 2, "restored finish never recounts")

func test_restore_totals(script) -> void:
	# Completed sessions and the current session consume distinct earned seconds.
	var baseline = script.new()
	baseline.start(5, "Keep me")
	baseline.advance(1.0)
	baseline.pause()
	var original: Dictionary = baseline.snapshot()
	for row in [["paused", 300.0, 1.0, 300.0, 1], ["running", 300.0, 1.0, 300.0, 1], ["finished", 1500.0, 0.0, 300.0, 1], ["finished", 1500.0, 0.0, 1500.0, 2]]:
		var receiver = script.new()
		receiver.restore(original)
		var candidate := {"schema_version": 1, "state": row[0], "duration_seconds": row[1], "remaining_seconds": row[2], "total_focus_seconds": row[3], "completed_sessions": row[4], "task_title": "x"}
		check(not receiver.restore(candidate) and receiver.snapshot() == original, "combined earned seconds reject atomically: %s" % str(row))
	for row in [["paused", 300.0, 1.0, 599.0, 1], ["running", 300.0, 1.0, 599.0, 1], ["finished", 1500.0, 0.0, 1500.0, 1], ["finished", 1500.0, 0.0, 1800.0, 2], ["idle", 1500.0, 1500.0, 600.0, 2], ["idle", 1500.0, 1500.0, 699.0, 2]]:
		var receiver = script.new()
		var candidate := {"schema_version": 1, "state": row[0], "duration_seconds": row[1], "remaining_seconds": row[2], "total_focus_seconds": row[3], "completed_sessions": row[4], "task_title": "x"}
		check(receiver.restore(JSON.parse_string(JSON.stringify(candidate))), "combined earned seconds accepts feasible JSON: %s" % str(row))
		var roundtrip = script.new()
		check(roundtrip.restore(receiver.snapshot()) and roundtrip.snapshot() == receiver.snapshot(), "paused/finished/idle roundtrip preserves valid totals")
func test_ambient(script) -> void:
	var first = script.new(42)
	var second = script.new(42)
	var previous: StringName = &""
	var elapsed := 0.0
	var event_count := 0
	for index in 10000:
		var action: StringName = first.step(0.5, true)
		check(action == second.step(0.5, true), "seeded sequence is reproducible")
		elapsed += 0.5
		if action != &"":
			check(elapsed >= 45.0 and elapsed <= 90.5, "event interval within cooldown")
			check(action in [&"look", &"rest", &"stretch", &"refract_turn"] and action != previous, "candidate valid and does not repeat")
			previous = action
			elapsed = 0.0
			event_count += 1
	check(event_count > 50, "many random intervals exercised")
	var blocked = script.new(42)
	for index in 200:
		check(blocked.step(1.0, false) == &"", "blocked never emits")
	for index in 44:
		check(blocked.step(1.0, true) == &"", "unblocking waits full cooldown")
	check(blocked.step(900.0, true) == &"", "sleep never catches up")
	for index in 44:
		check(blocked.step(1.0, true) == &"", "sleep restarts full cooldown")
	blocked.reset()
	for invalid in [-1.0, NAN, INF]:
		check(blocked.step(invalid, true) == &"", "invalid scheduler delta is silent")
	for index in 44:
		check(blocked.step(1.0, true) == &"", "reset waits full cooldown")
	# Polling blocked frames must not consume new random intervals each frame.
	var many = script.new(42)
	var once = script.new(42)
	for index in 100:
		many.step(0.1, false)
	once.step(0.1, false)
	for index in 300:
		check(many.step(0.5, true) == once.step(0.5, true), "blocked duration does not reroll per frame")
