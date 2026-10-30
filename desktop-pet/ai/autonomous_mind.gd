extends RefCounted
## Simulated needs provide continuity between sparse model planning requests.
var energy := 0.85
var curiosity := 0.7
var social_need := 0.35
var sleep_pressure := 0.1
var attention := 0.3
var rhythm := "day"
var local_hour := 12
var intention := "想看看周围有什么有趣的"
var _plan: Array[StringName] = []
var _recent: Array[StringName] = []
var _rng := RandomNumberGenerator.new()
const REST := [&"rest",&"doze",&"breath"]
const EXPLORE := [&"walk",&"swim",&"look",&"curious",&"orbit",&"helix",&"cross_orbit"]
const SOCIAL := [&"greet",&"nuzzle",&"bow",&"laugh",&"celebrate"]

func _init(seed: int = 0) -> void:
	if seed: _rng.seed = seed
	else: _rng.randomize()

func advance(delta: float, active: bool) -> void:
	if not active or not is_finite(delta) or delta <= 0 or delta > 2.0: return
	energy = clampf(energy+delta*0.0006,0.0,1.0)
	curiosity = clampf(curiosity+delta*0.0015,0.0,1.0)
	social_need = clampf(social_need+delta*0.0008,0.0,1.0)
	sleep_pressure = clampf(sleep_pressure+delta*(0.002 if rhythm == "night" else 0.0003),0.0,1.0)
	attention = maxf(0.0,attention-delta*0.002)

func set_hour(hour: int) -> void:
	local_hour = clampi(hour,0,23)
	rhythm = "night" if local_hour >= 22 or local_hour < 7 else ("morning" if local_hour < 10 else ("day" if local_hour < 18 else "evening"))

func observe(action: StringName) -> void:
	if action in [&"idle",&"dragging"]: return
	_recent.append(action)
	if _recent.size() > 5: _recent.pop_front()
	energy = clampf(energy+(0.14 if action in REST else -0.055),0.0,1.0)
	sleep_pressure = clampf(sleep_pressure+(-0.16 if action in REST else 0.035),0.0,1.0)
	if action in EXPLORE: curiosity = maxf(0.0,curiosity-0.12)
	if action in SOCIAL: social_need = maxf(0.0,social_need-0.08)

func interact() -> void:
	social_need = maxf(0.0,social_need-0.35)
	attention = 1.0
	intention = "想回应刚才的互动"
	clear_plan()

func context() -> Dictionary:
	return {"energy":snappedf(energy,0.01),"curiosity":snappedf(curiosity,0.01),"social_need":snappedf(social_need,0.01),"sleep_pressure":snappedf(sleep_pressure,0.01),"attention":snappedf(attention,0.01),"rhythm":rhythm,"local_hour":local_hour,"intention":intention,"recent_actions":_recent.duplicate(),"remaining_plan":_plan.duplicate()}

func clear_plan() -> void:
	_plan.clear()

func accept_plan(actions: Array, intent: String, supported: Array[StringName]) -> void:
	_plan.clear()
	for action in actions:
		if (action is String or action is StringName) and StringName(action) in supported:
			_plan.append(StringName(action))
		if _plan.size() >= 3: break
	if not intent.is_empty(): intention = intent.left(24)

func choose(supported: Array[StringName]) -> StringName:
	# Strong fatigue can revise an old play/exploration episode.
	if energy < 0.15 or sleep_pressure > 0.85: clear_plan()
	while not _plan.is_empty():
		var next: StringName = _plan.pop_front()
		if next in supported: return next
	if supported.is_empty(): return &"idle"
	var preferred := EXPLORE
	if energy < 0.3 or sleep_pressure > 0.65 or (rhythm == "night" and attention < 0.6):
		preferred = REST
		intention = "夜深了，想放慢一点" if rhythm == "night" else "活动了一会儿，想歇一歇"
	elif attention > 0.6 or social_need > 0.6 or rhythm == "evening":
		preferred = SOCIAL
		intention = "想和你打个招呼"
	elif rhythm == "morning":
		preferred = [&"stretch",&"walk",&"look",&"breath",&"greet"]
		intention = "舒展一下，开始新的一天"
	elif curiosity > 0.4:
		intention = "想去别的地方探索一下"
	else:
		preferred = [&"dance",&"roll",&"spin",&"hop",&"jump",&"sway",&"stretch"]
		intention = "想找点好玩的事情做"
	var weighted: Array[StringName] = []
	for action in supported:
		if action == &"idle": continue
		if not _recent.is_empty() and action == _recent.back(): continue
		var weight := 5 if action in preferred else 1
		if action in _recent: weight = 1
		for i in weight: weighted.append(action)
	return weighted[_rng.randi_range(0,weighted.size()-1)] if not weighted.is_empty() else supported[0]
