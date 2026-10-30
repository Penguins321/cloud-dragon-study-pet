extends PanelContainer

signal send_requested(text: String)
signal cancel_requested
signal preferences_requested(values: Array[String])
signal persona_requested(value: String)
signal clear_history_requested
signal dismiss_requested

const FontScale = preload("res://ui/font_scale.gd")
var message_input := TextEdit.new()
var send_button := Button.new()
var cancel_button := Button.new()
var status_label := Label.new()
var history_scroll := ScrollContainer.new()
var history_box := VBoxContainer.new()
var preferences_input := TextEdit.new()
var persona_input := TextEdit.new()
var preferences_save_button := Button.new()
var persona_save_button := Button.new()
var clear_history_button := Button.new()
var dismiss_button := Button.new()
var category_tabs := TabContainer.new()
var memory_scroll := ScrollContainer.new()
var _busy := false
var _font_level := 0
var _preferences_snapshot := ""
var _persona_snapshot := ""
var _companion_name := ""
var _persona_drafts: Dictionary = {}

func _init() -> void:
	# Wrapped labels briefly report tall minima before their width settles.
	# A scroll boundary keeps those transient heights out of the native window.
	var body_scroll := ScrollContainer.new()
	_scroll(body_scroll)
	add_child(body_scroll)
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation",8)
	body_scroll.add_child(outer)
	_label(outer,"和伙伴聊一会儿",20)
	category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(category_tabs)
	var chat := VBoxContainer.new()
	chat.name = "聊天"
	chat.add_theme_constant_override("separation",8)
	category_tabs.add_child(chat)
	_label(chat,"对话会发送给设置中选定的服务商；自主陪伴关闭时也可聊天。")
	_scroll(history_scroll)
	history_scroll.custom_minimum_size.y = 100
	chat.add_child(history_scroll)
	history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_box.add_theme_constant_override("separation",12)
	history_scroll.add_child(history_box)
	_editor(chat,message_input,"输入想说的话（最多 1000 字）",72)
	_button(chat,send_button,"发送",_send)
	_button(chat,cancel_button,"取消回复",func(): cancel_requested.emit())
	_scroll(memory_scroll)
	memory_scroll.name = "记忆与性格"
	category_tabs.add_child(memory_scroll)
	var memory := VBoxContainer.new()
	memory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	memory.add_theme_constant_override("separation",8)
	memory_scroll.add_child(memory)
	_label(memory,"最近对话、已保存偏好和当前伙伴性格会发送给选定服务商；自主陪伴也可能使用偏好。记忆保存在本机，可在此修改或删除。")
	_label(memory,"长期偏好（每行一条）",16)
	_label(memory,"最多 20 条，每条 160 字。删除对应行后保存即可移除；留空保存可清空全部偏好。聊天原文仍保留，需要时可另外清空。")
	_editor(memory,preferences_input,"例如：喜欢简短的回复",120)
	_button(memory,preferences_save_button,"保存长期偏好",_save_preferences)
	_label(memory,"当前伙伴性格",16)
	_label(memory,"只影响当前角色，最多 600 字；修改后保存。")
	_editor(memory,persona_input,"描述伙伴稳定的语气与性格",120)
	_button(memory,persona_save_button,"保存当前伙伴性格",_save_persona)
	_label(memory,"清空仅删除当前伙伴的对话记录，偏好与性格保留。")
	_button(memory,clear_history_button,"清空当前伙伴对话",func(): clear_history_requested.emit())
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",12)
	outer.add_child(status_label)
	_button(outer,dismiss_button,"收起",func(): dismiss_requested.emit())
	set_status("")

func _ready() -> void:
	if theme == null: theme = preload("res://ui/study_theme.tres")

func _label(parent: Node, text: String, font_size := 12) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _scroll(scroll: ScrollContainer) -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true

func _editor(parent: Node, editor: TextEdit, placeholder: String, height: int) -> void:
	editor.placeholder_text = placeholder
	editor.accessibility_name = placeholder
	editor.custom_minimum_size.y = height
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	parent.add_child(editor)

func _button(parent: Node, button: Button, text: String, callback: Callable) -> void:
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)

func set_conversation(messages: Array, companion_name: String) -> void:
	if companion_name != _companion_name:
		_persona_drafts[_companion_name] = {"text":persona_input.text,"snapshot":_persona_snapshot}
		_companion_name = companion_name
		var draft: Dictionary = _persona_drafts.get(companion_name,{"text":"","snapshot":""})
		persona_input.text = draft.text
		_persona_snapshot = draft.snapshot
	for child in history_box.get_children():
		child.free()
	for entry in messages:
		if not entry is Dictionary: continue
		var role := str(entry.get("role",""))
		if role not in ["user","assistant"]: continue
		var speaker := "我" if role == "user" else companion_name
		_label(history_box,speaker + "：\n" + str(entry.get("content","")),14)
	FontScale.apply(history_box,_font_level)
	_scroll_to_latest.call_deferred()

func _scroll_to_latest() -> void:
	if not is_inside_tree(): return
	var next_frame := get_tree().process_frame
	if not next_frame.is_connected(_scroll_after_layout):
		next_frame.connect(_scroll_after_layout,CONNECT_ONE_SHOT)

func _scroll_after_layout() -> void:
	if not is_inside_tree(): return
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)

func set_memories(preferences: Array[String], persona: String) -> void:
	var preferences_clean := preferences_input.text == _preferences_snapshot
	var persona_clean := persona_input.text == _persona_snapshot
	_preferences_snapshot = "\n".join(preferences)
	_persona_snapshot = persona
	if preferences_clean: preferences_input.text = _preferences_snapshot
	if persona_clean: persona_input.text = persona

func accept_preferences(values: Array[String]) -> void:
	_preferences_snapshot = "\n".join(values)
	preferences_input.text = _preferences_snapshot

func accept_persona(value: String) -> void:
	_persona_snapshot = value
	persona_input.text = value

func set_status(message: String, busy: bool = false) -> void:
	_busy = busy
	status_label.text = message
	send_button.disabled = busy
	cancel_button.disabled = not busy

func set_font_level(level: int) -> void:
	_font_level = FontScale.valid_level(level)
	FontScale.apply(self,_font_level)
	var bar := category_tabs.get_tab_bar()
	if not bar.has_meta("normal_font_size"):
		bar.set_meta("normal_font_size",bar.get_theme_font_size("font_size"))
	bar.add_theme_font_size_override("font_size",roundi(int(bar.get_meta("normal_font_size"))*FontScale.FACTORS[_font_level]))

func _send() -> void:
	if _busy: return
	var text := message_input.text.strip_edges()
	if text.is_empty() or text.length() > 1000:
		set_status("请输入 1 至 1000 字的消息。")
		return
	send_requested.emit(text)

func _save_preferences() -> void:
	var values: Array[String] = []
	for line in preferences_input.text.split("\n"):
		var value := line.strip_edges()
		if value.is_empty(): continue
		if value.length() > 160:
			status_label.text = "每条偏好最多 160 字，请缩短后保存。"
			return
		values.append(value)
	if values.size() > 20:
		status_label.text = "最多保存 20 条偏好，请减少后保存。"
		return
	preferences_requested.emit(values)

func _save_persona() -> void:
	var value := persona_input.text.strip_edges()
	if value.length() > 600:
		status_label.text = "伙伴性格最多 600 字，请缩短后保存。"
		return
	persona_requested.emit(value)
