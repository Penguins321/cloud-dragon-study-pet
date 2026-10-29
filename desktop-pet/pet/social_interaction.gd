extends RefCounted
## Pure cursor-to-intent model; coordinates are relative to the core in logical pixels.

const RANGE := 220.0
const COOLDOWN := 6.0
const DWELL := 1.2
const ELLIPSE := Vector2(100.0, 140.0)
var _cooldown := 0.0
var _previous := Vector2.ZERO
var _has_previous := false
var _was_inside := false
var _hover := 0.0
var _hover_anchor := Vector2.ZERO
var _greeted := false
var _stroke_distance := 0.0
var _stroke_direction := 0.0
var _reversals := 0
var _stroke_anchor := Vector2.ZERO
var _stroke_anchor_valid := false

func reset() -> void:
	_cooldown = 0.0
	_clear_gesture()

func _clear_gesture() -> void:
	_has_previous = false
	_was_inside = false
	_hover = 0.0
	_greeted = false
	_clear_stroke()

func _clear_stroke() -> void:
	_stroke_anchor_valid = false
	_stroke_distance = 0.0
	_stroke_direction = 0.0
	_reversals = 0

func step(delta: float, point: Vector2, enabled: bool = true) -> Dictionary:
	var result := {"attention": Vector2.ZERO, "action": &""}
	if not enabled or not point.is_finite() or not is_finite(delta) or delta <= 0.0 or delta > 2.0:
		_clear_gesture()
		return result
	_cooldown = maxf(0.0, _cooldown - delta)
	var distance := point.length()
	if distance > 0.0 and distance < RANGE:
		result.attention = point.normalized() * 0.55 * smoothstep(0.0,60.0,distance) * (1.0 - distance / RANGE)
	var inside := (point / ELLIPSE).length_squared() <= 1.0
	var movement := point - _previous if _has_previous else Vector2.ZERO
	var speed := movement.length() / delta
	var action: StringName = &""
	if inside:
		if not _has_previous or not _was_inside:
			_hover_anchor = point
		if not _stroke_anchor_valid:
			_stroke_anchor = point
			_stroke_anchor_valid = true
		if _has_previous and not _was_inside and speed > 900.0:
			if _cooldown <= 0.0:
				action = &"startle"
			_greeted = true
			_hover = 0.0
			_clear_stroke()
		elif _has_previous and _was_inside:
			if point.distance_to(_hover_anchor) < 4.0:
				_hover += delta
			else:
				_hover = 0.0
				_hover_anchor = point
			var stroke_delta := point - _stroke_anchor
			if absf(stroke_delta.x) >= 4.0 and absf(stroke_delta.y) <= absf(stroke_delta.x) and speed <= 900.0:
				var direction := signf(stroke_delta.x)
				if _stroke_direction != 0.0 and direction != _stroke_direction:
					_reversals += 1
				_stroke_direction = direction
				_stroke_distance += absf(stroke_delta.x)
				_stroke_anchor = point
			elif stroke_delta.length() >= 4.0:
				_clear_stroke()
			if _cooldown <= 0.0 and _reversals >= 2 and _stroke_distance >= 90.0:
				action = &"nuzzle"
				_greeted = true
				_clear_stroke()
			elif not _greeted and _hover + 0.00001 >= DWELL:
				_greeted = true
				if _cooldown <= 0.0:
					action = &"greet"
	else:
		_hover = 0.0
		_greeted = false
		_clear_stroke()
	if action != &"":
		_cooldown = COOLDOWN
		result.action = action
	_previous = point
	_has_previous = true
	_was_inside = inside
	return result
