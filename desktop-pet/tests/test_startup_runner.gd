extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	await load("res://tests/test_startup.gd").run(self,check)
	print("Startup: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
