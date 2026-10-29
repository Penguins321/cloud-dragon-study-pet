extends RefCounted
## Pure elapsed-time session. Persistence and task progression belong to callers.

var state: String = "idle"
var duration_seconds: float = 1500.0
var remaining_seconds: float = 1500.0
var total_focus_seconds: float = 0.0
var completed_sessions: int = 0
var task_title: String = ""

func start(minutes: int, title := "") -> Error:
	if state in ["running", "paused"]:
		return ERR_BUSY
	if minutes < 5 or minutes > 120 or title.length() > 200:
		return ERR_INVALID_PARAMETER
	duration_seconds = float(minutes * 60)
	remaining_seconds = duration_seconds
	task_title = title.strip_edges()
	if task_title.is_empty():
		task_title = "自由专注"
	state = "running"
	return OK

func pause() -> Error:
	if state != "running":
		return ERR_UNAVAILABLE
	state = "paused"
	return OK

func resume() -> Error:
	if state != "paused":
		return ERR_UNAVAILABLE
	state = "running"
	return OK

func cancel() -> Error:
	state = "idle"
	remaining_seconds = duration_seconds
	task_title = ""
	return OK

func advance(delta: float, continuous := true) -> bool:
	if state != "running" or not is_finite(delta) or delta < 0.0:
		return false
	if not continuous or delta > 2.0:
		state = "paused"
		return false
	var credited := minf(delta, remaining_seconds)
	remaining_seconds -= credited
	total_focus_seconds += credited
	if remaining_seconds <= 0.0:
		remaining_seconds = 0.0
		state = "finished"
		completed_sessions += 1
		return true
	return false

func snapshot() -> Dictionary:
	return {"schema_version": 1, "state": state, "duration_seconds": duration_seconds, "remaining_seconds": remaining_seconds, "total_focus_seconds": total_focus_seconds, "completed_sessions": completed_sessions, "task_title": task_title}

func restore(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if not _number(value.get("schema_version")) or value.schema_version != 1:
		return false
	if not value.get("state") is String or value.state not in ["idle", "running", "paused", "finished"]:
		return false
	for field in ["duration_seconds", "remaining_seconds", "total_focus_seconds", "completed_sessions"]:
		if not _number(value.get(field)):
			return false
	var duration: float = value.duration_seconds
	var remaining: float = value.remaining_seconds
	var total: float = value.total_focus_seconds
	var completed: float = value.completed_sessions
	if duration < 300.0 or duration > 7200.0 or fmod(duration, 60.0) != 0.0:
		return false
	if remaining < 0.0 or remaining > duration or total < 0.0:
		return false
	# JSON stores numbers as floats; allow integral counts within exact range.
	if completed < 0.0 or completed > 9007199254740991.0 or completed != floor(completed):
		return false
	if not value.get("task_title") is String or value.task_title.length() > 200:
		return false
	if value.state == "idle" and remaining != duration:
		return false
	if value.state in ["running", "paused"] and (remaining <= 0.0 or value.task_title.strip_edges().is_empty()):
		return false
	if value.state == "finished" and (remaining != 0.0 or completed < 1.0):
		return false
	# Finished includes this session in the count; active sessions do not.
	# Each earlier completion earned at least the minimum five minutes.
	var minimum_total := completed * 300.0
	if value.state in ["running", "paused"]:
		minimum_total += duration - remaining
	elif value.state == "finished":
		minimum_total = (completed - 1.0) * 300.0 + duration
	if total + 0.000001 < minimum_total:
		return false
	state = "paused" if value.state == "running" else value.state
	duration_seconds = duration
	remaining_seconds = remaining
	total_focus_seconds = total
	completed_sessions = int(completed)
	task_title = value.task_title
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
