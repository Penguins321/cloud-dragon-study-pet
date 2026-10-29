extends PanelContainer

signal focus_requested(action: String, minutes: int)

var clock_label := Label.new()
var title_label := Label.new()
var state_label := Label.new()
var minutes_input := SpinBox.new()
var primary_button := Button.new()
var cancel_button := Button.new()
var _state := "idle"
var _has_session_snapshot := false

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("eaf1e9")
	style.border_color = Color("c7d8c9")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	add_child(box)
	state_label.add_theme_font_size_override("font_size",13)
	box.add_child(state_label)
	clock_label.add_theme_font_size_override("font_size",34)
	clock_label.add_theme_color_override("font_color",Color("245849"))
	box.add_child(clock_label)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size",13)
	box.add_child(title_label)
	var duration := HBoxContainer.new()
	box.add_child(duration)
	var duration_label := Label.new()
	duration_label.text = "时长（分钟）"
	duration_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duration.add_child(duration_label)
	minutes_input.min_value = 5
	minutes_input.max_value = 120
	minutes_input.step = 1
	minutes_input.value = 25
	minutes_input.allow_greater = false
	minutes_input.allow_lesser = false
	minutes_input.accessibility_name = "专注时长，5 至 120 分钟"
	duration.add_child(minutes_input)
	minutes_input.value_changed.connect(func(_value):
		if _state in ["idle","finished"]: clock_label.text = _format_seconds(int(minutes_input.value)*60)
	)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button.pressed.connect(func():
		var action := "pause" if _state == "running" else ("resume" if _state == "paused" else "start")
		focus_requested.emit(action,int(minutes_input.value))
	)
	actions.add_child(primary_button)
	cancel_button.text = "结束本次"
	cancel_button.pressed.connect(func(): focus_requested.emit("cancel",int(minutes_input.value)))
	actions.add_child(cancel_button)
	set_focus_state({})

func set_focus_state(snapshot: Dictionary) -> void:
	_state = snapshot.get("state","idle")
	var active := _state in ["running","paused"]
	if snapshot.has("duration_seconds") and float(snapshot.duration_seconds) > 0:
		if active or not _has_session_snapshot:
			minutes_input.set_value_no_signal(clampf(float(snapshot.duration_seconds)/60.0,5,120))
		_has_session_snapshot = true
	minutes_input.editable = not active
	cancel_button.visible = active
	primary_button.text = "暂停" if _state == "running" else ("继续" if _state == "paused" else "开始专注")
	state_label.text = {"idle":"专注一会儿","running":"正在专注 · 玉核静静陪伴","paused":"已暂停 · 随时继续","finished":"本次专注已完成"}.get(_state,"专注一会儿")
	var shown_seconds := int(minutes_input.value)*60 if _state == "idle" else ceili(float(snapshot.get("remaining_seconds",int(minutes_input.value)*60)))
	clock_label.text = _format_seconds(shown_seconds)
	title_label.text = snapshot.get("task_title","") if active or _state == "finished" else "计时独立于清单；任务完成后，由你手动标记。"
	if title_label.text.is_empty(): title_label.text = "自由专注"

func _format_seconds(value: int) -> String:
	var seconds := maxi(0,value)
	return "%02d:%02d" % [seconds / 60,seconds % 60]
