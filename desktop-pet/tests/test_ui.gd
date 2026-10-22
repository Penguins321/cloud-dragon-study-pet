extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var scene = load("res://ui/plan_panel.tscn")
	var panel = scene.instantiate()
	tree.root.add_child(panel)
	var model = load("res://study/study_plan.gd").new()
	var titles: Array[String] = ["单例模式", "工厂模式"]
	model.replace_content("每天学习", titles)
	panel.render_plan(model.to_dict())
	check.call(panel.current_label.text == "单例模式", "UI shows current task")
	check.call(not panel.action_button.disabled, "current task can be completed")
	var received: Array[String] = []
	panel.complete_requested.connect(func(): received.append("complete"))
	panel.next_requested.connect(func(): received.append("next"))
	panel.action_button.pressed.emit()
	check.call(received == ["complete"], "active task emits completion request")
	model.mark_current_complete()
	panel.render_plan(model.to_dict())
	panel.action_button.pressed.emit()
	check.call(received == ["complete", "next"], "completed task emits only explicit next request")
	check.call(panel.current_label.text == "单例模式", "completed task remains current in UI")
	model.start_next()
	model.mark_current_complete()
	panel.render_plan(model.to_dict())
	check.call(panel.action_button.disabled, "all finished disables next button")
	var empty: Array[String] = []
	model.replace_content("", empty)
	panel.render_plan(model.to_dict())
	check.call(panel.action_button.disabled, "empty list disables action")
	var long_titles: Array[String] = ["长任务".repeat(60)]
	model.replace_content("长目标".repeat(80), long_titles)
	panel.render_plan(model.to_dict())
	check.call(panel.current_label.text == long_titles[0] and not panel.action_button.disabled, "long title retains complete content and action")
	panel.free()
