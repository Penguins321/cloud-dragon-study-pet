extends SceneTree

var failures := 0

func _initialize() -> void:
	load("res://tests/test_appearance.gd").run(func(ok: bool, message: String):
		if not ok:
			failures += 1
			printerr("FAIL: "+message)
	)
	print("Appearance failures: ",failures)
	load("res://tests/test_flame.gd").run(func(ok: bool, message: String):
		if not ok:
			failures += 1
			printerr("FAIL: "+message)
	)
	print("Appearance and flame failures: ",failures)
	quit(0 if failures == 0 else 1)
