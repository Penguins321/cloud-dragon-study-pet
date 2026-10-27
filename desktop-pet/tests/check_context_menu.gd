extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	auto_accept_quit = false
	await load("res://tests/test_context_menu.gd").run(self,check)
	print("Context menu and exit failures: ",failures)
	quit(0 if failures == 0 else 1)
