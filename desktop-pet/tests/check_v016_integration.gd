extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("Integration timed out"); quit(1))
	call_deferred("run")

func run() -> void:
	var directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	if directory.is_empty():
		printerr("Isolated data directory required")
		quit(1)
		return
	var scene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	if not app.has_method("_set_companion_mode"):
		printerr("FAIL: v0.16 application integration missing")
		app.free()
		quit(1)
		return
	app.settings.companion_mode_requested.emit("quiet")
	app.settings.reduced_motion_requested.emit(true)
	app.settings.performance_requested.emit("eco")
	app.settings.topmost_requested.emit(false)
	check(app.companion_mode == "quiet" and app.reduced_motion, "Companion options apply through real UI signals")
	check(Engine.max_fps == 30 and not app.desktop.topmost_enabled, "Performance and topmost apply")
	check(app.pet.reduced_motion, "Reduced motion reaches actor executor")
	var first_id: String = app.plan.data.current_id
	var count: int = app.plan.data.tasks.size()
	app._complete()
	app._append_task("保留进度后追加")
	check(app.plan.data.tasks.size() == count+1 and app.plan.data.current_id == first_id and app.plan.data.tasks[0].completed, "Append preserves completed current item")
	app._revise_current("新目标", "修订当前项")
	check(app.plan.data.goal == "新目标" and app.plan.data.tasks[0].title == "修订当前项" and app.plan.data.tasks[0].id == first_id, "Details revision preserves stable ID")
	app._undo_complete()
	check(not app.plan.data.tasks[0].completed and app.plan.data.current_id == first_id, "Undo reopens current without stepping backward")
	app._focus_action("start", 5)
	app.focus_session.advance(1.0)
	check(app.focus_session.state == "running" and app.focus_session.task_title == "修订当前项", "Focus begins with current title snapshot")
	check(not app.plan.data.tasks[0].completed, "Focus does not complete task")
	app._save_preferences()
	app.free()
	await process_frame
	app = scene.instantiate()
	root.add_child(app)
	check(app.companion_mode == "quiet" and app.reduced_motion and app.performance_mode == "eco" and not app.topmost_enabled, "All companion options persist")
	check(app.focus_session.state == "paused" and app.focus_session.total_focus_seconds >= 1.0, "Restart restores focus paused with credited duration")
	app._focus_action("resume")
	# Headless has no tray by design, so exercise the visibility policy signal;
	# native hide-without-tray correctly opens a recovery panel instead.
	if app.desktop._tray == null: app.desktop.pet_visibility_changed.emit(false)
	else: app.desktop.hide_pet()
	check(app.focus_session.state == "running" and Engine.max_fps == 10, "Hide preserves explicitly running focus and reduces refresh")
	app.desktop.show_pet()
	check(Engine.max_fps == 30, "Show restores chosen eco refresh")
	app._focus_action("pause")
	var previous: Dictionary = app.plan.to_dict()
	var transfer = load("res://study/plan_transfer.gd")
	var imported = load("res://study/study_plan.gd").new()
	var titles: Array[String] = ["分享的第一项", "分享的第二项"]
	imported.replace_content("导入目标", titles)
	var import_path := directory.path_join("shared.json")
	check(transfer.write_file(import_path, transfer.encode_template(imported.to_dict())) == OK, "Write real transfer file")
	app._import_file(import_path)
	check(app.plan.to_dict() == previous, "Import preview does not commit")
	app._confirm_import()
	check(app.plan.data.goal == "导入目标" and FileAccess.file_exists(app.store.path+".before-import"), "Confirmed import preserves separate checkpoint")
	var checkpoint: Variant = JSON.parse_string(FileAccess.get_file_as_string(app.store.path+".before-import"))
	check(checkpoint == previous, "Checkpoint contains actual pre-import progress")
	check(app.store.has_method("preview_checkpoint"), "Import checkpoint has a usable recovery preview")
	if app.store.has_method("preview_checkpoint"):
		check(app.store.preview_checkpoint().error == OK, "Preserved pre-import plan can be previewed for restoration")
	var stored := FileAccess.get_file_as_string(app.store.path)
	app._export_plan("template", app.store.path)
	check(FileAccess.get_file_as_string(app.store.path) == stored, "Export cannot overwrite live study storage")
	var pref_stored := FileAccess.get_file_as_string(app.preferences_path)
	app._export_plan("template", app.preferences_path)
	check(FileAccess.get_file_as_string(app.preferences_path) == pref_stored, "Export cannot overwrite preferences")
	var export_path := directory.path_join("exported-backup.json")
	app._export_plan("backup", export_path)
	check(transfer.read_file(export_path).error == OK, "Real backup export can be re-imported")
	var bad := FileAccess.open(directory.path_join("bad.json"), FileAccess.WRITE)
	bad.store_string("{bad")
	bad.close()
	var good: Dictionary = app.plan.to_dict()
	app._import_file(directory.path_join("bad.json"))
	app._confirm_import()
	check(app.plan.to_dict() == good, "Invalid import clears stale pending preview")
	app._set_companion_mode("bad")
	app._set_performance("bad")
	check(app.companion_mode == "natural" and app.performance_mode == "smooth", "Invalid options normalize safely")
	app._set_reduced_motion(false)
	app.panel_window.hide()
	app.settings_window.hide()
	app.pet.play_action(&"idle")
	app.scheduler._was_allowed = true
	app.scheduler._remaining = 0.001
	app._last_session_tick = Time.get_ticks_msec()-5000
	app._process(0.016)
	check(app.pet.current_action == &"idle", "Monotonic suspend gap resets ambient cooldown even when Godot delta is capped")
	app.companionship.restore(1800.0)
	app._show_settings()
	check(app.settings.companionship_info.text.contains("0.5"), "Reopening settings refreshes actual companionship statistics")
	app.free()
	await process_frame
	# A readable configuration format can still be corrupt: never overwrite both
	# bad copies with a fresh default on exit or when changing a setting.
	var faults := directory.path_join("corrupt-fixture")
	DirAccess.make_dir_recursive_absolute(faults)
	for name in ["preferences.cfg", "preferences.cfg.bak", "plan.json", "plan.json.bak"]:
		var file := FileAccess.open(faults.path_join(name), FileAccess.WRITE)
		file.store_string("[broken" if name.begins_with("preferences") else "{broken")
		file.close()
	OS.set_environment("CLOUD_DRAGON_DATA_DIR", faults)
	app = scene.instantiate()
	root.add_child(app)
	check(app.storage_blocked and app._preferences_blocked, "Both-corrupt plan and preferences enter protected mode")
	app._set_companion_mode("quiet")
	app._append_task("不能覆盖坏文件")
	app._save_preferences()
	check(FileAccess.get_file_as_string(faults.path_join("preferences.cfg")) == "[broken", "Bad preferences retained after settings change/save")
	check(FileAccess.get_file_as_string(faults.path_join("plan.json")) == "{broken", "Bad plan retained after attempted append")
	app.free()
	OS.set_environment("CLOUD_DRAGON_DATA_DIR", directory)
	await process_frame
	print("V016 INTEGRATION: ", failures, " failures")
	quit(0 if failures == 0 else 1)
