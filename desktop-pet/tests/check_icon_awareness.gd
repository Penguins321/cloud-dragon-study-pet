extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	load("res://tests/test_icon_awareness.gd").run(self,check)
	print("Icon awareness policy failures: ",failures)
	quit(0 if failures == 0 else 1)
