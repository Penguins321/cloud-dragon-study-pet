extends SceneTree

var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var geometry = load("res://desktop/window_geometry.gd")
	var areas: Array[Rect2i] = [Rect2i(0, 0, 1920, 1040)]
	check(geometry.restore_position(Vector2i(4000, 3000), Vector2i(500, 260), areas) == Vector2i(1420, 780), "offscreen pet returns inside desktop")
	check(geometry.restore_position(Vector2i(200, 300), Vector2i(500, 260), areas) == Vector2i(200, 300), "visible pet keeps its placement")
	check(geometry.restore_position(Vector2i(-490, 100), Vector2i(500, 260), areas) == Vector2i(0, 100), "almost hidden pet is recovered fully")
	check(geometry.restore_position(Vector2i(-20000, -20000), Vector2i(500, 318), areas) == Vector2i.ZERO, "drag target clamps at top and left before release")
	check(geometry.restore_position(Vector2i(20000, 20000), Vector2i(500, 318), areas) == Vector2i(1420, 722), "drag target keeps complete motion bounds above taskbar")
	check(geometry.place_panel(Rect2i(0, 700, 500, 280), Vector2i(410, 610), areas) == Vector2i(516, 370), "left-edge pet opens panel on free right side")
	check(geometry.place_panel(Rect2i(1420, 700, 500, 280), Vector2i(410, 610), areas) == Vector2i(994, 370), "right-edge pet opens panel on free left side")
	var body := PackedVector2Array([Vector2(0, 100), Vector2(100, 100), Vector2(100, 200), Vector2(0, 200)])
	var bubble := PackedVector2Array([Vector2(160, 0), Vector2(240, 0), Vector2(240, 60), Vector2(160, 60)])
	var combined: PackedVector2Array = geometry.combine_input_regions(body, bubble)
	check(not Geometry2D.is_point_in_polygon(Vector2(140, 80), combined), "transparent gap does not intercept desktop input")
	check(Geometry2D.is_point_in_polygon(Vector2(50, 150), combined), "pet body remains interactive")
	check(Geometry2D.is_point_in_polygon(Vector2(200, 30), combined), "bubble remains interactive")
	var overlapping: Array[PackedVector2Array] = [PackedVector2Array([Vector2(80,80),Vector2(150,80),Vector2(150,140),Vector2(80,140)])]
	var merged := PackedVector2Array()
	var original: Array[PackedVector2Array] = [body]
	for outline in geometry.merge_input_outlines(original,overlapping):
		merged = geometry.combine_input_regions(merged,outline)
	check(Geometry2D.is_point_in_polygon(Vector2(90,120),merged), "breath/body overlap stays filled instead of becoming an alternate-fill hole")
	check(not Geometry2D.is_point_in_polygon(Vector2(140,170),merged), "union preserves unrelated transparent desktop gaps")
	var diagonal: Array[PackedVector2Array] = [PackedVector2Array([Vector2(0.9,0.9),Vector2(20.9,0.9),Vector2(0.9,20.9)])]
	var no_additions: Array[PackedVector2Array] = []
	var rounded := PackedVector2Array()
	for outline in geometry.merge_input_outlines(diagonal,no_additions):
		for point in outline: rounded.append(point.floor())
	check(Geometry2D.is_point_in_polygon(Vector2(10.5,10.5),rounded), "native integer rounding retains subpixel coverage after polygon union")
	var Guard = load("res://desktop/single_instance.gd")
	var first_guard = Guard.new()
	var second_guard = Guard.new()
	var scope := ""
	var acquired := false
	for attempt in range(20):
		scope = "isolated_test_%s_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec(), attempt]
		if first_guard.acquire(scope):
			acquired = true
			break
	check(acquired, "first process guard acquires an available isolated scope")
	check(not second_guard.acquire(scope), "second instance cannot write same scope")
	first_guard.release()
	check(second_guard.acquire(scope), "released instance scope can restart")
	second_guard.release()
	await load("res://tests/test_pet.gd").run(self, check)
	load("res://tests/test_study.gd").run(check)
	load("res://tests/test_companionship.gd").run(check)
	load("res://tests/test_study.gd").run_store(check)
	await load("res://tests/test_ui.gd").run(self, check)
	await load("res://tests/test_startup.gd").run(self, check)
	check(load("res://main.gd").can_instantiate(), "application composition compiles")
	await load("res://tests/test_coverage.gd").run(self, check)
	await load("res://tests/test_motion.gd").run(self, check)
	await load("res://tests/test_motion_reuse.gd").run(self, check)
	await load("res://tests/test_flexible.gd").run(self, check)
	load("res://tests/test_wind.gd").run(self, check)
	load("res://tests/test_tail_flow.gd").run(self, check)
	await load("res://tests/test_jade_skin.gd").run(self, check)
	load("res://tests/test_head.gd").run(self, check)
	load("res://tests/test_mane.gd").run(self, check)
	load("res://tests/test_breath.gd").run(self, check)
	load("res://tests/test_goal_light.gd").run(self, check)
	load("res://tests/test_crystal_growth.gd").run(self, check)
	print("%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	quit(0 if failures.is_empty() else 1)
