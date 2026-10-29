extends SceneTree

var failures := 0

func check(ok: bool) -> void:
	if not ok:
		failures += 1
		printerr("MAC STARTUP CHECK FAILED")

func _initialize() -> void:
	var script = load("res://desktop/startup_macos.gd")
	if script == null:
		quit(1)
		return
	var directory := ProjectSettings.globalize_path("res://../.tools/mac-startup-test-%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	var executable := directory.path_join("温玉 & 'test'.app")
	var file := FileAccess.open(executable, FileAccess.WRITE)
	file.store_string("test")
	file.close()
	var service = script.new(directory, executable)
	check(service.available and not service.is_enabled())
	check(service.set_enabled(true) == OK and service.is_enabled())
	var xml := FileAccess.get_file_as_string(service.shortcut_path)
	check(xml.contains("&amp;") and xml.contains("温玉"))
	check(xml.contains("<key>RunAtLoad</key><true/>") and not xml.contains("KeepAlive"))
	var parser := XMLParser.new()
	check(parser.open_buffer(xml.to_utf8_buffer()) == OK)
	var parse_error := parser.read()
	while parse_error == OK: parse_error = parser.read()
	check(parse_error == ERR_FILE_EOF)
	var refreshed = script.new(directory, executable)
	check(refreshed.is_enabled())
	var other := directory.path_join("new.app")
	file = FileAccess.open(other, FileAccess.WRITE)
	file.store_string("new")
	file.close()
	refreshed = script.new(directory, other)
	check(FileAccess.get_file_as_string(service.shortcut_path).contains("new.app"))
	check(service.set_enabled(false) == OK and not service.is_enabled())
	check(service.set_enabled(false) == OK)
	check(FileAccess.file_exists(executable))
	var missing = script.new(directory, directory.path_join("missing"))
	check(not missing.available and missing.set_enabled(true) != OK)
	var blocked = script.new(executable.path_join("subdirectory"), executable)
	check(blocked.set_enabled(true) != OK and not blocked.is_enabled() and not blocked.message.is_empty())
	check(not script.new().available)
	DirAccess.remove_absolute(executable)
	DirAccess.remove_absolute(other)
	DirAccess.remove_absolute(directory)
	print("MAC STARTUP failures: %d" % failures)
	quit(0 if failures == 0 else 1)
