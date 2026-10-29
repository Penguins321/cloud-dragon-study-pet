extends PanelContainer

signal complete_requested
signal next_requested
signal content_replace_requested(goal: String, titles: Array[String])
signal settings_requested
signal dismiss_requested
signal layout_changed

var current_label := Label.new()
var action_button := Button.new()
var _goal := Label.new()
var _status := Label.new()
var _list := VBoxContainer.new()
var _body := VBoxContainer.new()
var _editor := VBoxContainer.new()
var _goal_input := LineEdit.new()
var _titles_input := TextEdit.new()
var _message := Label.new()
var _confirm := ConfirmationDialog.new()
var _snapshot: Dictionary = {}
var _completed := false
var _font_level := 0

func set_font_level(level: int) -> void:
	_font_level = preload("res://ui/font_scale.gd").valid_level(level)
	preload("res://ui/font_scale.gd").apply(self,_font_level)

func _ready() -> void:
	var outer := VBoxContainer.new()
	add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "学习计划"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header, "收起", func(): dismiss_requested.emit())
	outer.add_child(HSeparator.new())
	outer.add_child(_body)
	_caption(_body, "近期目标")
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.max_lines_visible = 2
	_body.add_child(_goal)
	_body.add_child(HSeparator.new())
	_caption(_body, "当前任务")
	current_label.name = "CurrentTask"
	current_label.add_theme_font_size_override("font_size", 22)
	current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_label.max_lines_visible = 2
	current_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_body.add_child(current_label)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_status)
	action_button.name = "PrimaryAction"
	action_button.pressed.connect(func():
		if _completed:
			next_requested.emit()
		else:
			complete_requested.emit()
	)
	var primary: StyleBoxFlat = get_theme_stylebox("normal", "Button").duplicate()
	primary.bg_color = Color("2878ea")
	action_button.add_theme_stylebox_override("normal", primary)
	action_button.add_theme_color_override("font_color", Color.WHITE)
	_body.add_child(action_button)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 135
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(scroll)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var footer := HBoxContainer.new()
	_body.add_child(footer)
	_button(footer, "编辑清单", _open_editor)
	_button(footer, "设置", func(): settings_requested.emit())
	outer.add_child(_editor)
	_editor.hide()
	_caption(_editor, "近期目标")
	_goal_input.max_length = 300
	_editor.add_child(_goal_input)
	_caption(_editor, "每行一个任务，最多 500 项")
	_titles_input.custom_minimum_size.y = 220
	_titles_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.add_child(_titles_input)
	_caption(_editor, "替换清单会重置进度；原计划保留最近一次备份。")
	var actions := HBoxContainer.new()
	_editor.add_child(actions)
	_button(actions, "保存清单", _request_replace)
	_button(actions, "取消", func(): _editor.hide(); _body.show())
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color("aa453b"))
	outer.add_child(_message)
	_message.hide()
	_confirm.title = "确认替换学习清单"
	_confirm.dialog_text = "这会重置当前学习进度。确定使用新清单吗？"
	_confirm.ok_button_text = "替换并重置"
	_confirm.cancel_button_text = "取消"
	_confirm.theme = theme.duplicate(true)
	_confirm.theme.set_stylebox("panel","AcceptDialog",get_theme_stylebox("panel","PanelContainer").duplicate())
	_confirm.theme.set_color("font_focus_color","Button",Color("193d70"))
	add_child(_confirm)
	_confirm.confirmed.connect(_submit_replace)
	_editor.visibility_changed.connect(func(): layout_changed.emit())
	_message.visibility_changed.connect(func(): layout_changed.emit())

func render_plan(plan: Dictionary) -> void:
	_snapshot = plan.duplicate(true)
	_goal.text = plan.goal if not plan.goal.is_empty() else "还没有设置近期目标"
	var current: Dictionary = {}
	var index := -1
	for i in plan.tasks.size():
		if plan.tasks[i].id == plan.current_id:
			current = plan.tasks[i]
			index = i
	_completed = current.get("completed", false)
	current_label.text = current.get("title", "还没有学习任务")
	current_label.tooltip_text = current_label.text
	_status.text = "已完成 · 准备好后，再开始下一项" if _completed else "进行中 · 按自己的节奏学习"
	action_button.text = "开始下一项" if _completed else "标记完成"
	action_button.disabled = current.is_empty() or (_completed and index == plan.tasks.size() - 1)
	if current.is_empty():
		_status.text = "点击编辑清单，添加你的第一个目标"
	elif action_button.disabled:
		action_button.text = "本轮清单已完成"
	for child in _list.get_children():
		child.free()
	for task in plan.tasks:
		var row := Label.new()
		row.text = ("✓  " if task.completed else "○  ") + task.title
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.tooltip_text = task.title
		if task.id == plan.current_id:
			row.add_theme_color_override("font_color", Color("2469bc"))
		_list.add_child(row)
	_editor.hide()
	_body.show()
	_message.hide()
	set_font_level(_font_level)

func show_error(message: String) -> void:
	_message.text = message
	_message.show()

func _open_editor() -> void:
	_goal_input.text = _snapshot.goal
	var titles := PackedStringArray()
	for task in _snapshot.tasks:
		titles.append(task.title)
	_titles_input.text = "\n".join(titles)
	_body.hide()
	_editor.show()
	_goal_input.grab_focus()

func _request_replace() -> void:
	var titles := _get_titles()
	var model = preload("res://study/study_plan.gd").new()
	if model.replace_content(_goal_input.text, titles) != OK:
		show_error("请检查清单：每项 1–200 字，最多 500 项。")
		return
	_confirm.popup_centered(Vector2i(360, 150))

func _get_titles() -> Array[String]:
	var titles: Array[String] = []
	for line in _titles_input.text.split("\n"):
		if not line.strip_edges().is_empty():
			titles.append(line.strip_edges())
	return titles

func _submit_replace() -> void:
	content_replace_requested.emit(_goal_input.text, _get_titles())

func _caption(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
