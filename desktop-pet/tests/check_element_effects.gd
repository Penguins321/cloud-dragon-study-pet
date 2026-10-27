extends SceneTree
var failures := 0
func _initialize() -> void:
	load("res://tests/test_element_effects.gd").run(func(ok: bool, message: String):
		print("PASS " if ok else "FAIL ",message)
		if not ok: failures += 1)
	quit(failures)
