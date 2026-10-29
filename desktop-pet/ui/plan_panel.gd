extends PanelContainer

signal complete_requested
signal next_requested
signal content_replace_requested(goal: String, titles: Array[String])
signal settings_requested
signal dismiss_requested
signal layout_changed
signal append_requested(title: String)
signal details_requested(goal: String, title: String)
signal undo_requested
signal focus_requested(action: String, minutes: int)

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
var _message_row := HBoxContainer.new()
var _confirm := ConfirmationDialog.new()
var _snapshot: Dictionary = {}
var _completed := false
var _font_level := 0
var body_scroll := ScrollContainer.new()
var focus_card := preload("res://ui/focus_card.gd").new()
var _append_input := LineEdit.new()
var _details_goal := LineEdit.new()
var _details_title := LineEdit.new()
var _details_dialog := ConfirmationDialog.new()
var _details_error := Label.new()
var _undo_button := Button.new()
var _progress_label := Label.new()
var _progress := ProgressBar.new()

func set_font_level(level: int) -> void:
	_font_level = preload("res://ui/font_scale.gd").valid_level(level)
	preload("res://ui/font_scale.gd").apply(self,_font_level)

func _ready() -> void:
	if theme == null: theme = preload("res://ui/study_theme.tres")
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",12)
	add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "学习计划"
	title.add_theme_font_size_override("font_size",24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header,"设置",func(): settings_requested.emit())
	_button(header,"收起",func(): dismiss_requested.emit())
	body_scroll.name = "PlanBodyScroll"
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.follow_focus = true
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.custom_minimum_size.y = 180
	outer.add_child(body_scroll)
	var pages := VBoxContainer.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(pages)
	pages.add_child(_body)
	var current := _card(_body)
	_caption(current,"近期目标")
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.add_child(_goal)
	current.add_child(HSeparator.new())
	_caption(current,"现在，专心做好这一件")
	current_label.name = "CurrentTask"
	current_label.add_theme_font_size_override("font_size",22)
	current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.add_child(current_label)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size",13)
	current.add_child(_status)
	action_button.name = "PrimaryAction"
	action_button.pressed.connect(func():
		if _completed: next_requested.emit()
		else: complete_requested.emit()
	)
	var primary := get_theme_stylebox("normal","Button").duplicate() as StyleBoxFlat
	primary.bg_color = Color("356854")
	action_button.add_theme_stylebox_override("normal",primary)
	var primary_hover := primary.duplicate() as StyleBoxFlat
	primary_hover.bg_color = Color("2c5948")
	action_button.add_theme_stylebox_override("hover",primary_hover)
	action_button.add_theme_stylebox_override("pressed",primary_hover)
	action_button.add_theme_color_override("font_color",Color("fffef6"))
	action_button.add_theme_color_override("font_hover_color",Color("fffef6"))
	action_button.add_theme_color_override("font_pressed_color",Color("fffef6"))
	action_button.add_theme_color_override("font_focus_color",Color("fffef6"))
	current.add_child(action_button)
	_undo_button.text = "撤销当前完成"
	_undo_button.pressed.connect(func(): undo_requested.emit())
	current.add_child(_undo_button)
	_body.add_child(focus_card)
	focus_card.focus_requested.connect(func(action,minutes): focus_requested.emit(action,minutes))
	var progress_card := _card(_body)
	_progress_label.add_theme_font_size_override("font_size",14)
	progress_card.add_child(_progress_label)
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 6
	progress_card.add_child(_progress)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation",10)
	progress_card.add_child(_list)
	var maintenance := _card(_body)
	_caption(maintenance,"让清单跟上你的节奏")
	_append_input.placeholder_text = "输入一个新任务"
	_append_input.max_length = 200
	_append_input.accessibility_name = "追加任务标题"
	maintenance.add_child(_append_input)
	_button(maintenance,"追加任务",_request_append)
	_append_input.text_submitted.connect(func(_text): _request_append())
	_button(maintenance,"修订当前内容",_open_details)
	_button(maintenance,"编辑整份清单",_open_editor)
	_caption(maintenance,"追加与修订保留进度；整单替换会重新开始。")
	pages.add_child(_editor)
	_editor.hide()
	_caption(_editor,"近期目标")
	_goal_input.max_length = 300
	_editor.add_child(_goal_input)
	_caption(_editor,"每行一个任务，最多 500 项")
	_titles_input.custom_minimum_size.y = 220
	_titles_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.add_child(_titles_input)
	_caption(_editor,"替换清单会重置进度；原计划保留最近一次备份。")
	_button(_editor,"保存清单",_request_replace)
	_button(_editor,"取消",func(): _editor.hide(); _body.show())
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(_message_row)
	_message_row.add_child(_message)
	var dismiss_notice := _button(_message_row,"×",func(): _message.hide(); _message_row.hide())
	dismiss_notice.accessibility_name = "关闭提示"
	dismiss_notice.tooltip_text = "关闭提示"
	dismiss_notice.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dismiss_notice.add_theme_font_size_override("font_size",16)
	_message.hide()
	_message_row.hide()
	_confirm.title = "确认替换学习清单"
	_confirm.dialog_text = "这会重置当前学习进度。确定使用新清单吗？"
	_confirm.ok_button_text = "替换并重置"
	_confirm.cancel_button_text = "取消"
	_confirm.theme = theme.duplicate(true)
	add_child(_confirm)
	_confirm.confirmed.connect(_submit_replace)
	_details_dialog.title = "修订当前内容 · 保留进度"
	_details_dialog.ok_button_text = "保存修订"
	_details_dialog.cancel_button_text = "取消"
	_details_dialog.dialog_hide_on_ok = false
	_details_dialog.theme = theme.duplicate(true)
	add_child(_details_dialog)
	var details := VBoxContainer.new()
	_details_dialog.add_child(details)
	_caption(details,"近期目标")
	_details_goal.max_length = 300
	_details_goal.accessibility_name = "修订近期目标"
	details.add_child(_details_goal)
	_caption(details,"当前任务标题")
	_details_title.max_length = 200
	_details_title.accessibility_name = "修订当前任务标题"
	details.add_child(_details_title)
	_details_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_error.add_theme_color_override("font_color",Color("a24c3f"))
	_details_error.hide()
	details.add_child(_details_error)
	_details_dialog.confirmed.connect(func(): details_requested.emit(_details_goal.text,_details_title.text))
	_editor.visibility_changed.connect(func(): layout_changed.emit())
	_message.visibility_changed.connect(func():
		_message_row.visible = _message.visible
		layout_changed.emit()
	)

func render_plan(plan: Dictionary) -> void:
	_details_dialog.hide()
	_snapshot = plan.duplicate(true)
	_goal.text = plan.goal if not plan.goal.is_empty() else "还没有设置近期目标"
	var current: Dictionary = {}
	var index := -1
	var completed_count := 0
	for i in plan.tasks.size():
		if plan.tasks[i].completed: completed_count += 1
		if plan.tasks[i].id == plan.current_id:
			current = plan.tasks[i]
			index = i
	_completed = current.get("completed",false)
	current_label.text = current.get("title","还没有学习任务")
	current_label.tooltip_text = current_label.text
	_status.text = "已完成 · 准备好后，再开始下一项" if _completed else "进行中 · 按自己的节奏学习"
	action_button.text = "开始下一项" if _completed else "标记完成"
	action_button.disabled = current.is_empty() or (_completed and index == plan.tasks.size()-1)
	_undo_button.visible = _completed
	if current.is_empty(): _status.text = "编辑清单，添加你的第一个目标"
	elif action_button.disabled: action_button.text = "本轮清单已完成"
	_progress_label.text = "清单进度   %d / %d 已完成" % [completed_count,plan.tasks.size()]
	_progress.max_value = maxi(1,plan.tasks.size())
	_progress.value = completed_count
	for child in _list.get_children(): child.free()
	for task in plan.tasks:
		var row := Label.new()
		row.text = ("✓  " if task.completed else "○  ") + task.title
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.tooltip_text = task.title
		if task.id == plan.current_id: row.add_theme_color_override("font_color",Color("2b7057"))
		_list.add_child(row)
	_editor.hide()
	_body.show()
	_message.hide()
	set_font_level(_font_level)

func set_focus_state(state: Dictionary) -> void:
	focus_card.set_focus_state(state)
	set_font_level(_font_level)

func show_error(message: String) -> void:
	if _details_dialog.visible:
		_details_error.text = message
		_details_error.show()
		return
	_message.add_theme_color_override("font_color",Color("a24c3f"))
	_message.text = message
	_message_row.show()
	_message.show()

func show_notice(text: String) -> void:
	_message.add_theme_color_override("font_color",Color("356854"))
	_message.text = text
	_message_row.show()
	_message.show()

func _request_append() -> void:
	var title := _append_input.text.strip_edges()
	if title.is_empty():
		show_error("先写下新任务的标题。")
		return
	append_requested.emit(title)

func _open_details() -> void:
	_details_error.hide()
	_details_goal.text = _snapshot.get("goal","")
	_details_title.text = ""
	for task in _snapshot.get("tasks",[]):
		if task.id == _snapshot.current_id: _details_title.text = task.title
	_details_title.editable = not _details_title.text.is_empty()
	_details_dialog.popup_centered(Vector2i(420,220))
	_details_goal.grab_focus()

func _open_editor() -> void:
	_goal_input.text = _snapshot.get("goal","")
	var titles := PackedStringArray()
	for task in _snapshot.get("tasks",[]): titles.append(task.title)
	_titles_input.text = "\n".join(titles)
	_body.hide()
	_editor.show()
	_goal_input.grab_focus()

func _request_replace() -> void:
	var model = preload("res://study/study_plan.gd").new()
	if model.replace_content(_goal_input.text,_get_titles()) != OK:
		show_error("请检查清单：每项 1–200 字，最多 500 项。")
		return
	_confirm.popup_centered(Vector2i(360,180))

func _get_titles() -> Array[String]:
	var titles: Array[String] = []
	for line in _titles_input.text.split("\n"):
		if not line.strip_edges().is_empty(): titles.append(line.strip_edges())
	return titles

func _submit_replace() -> void:
	content_replace_requested.emit(_goal_input.text,_get_titles())

func _caption(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",13)
	label.add_theme_color_override("font_color",Color("6b7c6b"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffef8")
	style.border_color = Color("dce4d7")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	return box
