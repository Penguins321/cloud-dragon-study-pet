extends RefCounted

var data := {"schema_version": 1, "goal": "", "tasks": [], "current_id": ""}

func to_dict() -> Dictionary:
	return data.duplicate(true)

func replace_content(goal: String, titles: Array[String]) -> Error:
	if goal.length() > 300 or titles.size() > 500:
		return ERR_INVALID_DATA
	var tasks: Array = []
	for index in titles.size():
		var title := titles[index].strip_edges()
		if title.is_empty() or title.length() > 200:
			return ERR_INVALID_DATA
		tasks.append({"id": "task_%d" % index, "title": title, "completed": false})
	data = {"schema_version": 1, "goal": goal.strip_edges(), "tasks": tasks, "current_id": "task_0" if not tasks.is_empty() else ""}
	return OK

func append_task(title: String) -> Error:
	var cleaned := title.strip_edges()
	if cleaned.is_empty() or cleaned.length() > 200 or data.tasks.size() >= 500:
		return ERR_INVALID_DATA
	var ids: Array[String] = []
	for task in data.tasks:
		ids.append(task.id)
	var suffix: int = data.tasks.size()
	while ids.has("task_%d" % suffix):
		suffix += 1
	var id := "task_%d" % suffix
	data.tasks.append({"id": id, "title": cleaned, "completed": false})
	if data.tasks.size() == 1:
		data.current_id = id
	return OK

func rename_current(title: String) -> Error:
	var cleaned := title.strip_edges()
	if cleaned.is_empty() or cleaned.length() > 200:
		return ERR_INVALID_DATA
	for task in data.tasks:
		if task.id == data.current_id:
			task.title = cleaned
			return OK
	return ERR_DOES_NOT_EXIST

func set_goal(goal: String) -> Error:
	if goal.length() > 300:
		return ERR_INVALID_DATA
	data.goal = goal.strip_edges()
	return OK

func undo_current_complete() -> Error:
	for task in data.tasks:
		if task.id == data.current_id:
			task.completed = false
			return OK
	return ERR_DOES_NOT_EXIST

func mark_current_complete() -> Error:
	for task in data.tasks:
		if task.id == data.current_id:
			task.completed = true
			return OK
	return ERR_DOES_NOT_EXIST

func start_next() -> Error:
	for index in data.tasks.size():
		if data.tasks[index].id == data.current_id:
			if not data.tasks[index].completed:
				return ERR_UNAVAILABLE
			if index + 1 >= data.tasks.size():
				return ERR_DOES_NOT_EXIST
			data.current_id = data.tasks[index + 1].id
			return OK
	return ERR_DOES_NOT_EXIST

static func validate(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema_version") != 1:
		return false
	if not value.get("goal") is String or value.goal.length() > 300 or not value.get("current_id") is String:
		return false
	if not value.get("tasks") is Array or value.tasks.size() > 500:
		return false
	var ids: Array[String] = []
	for task in value.tasks:
		if not task is Dictionary or not task.get("id") is String or task.id.is_empty() or ids.has(task.id):
			return false
		if not task.get("title") is String or task.title.strip_edges().is_empty() or task.title.length() > 200 or not task.get("completed") is bool:
			return false
		ids.append(task.id)
	if ids.is_empty():
		return value.current_id == ""
	if not ids.has(value.current_id):
		return false
	var current_index := ids.find(value.current_id)
	for index in value.tasks.size():
		if index < current_index and not value.tasks[index].completed:
			return false
		if index > current_index and value.tasks[index].completed:
			return false
	return true
