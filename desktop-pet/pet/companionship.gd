extends RefCounted

const MATURE_SECONDS := 40.0 * 3600.0
var active_seconds := 0.0

func restore(value: Variant) -> void:
	active_seconds = 0.0
	if (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.0:
		active_seconds = float(value)

func advance(delta: float, active: bool) -> float:
	if not active or not is_finite(delta) or delta <= 0.0 or delta > 2.0:
		return 0.0
	active_seconds += delta
	return delta

func progress() -> float:
	return clampf(active_seconds / MATURE_SECONDS, 0.0, 1.0)
