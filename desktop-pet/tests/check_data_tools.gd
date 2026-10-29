extends SceneTree

var failures := 0
var checks := 0
var base := ""
var Plan = load("res://study/study_plan.gd")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	base = OS.get_environment("CLOUD_DRAGON_TEST_DIR")
	if base.is_empty():
		printerr("Use an explicit isolated CLOUD_DRAGON_TEST_DIR")
		quit(1)
		return
	base = base.path_join("data-tools-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(base)
	_test_maintenance()
	_test_transfer()
	_test_plan_store()
	_test_preferences()
	load("res://tests/test_study.gd").run(check)
	load("res://tests/test_study.gd").run_store(check)
	print("Data tools: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _model():
	var model = Plan.new()
	var titles: Array[String] = ["重复名称", "重复名称"]
	model.replace_content("近期目标", titles)
	return model

func _test_maintenance() -> void:
	var model = _model()
	for method in ["append_task", "rename_current", "set_goal", "undo_current_complete"]:
		check(model.has_method(method), "maintenance provides " + method)
		if not model.has_method(method):
			return
	model.mark_current_complete()
	model.start_next()
	model.mark_current_complete()
	var before: Dictionary = model.to_dict()
	check(model.append_task("  第三项  ") == OK, "append after completed final task succeeds")
	check(model.data.current_id == before.current_id and model.data.tasks.slice(0, 2) == before.tasks, "append preserves stable IDs, current and completed progress")
	check(model.data.tasks[2].title == "第三项" and not model.data.tasks[2].completed, "append trims title and starts incomplete")
	check(model.start_next() == OK, "only explicit advance selects appended task")
	check(model.rename_current("新名称") == OK and model.set_goal("新目标") == OK, "rename current and goal succeed")
	check(model.data.tasks[2].id != before.tasks[1].id and model.data.tasks[0] == before.tasks[0], "rename keeps identity and previous task")
	model.mark_current_complete()
	var current_id: String = model.data.current_id
	check(model.undo_current_complete() == OK and model.undo_current_complete() == OK, "repeated undo is idempotent")
	check(not model.data.tasks[2].completed and model.data.tasks[1].completed and model.data.current_id == current_id, "undo only changes current completion without stepping back")
	before = model.to_dict()
	check(model.append_task(" ") == ERR_INVALID_DATA and model.rename_current("x".repeat(201)) == ERR_INVALID_DATA and model.set_goal("x".repeat(301)) == ERR_INVALID_DATA, "invalid edits reject blank and overlong content")
	check(model.to_dict() == before, "rejected edits leave model unchanged")
	var titles: Array[String] = []
	model.replace_content("", titles)
	check(model.rename_current("none") == ERR_DOES_NOT_EXIST and model.undo_current_complete() == ERR_DOES_NOT_EXIST, "empty list cannot rename or undo")
	check(model.append_task("唯一项") == OK and model.data.current_id == model.data.tasks[0].id, "append to empty selects first task")
	titles.clear()
	for index in 500:
		titles.append("任务%d" % index)
	model.replace_content("", titles)
	check(model.append_task("第501项") == ERR_INVALID_DATA and model.data.tasks.size() == 500, "append enforces 500-task limit")
	model = _model()
	model.data.tasks[0].id = "task_2"
	model.data.current_id = "task_2"
	check(model.append_task("碰撞") == OK and Plan.validate(model.to_dict()), "append avoids collision with arbitrary existing stable IDs")
	model = _model()
	model.mark_current_complete()
	model.start_next()
	model.mark_current_complete()
	before = model.to_dict()
	check(model.rename_current("修订已完成项") == OK and model.set_goal("修订目标") == OK, "completed current item can be revised")
	check(model.data.current_id == before.current_id and model.data.tasks[1].id == before.tasks[1].id and model.data.tasks[1].completed and model.data.tasks[0] == before.tasks[0], "revision preserves final completed state and prior progress")

func _test_transfer() -> void:
	if not ResourceLoader.exists("res://study/plan_transfer.gd"):
		check(false, "transfer tools exist")
		return
	var Transfer = load("res://study/plan_transfer.gd")
	var model = _model()
	model.mark_current_complete()
	model.start_next()
	model.mark_current_complete()
	var original: Dictionary = model.to_dict()
	var template: Dictionary = Transfer.encode_template(original)
	check(template == {"format": "warmjade-plan", "version": 1, "goal": "近期目标", "tasks": ["重复名称", "重复名称"]}, "template contains only goal and task text with format/version")
	var result: Dictionary = Transfer.decode(template)
	check(result.error == OK and result.kind == "template" and Plan.validate(result.plan), "template decodes to validated schema1")
	check(result.plan.current_id == result.plan.tasks[0].id and not result.plan.tasks[0].completed and not result.plan.tasks[1].completed, "template strips progress and resets current")
	var backup: Dictionary = Transfer.encode_backup(original)
	result = Transfer.decode(backup)
	check(result.error == OK and result.kind == "backup" and result.plan == original, "backup preserves IDs, current and completed final state")
	result.plan.tasks[0].title = "mutated"
	check(backup.plan == original and model.to_dict() == original, "decoded snapshot cannot mutate backup or source")
	for value in [null, [], {"format": "warmjade-plan", "version": 99, "goal": "", "tasks": []}, {"format": "warmjade-plan", "version": 1.5, "goal": "", "tasks": []}, {"format": "warmjade-plan", "version": "1", "goal": "", "tasks": []}, {"format": "other", "version": 1}, {"format": "warmjade-plan", "version": 1, "goal": 2, "tasks": []}, {"format": "warmjade-plan", "version": 1, "goal": "", "tasks": [2]}, {"format": "warmjade-plan-backup", "version": 1, "plan": {} }]:
		check(Transfer.decode(value).error != OK, "malformed/unknown transfer rejected: " + str(value))
	var malformed: Dictionary = template.duplicate(true)
	malformed.tasks = ["x".repeat(201)]
	check(Transfer.decode(malformed).error != OK, "overlong template task rejected")
	malformed.tasks = []
	malformed.tasks.resize(501)
	malformed.tasks.fill("task")
	check(Transfer.decode(malformed).error != OK, "overquantity template rejected")
	malformed = backup.duplicate(true)
	malformed.plan.tasks[0].completed = false
	check(Transfer.decode(malformed).error != OK, "backup rejects impossible manual progress ordering")
	malformed = template.duplicate(true)
	malformed.extra = "x".repeat(2_000_001)
	check(Transfer.decode(malformed).error != OK, "serialized transfer input is bounded even in unknown fields")
	check(Transfer.encode_template({}).is_empty() and Transfer.encode_backup({}).is_empty(), "encoders reject invalid source plans")
	var huge_plan: Dictionary = original.duplicate(true)
	huge_plan.tasks[0].id = "x".repeat(2_000_001)
	check(Transfer.encode_template(huge_plan).is_empty() and Transfer.encode_backup(huge_plan).is_empty(), "encoders reject oversized source plans before serialization")
	malformed = template.duplicate(true)
	malformed.version = true
	check(Transfer.decode(malformed).error != OK, "boolean cannot impersonate transfer version")
	malformed = backup.duplicate(true)
	malformed.version = 2
	check(Transfer.decode(malformed).error != OK, "unknown backup version rejected")
	check(Transfer.decode(original).error != OK, "raw schema1 file is not silently treated as previewed transfer")
	var empty_model = Plan.new()
	check(Transfer.decode(Transfer.encode_template(empty_model.to_dict())).error == OK, "empty template is valid")
	var boundary_titles: Array[String] = []
	for index in 500:
		boundary_titles.append("x".repeat(200))
	empty_model.replace_content("g".repeat(300), boundary_titles)
	check(Transfer.decode(Transfer.encode_template(empty_model.to_dict())).error == OK, "500 tasks and exact text boundaries accepted")
	var path := base.path_join("share.json")
	check(Transfer.write_file(path, template) == OK and Transfer.read_file(path).error == OK, "transfer writes and reads valid file")
	var saved := FileAccess.get_file_as_string(path)
	check(Transfer.write_file(path, {"invalid": true}) != OK and FileAccess.get_file_as_string(path) == saved, "rejected transfer write preserves existing file")
	check(Transfer.write_file(base.path_join("missing/export.json"), template) != OK, "export write failure is reported")
	write_text(path, "invalid json")
	check(Transfer.read_file(path).error != OK, "malformed JSON rejected")
	write_text(path, " ".repeat(2_000_001))
	check(Transfer.read_file(path).error != OK, "oversized external file rejected before parsing")
	check(Transfer.read_file(base.path_join("absent.json")).error == ERR_FILE_NOT_FOUND, "missing transfer distinguished from invalid file")

func _test_plan_store() -> void:
	var Store = load("res://study/plan_store.gd")
	var path := base.path_join("plan.json")
	var store = Store.new(path)
	for method in ["preview_backup", "import_plan"]:
		check(store.has_method(method), "plan store provides " + method)
		if not store.has_method(method):
			return
	var model = _model()
	var first: Dictionary = model.to_dict()
	check(store.save_plan(first) == OK, "plan initial save succeeds")
	model.mark_current_complete()
	var current: Dictionary = model.to_dict()
	check(store.save_plan(current) == OK, "plan subsequent save succeeds")
	check(same_plan(store.preview_backup().plan, first), "preview reads previous valid backup only")
	var imported: Dictionary = first.duplicate(true)
	imported.goal = "导入目标"
	check(store.import_plan(imported, current) == OK, "import saves valid candidate")
	check(same_plan(store.load_plan().plan, imported) and same_plan(Store.new(path + ".before-import").load_plan().plan, current), "import checkpoint preserves current before replacement")
	check(same_plan(store.preview_backup().plan, current), "regular backup still records previous valid save")
	check(store.import_plan({}, imported) == ERR_INVALID_DATA and same_plan(store.load_plan().plan, imported), "invalid import leaves current untouched")
	write_text(path, "broken primary")
	check(store.load_plan().recovered, "plan can recover from valid backup")
	check(store.save_plan(imported) == OK and same_plan(store.preview_backup().plan, current), "recovered save never replaces valid backup with corrupt primary")
	write_text(path, "broken primary")
	write_text(path + ".bak", "broken backup")
	check(store.preview_backup().error == ERR_FILE_CORRUPT, "invalid backup cannot preview as empty replacement")
	check(store.save_plan(first) == ERR_FILE_CORRUPT and FileAccess.get_file_as_string(path) == "broken primary", "ordinary save blocks when both stored copies corrupt")
	var failed_path := base.path_join("blocked-plan.json")
	var failed = Store.new(failed_path)
	failed.save_plan(current)
	DirAccess.make_dir_absolute(failed_path + ".before-import")
	check(failed.import_plan(imported, current) != OK and same_plan(failed.load_plan().plan, current), "checkpoint failure aborts import before current replacement")
	var protected_path := base.path_join("protected-plan.json")
	var protected = Store.new(protected_path)
	protected.save_plan(first)
	protected.save_plan(current)
	var saved_primary := FileAccess.get_file_as_string(protected_path)
	var saved_backup := FileAccess.get_file_as_string(protected_path + ".bak")
	DirAccess.make_dir_absolute(protected_path + ".bak.tmp")
	check(protected.save_plan(imported) != OK and FileAccess.get_file_as_string(protected_path) == saved_primary and FileAccess.get_file_as_string(protected_path + ".bak") == saved_backup, "failed backup copy preserves both valid plan files")
	var delayed_path := base.path_join("delayed-plan.json")
	var delayed = Store.new(delayed_path)
	delayed.save_plan(current)
	DirAccess.make_dir_absolute(delayed_path + ".tmp")
	check(delayed.import_plan(imported, current) != OK and same_plan(delayed.load_plan().plan, current) and same_plan(Store.new(delayed_path + ".before-import").load_plan().plan, current), "save failure after checkpoint keeps current plan and recoverable checkpoint")
	var oversized: Dictionary = first.duplicate(true)
	oversized.tasks[0].id = "x".repeat(2_000_001)
	oversized.current_id = oversized.tasks[0].id
	check(protected.save_plan(oversized) == ERR_INVALID_DATA, "plan serialized write is bounded to 2MB")

func _test_preferences() -> void:
	if not ResourceLoader.exists("res://study/preferences_store.gd"):
		check(false, "preferences store exists")
		return
	var Store = load("res://study/preferences_store.gd")
	var path := base.path_join("preferences.cfg")
	var result: Dictionary = Store.load_config(path)
	check(result.error == ERR_FILE_NOT_FOUND and result.config is ConfigFile and not result.recovered, "missing preferences returns safe ConfigFile and distinct error")
	var config := ConfigFile.new()
	config.set_value("extension", "future_value", {"unknown": ["preserved", 7]})
	config.set_value("pet", "performance", "smooth")
	check(Store.save_config(path, config) == OK, "preferences first save succeeds")
	config.set_value("pet", "performance", "eco")
	check(Store.save_config(path, config) == OK, "preferences next save succeeds")
	result = Store.load_config(path)
	check(result.error == OK and result.config.get_value("extension", "future_value") == {"unknown": ["preserved", 7]}, "preferences preserve unknown configuration fields")
	write_text(path, "[broken")
	result = Store.load_config(path)
	check(result.error == OK and result.recovered and result.config.get_value("pet", "performance") == "smooth", "corrupt preferences primary recovers actual previous config")
	check(Store.save_config(path, config) == OK, "preferences recovered save can retry")
	write_text(path, "[broken")
	result = Store.load_config(path)
	check(result.error == OK and result.recovered and result.config.get_value("pet", "performance") == "smooth", "recovered save preserves valid backup instead of corrupt source")
	write_text(path + ".bak", "[broken backup")
	result = Store.load_config(path)
	check(result.error == ERR_FILE_CORRUPT and result.config.get_sections().is_empty(), "two corrupt preferences return error and fresh safe config")
	check(Store.save_config(path, config) == ERR_FILE_CORRUPT and FileAccess.get_file_as_string(path) == "[broken", "two corrupt preferences block automatic overwrite")
	check(Store.save_config(base.path_join("missing/preferences.cfg"), config) != OK, "preferences failed write reported")
	var valid_path := base.path_join("protected.cfg")
	Store.save_config(valid_path, config)
	var saved := FileAccess.get_file_as_string(valid_path)
	DirAccess.make_dir_absolute(valid_path + ".tmp")
	config.set_value("pet", "performance", "smooth")
	check(Store.save_config(valid_path, config) != OK and FileAccess.get_file_as_string(valid_path) == saved, "preferences tmp failure leaves persisted settings unchanged")
	var protected_path := base.path_join("backup-protected.cfg")
	Store.save_config(protected_path, config)
	config.set_value("pet", "performance", "eco")
	Store.save_config(protected_path, config)
	var saved_primary := FileAccess.get_file_as_string(protected_path)
	var saved_backup := FileAccess.get_file_as_string(protected_path + ".bak")
	DirAccess.make_dir_absolute(protected_path + ".bak.tmp")
	check(Store.save_config(protected_path, config) != OK and FileAccess.get_file_as_string(protected_path) == saved_primary and FileAccess.get_file_as_string(protected_path + ".bak") == saved_backup, "failed preferences backup copy preserves both valid files")
	var huge := ConfigFile.new()
	huge.set_value("extension", "huge", "x".repeat(2_000_001))
	check(Store.save_config(base.path_join("huge.cfg"), huge) != OK, "preferences serialized write bounded to 2MB")
	write_text(base.path_join("huge-read.cfg"), " ".repeat(2_000_001))
	check(Store.load_config(base.path_join("huge-read.cfg")).error == ERR_FILE_CORRUPT, "oversized serialized preferences rejected")

func write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		check(false, "test fixture writable: " + path)
		return
	file.store_string(content)
	file.close()

func same_plan(left: Variant, right: Dictionary) -> bool:
	# JSON parses schema_version as a float; dictionary equality is type-sensitive.
	return Plan.validate(left) and left.goal == right.goal and left.current_id == right.current_id and left.tasks == right.tasks
