extends RefCounted
## Desktop translation is separate from the character's local skeletal animation.
const TRAVEL := [&"walk",&"swim",&"orbit",&"helix",&"cross_orbit"]
var _rng := RandomNumberGenerator.new()
var _target := Vector2.INF
var _remainder := Vector2.ZERO
var _action: StringName = &""

func _init(seed: int = 0) -> void:
	if seed: _rng.seed = seed
	else: _rng.randomize()

func step(delta: float, position: Vector2i, size: Vector2i, areas: Array[Rect2i], action: StringName, allowed: bool) -> Vector2i:
	if not allowed or action not in TRAVEL or areas.is_empty() or not is_finite(delta) or delta <= 0 or delta > 2.0:
		_target = Vector2.INF
		_remainder = Vector2.ZERO
		_action = &""
		return position
	var area := areas[0]
	var overlap := -1
	for candidate in areas:
		var amount := candidate.intersection(Rect2i(position,size)).get_area()
		if amount > overlap:
			overlap = amount
			area = candidate
	var low := Vector2(area.position)
	var high := Vector2(area.end-size).max(low)
	if action != _action or _target == Vector2.INF or Vector2(position).distance_to(_target) < 12:
		_action = action
		# Choose among full-screen destinations, favouring a substantial journey.
		_target = Vector2(position)
		for attempt in 8:
			var point := Vector2(_rng.randf_range(low.x,high.x),_rng.randf_range(low.y,high.y))
			if point.distance_squared_to(Vector2(position)) > _target.distance_squared_to(Vector2(position)): _target = point
	_target = _target.clamp(low,high)
	var next := (Vector2(position)+_remainder).move_toward(_target,(115.0 if action == &"walk" else 155.0)*minf(delta,0.1)).clamp(low,high)
	var rounded := Vector2i(next.round())
	_remainder = next-Vector2(rounded)
	return rounded
