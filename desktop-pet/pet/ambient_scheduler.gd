extends RefCounted
## Pure automatic-action gate. Seed zero randomizes; nonzero seeds reproduce runs.

const ACTIONS: Array[StringName] = [&"swim",&"look",&"stretch",&"rest",&"celebrate",&"breath",&"walk",&"laugh",&"jump",&"hop",&"spin",&"sway",&"bow",&"roll",&"dance",&"orbit",&"helix",&"cross_orbit",&"refract_turn",&"greet",&"nuzzle",&"startle",&"doze",&"curious"]
var _rng := RandomNumberGenerator.new()
var _remaining: float = 0.0
var _was_allowed: bool = false
var _previous: StringName = &""

func _init(seed: int = 0) -> void:
	if seed == 0:
		_rng.randomize()
	else:
		_rng.seed = seed
	reset()

func step(delta: float, allowed: bool, supported: Array = []) -> StringName:
	if not allowed:
		# Blocked frames must not continually consume random cooldowns.
		_was_allowed = false
		return &""
	if not is_finite(delta) or delta < 0.0 or delta > 2.0:
		reset()
		return &""
	if not _was_allowed:
		_remaining = _rng.randf_range(10.0, 20.0)
		_was_allowed = true
	_remaining -= delta
	if _remaining > 0.0:
		return &""
	var candidates: Array[StringName] = []
	for action in ACTIONS:
		if not supported.is_empty() and not supported.has(action): continue
		if action != _previous:
			candidates.append(action)
	if candidates.is_empty(): return &""
	_previous = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_remaining = _rng.randf_range(10.0, 20.0)
	return _previous

func reset() -> void:
	# Keep the prior action so blocking/reset cannot cause adjacent repeats.
	_was_allowed = false
	_remaining = 0.0
