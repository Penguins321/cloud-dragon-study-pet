extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	create_timer(20).timeout.connect(func(): printerr("Expressive integration timed out"); quit(1))
	call_deferred("run")

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	if not app.has_method("_manual_social"):
		printerr("FAIL: expressive input routes missing")
		app.free()
		quit(1)
		return
	check(app.pet.CLICK_ACTIONS.size() == 23, "23 authored actions registered")
	for action in [&"greet", &"nuzzle", &"startle", &"doze"]:
		check(app.pet.skin.action_map.has(action), "Emotion available: "+action)
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	app.desktop._input(middle)
	check(app.pet.current_action == &"nuzzle", "Middle click requests affection")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.double_click = true
	press.position = app.pet.position+app.pet.map_skin_point(Vector2(220,133))
	app.desktop._input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = press.position
	app.desktop._input(release)
	check(app.pet.current_action == &"greet", "Double click explicitly greets")
	app._set_companion_mode("quiet")
	check(not app._social_allowed(), "Quiet blocks unsolicited reactions")
	app._set_companion_mode("natural")
	app._focus_action("start",5)
	check(not app._social_allowed(), "Focus blocks unsolicited reactions")
	app._focus_action("cancel")
	app._set_reduced_motion(true)
	check(not app._social_allowed(), "Reduced motion blocks unsolicited reactions")
	var before: Dictionary = app.plan.to_dict()
	app._manual_social(&"nuzzle")
	check(app.plan.to_dict() == before, "Affection never modifies study plan")
	app.free()
	await process_frame
	print("EXPRESSIVE INTEGRATION: ", failures, " failures")
	quit(0 if failures == 0 else 1)
