extends SceneTree
func _initialize() -> void:
	if not ResourceLoader.exists("res://pet/screen_roaming.gd"):
		printerr("Screen-wide movement controller missing")
		quit(1)
		return
	var roaming = load("res://pet/screen_roaming.gd").new(123)
	var areas: Array[Rect2i] = [Rect2i(-1920,0,1920,1080)]
	var position := Vector2i(-1200,400)
	var initial := position
	for frame in 180:
		position = roaming.step(1.0/60.0,position,Vector2i(300,300),areas,&"walk",true)
		assert(areas[0].encloses(Rect2i(position,Vector2i(300,300))))
	assert(Vector2(position-initial).length() > 150,"Travel must be larger than local animation sway")
	var stopped: Vector2i = roaming.step(1.0,position,Vector2i(300,300),areas,&"walk",false)
	assert(stopped == position,"Dragging and panels immediately stop travel")
	assert(roaming.step(3.0,position,Vector2i(300,300),areas,&"walk",true) == position,"Resume after suspend must not teleport")
	assert(roaming.step(0.1,position,Vector2i(300,300),areas,&"stretch",true) == position,"Stationary gestures must not slide across desktop")
	var scheduler = load("res://pet/ambient_scheduler.gd").new(123)
	var supported := [&"walk",&"dance",&"breath",&"roll",&"spin"]
	var observed: Array = []
	var previous: StringName = &""
	var wait := 0.0
	for second in 3000:
		wait += 1.0
		var action: StringName = scheduler.step(1.0,true,supported)
		if action != &"":
			assert(action in supported and action != previous)
			assert(wait <= 20.0,"Development activity must not wait 45 seconds")
			wait = 0.0
			previous = action
			if action not in observed: observed.append(action)
	assert(observed.size() == supported.size(),"Every supported performance action must be reachable automatically")
	print("SCREEN ROAMING: PASS")
	quit(0)
