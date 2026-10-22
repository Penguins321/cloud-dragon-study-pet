extends RefCounted

static func run(check: Callable) -> void:
	var Plan = load("res://study/study_plan.gd")
	var model = Plan.new()
	var titles: Array[String] = ["单例模式", "工厂模式"]
	check.call(model.replace_content("每天学习", titles) == OK, "create study list")
	if model.data.tasks.is_empty():
		return
	var first_id: String = model.data.current_id
	check.call(model.start_next() == ERR_UNAVAILABLE, "unfinished task cannot advance")
	check.call(model.mark_current_complete() == OK, "mark current task complete")
	check.call(model.data.current_id == first_id, "completion retains current task")
	check.call(model.mark_current_complete() == OK, "completion is idempotent")
	check.call(model.start_next() == OK and model.data.tasks[1].id == model.data.current_id, "explicit next advances")
	model.mark_current_complete()
	check.call(model.start_next() == ERR_DOES_NOT_EXIST, "final completed task does not wrap")
	var snapshot: Dictionary = model.to_dict()
	snapshot.tasks.clear()
	check.call(model.data.tasks.size() == 2, "snapshot mutation cannot corrupt model")
	check.call(Plan.validate(model.to_dict()), "valid completed plan can reload")
	var broken: Dictionary = model.to_dict()
	broken.schema_version = 99
	check.call(not Plan.validate(broken), "unknown schema rejected")
	broken = model.to_dict()
	broken.tasks[1].id = broken.tasks[0].id
	check.call(not Plan.validate(broken), "duplicate task IDs rejected")
	broken = model.to_dict()
	broken.tasks[0].completed = "yes"
	check.call(not Plan.validate(broken), "malformed completion type rejected")
	var empty: Array[String] = []
	check.call(model.replace_content("", empty) == OK, "empty list is valid")
	check.call(model.mark_current_complete() == ERR_DOES_NOT_EXIST, "empty list has no completable task")
	var invalid_titles: Array[String] = [""]
	check.call(model.replace_content("", invalid_titles) == ERR_INVALID_DATA, "blank task rejected")

static func run_store(check: Callable) -> void:
	var Plan = load("res://study/study_plan.gd")
	var Store = load("res://study/plan_store.gd")
	var model = Plan.new()
	var titles: Array[String] = ["单例模式", "工厂模式"]
	model.replace_content("学习", titles)
	if model.data.tasks.is_empty():
		return
	var base := OS.get_environment("CLOUD_DRAGON_TEST_DIR")
	if base.is_empty():
		check.call(false, "test data directory must be explicitly isolated")
		return
	base = base.path_join(str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(base)
	var path := base.path_join("plan.json")
	var store = Store.new(path)
	check.call(store.load_plan().error == ERR_FILE_NOT_FOUND, "missing plan is distinguished from corruption")
	check.call(store.save_plan(model.to_dict()) == OK, "save first plan")
	if not FileAccess.file_exists(path):
		return
	model.mark_current_complete()
	check.call(store.save_plan(model.to_dict()) == OK, "save second plan and backup")
	check.call(store.load_plan().plan.tasks[0].completed == true, "saved completion reloads")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken JSON")
	file.close()
	var result: Dictionary = store.load_plan()
	check.call(result.error == OK and result.recovered, "corrupt main recovers backup")
	check.call(result.plan.tasks[0].completed == false, "backup holds actual previous saved state")
	file = FileAccess.open(path + ".bak", FileAccess.WRITE)
	file.store_string("also broken")
	file.close()
	check.call(store.load_plan().error == ERR_FILE_CORRUPT, "both corrupt files report error without reset")
	check.call(FileAccess.get_file_as_string(path) == "broken JSON", "failed recovery preserves damaged original")
	var blocked = Store.new(base.path_join("missing/plan.json"))
	check.call(blocked.save_plan(model.to_dict()) != OK, "failed write is not reported as success")
