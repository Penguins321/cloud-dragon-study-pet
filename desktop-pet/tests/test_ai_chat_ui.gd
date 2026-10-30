extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not ResourceLoader.exists("res://ui/ai_chat_panel.gd"):
		check(false,"Chat panel must exist")
		quit(1)
		return
	var panel = load("res://ui/ai_chat_panel.gd").new()
	root.add_child(panel)
	check(panel.get_combined_minimum_size().y <= 668,"Initial wrapping cannot force a 720px window beyond its screen")
	panel.size = Vector2(410,680)
	var sent: Array = []
	var saved: Array = []
	var personas: Array = []
	var events: Array = []
	panel.send_requested.connect(func(text): sent.append(text))
	panel.preferences_requested.connect(func(values): saved.append(values))
	panel.persona_requested.connect(func(value): personas.append(value))
	panel.cancel_requested.connect(func(): events.append("cancel"))
	panel.clear_history_requested.connect(func(): events.append("clear"))
	panel.dismiss_requested.connect(func(): events.append("dismiss"))
	panel.message_input.text = " \n "
	panel.send_button.pressed.emit()
	panel.message_input.text = "字".repeat(1001)
	panel.send_button.pressed.emit()
	check(sent.is_empty() and not panel.status_label.text.is_empty(),"Blank and oversized chat never emit requests")
	panel.message_input.text = "  你好\n伙伴  "
	panel.send_button.pressed.emit()
	check(sent == ["你好\n伙伴"],"Send emits trimmed multiline text")
	panel.set_status("连接失败，请重试")
	check(panel.message_input.text == "  你好\n伙伴  ","Failed send preserves draft")
	panel.set_status("正在回复…",true)
	check(panel.send_button.disabled and not panel.cancel_button.disabled,"Busy blocks send but offers cancel")
	panel.send_button.pressed.emit()
	check(sent.size() == 1,"Busy state also rejects direct repeated submit")
	panel.cancel_button.pressed.emit()
	check(events.back() == "cancel","Cancel requests cancellation")
	panel.set_status("已取消")
	check(not panel.send_button.disabled and panel.cancel_button.disabled,"Cancel completion releases send")
	panel.message_input.text = "字".repeat(1000)
	panel.send_button.pressed.emit()
	check(sent.back().length() == 1000,"Message limit includes exactly 1000 characters")
	panel.message_input.text = "  你好\n伙伴  "
	panel.set_conversation([{"role":"user","content":"[b]你好[/b]"},{"role":"assistant","content":"<script>plain</script>"}],"小鸭")
	check(panel.history_box.get_child_count() == 2,"Conversation renders both messages")
	check(panel.history_box.get_child(0) is Label and panel.history_box.get_child(0).text.contains("[b]你好[/b]"),"Chat renders untrusted content as literal plain text")
	check(panel.history_box.get_child(1).text.contains("小鸭") and panel.history_box.get_child(1).text.contains("<script>plain</script>"),"Reply identifies current companion and retains literal content")
	check(panel.message_input.text == "  你好\n伙伴  ","Refreshing conversation preserves draft until root acknowledges success")
	var preferences: Array[String] = ["喜欢简短回复","称呼我为小林"]
	panel.set_memories(preferences,"温和、安静")
	check(panel.preferences_input.text == "喜欢简短回复\n称呼我为小林" and panel.persona_input.text == "温和、安静","Saved memories remain visible and editable")
	panel.preferences_input.text = " 第一条 \n\n第二条"
	panel.preferences_save_button.pressed.emit()
	check(saved == [["第一条","第二条"]],"Preference save trims lines and ignores blanks")
	panel.preferences_input.text = "条\n".repeat(21)
	panel.preferences_save_button.pressed.emit()
	panel.preferences_input.text = "字".repeat(161)
	panel.preferences_save_button.pressed.emit()
	check(saved.size() == 1,"Oversized preference list and entry are rejected")
	panel.preferences_input.text = ""
	panel.preferences_save_button.pressed.emit()
	check(saved.back().is_empty(),"Empty preference save allows deleting all preferences")
	panel.preferences_input.text = ("字".repeat(160) + "\n").repeat(20)
	panel.preferences_save_button.pressed.emit()
	check(saved.back().size() == 20 and saved.back()[0].length() == 160,"Preference limits accept exactly 20 entries of 160 characters")
	panel.persona_input.text = "字".repeat(601)
	panel.persona_save_button.pressed.emit()
	check(personas.is_empty(),"Oversized persona is rejected")
	panel.persona_input.text = " 新性格 "
	panel.persona_save_button.pressed.emit()
	check(personas == ["新性格"],"Persona save emits current editable text")
	panel.persona_input.text = "字".repeat(600)
	panel.persona_save_button.pressed.emit()
	check(personas.back().length() == 600,"Persona limit includes exactly 600 characters")
	panel.clear_history_button.pressed.emit()
	panel.dismiss_button.pressed.emit()
	check(events.slice(-2) == ["clear","dismiss"],"Clear history and dismiss delegate to host")
	for level in range(4):
		panel.set_font_level(level)
		for page in range(2):
			panel.category_tabs.current_tab = page
			panel.size = Vector2(410,680)
			await process_frame
			await process_frame
			check(panel.get_combined_minimum_size().x <= 410,"Chat and memory tabs fit narrow window at font level %d" % level)
			check(panel.size.y <= 680,"Chat and memory fit bounded height at font level %d" % level)
	check(panel.memory_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,"Memory tab uses vertical scrolling")
	panel.set_conversation([{"role":"assistant","content":"更新后的回复"}],"小鸭")
	check(panel.history_box.get_child(0).get_theme_font_size("font_size") == 24,"New replies retain selected largest font")
	panel.free()
	var drafts = load("res://ui/ai_chat_panel.gd").new()
	root.add_child(drafts)
	check(drafts.has_method("accept_preferences") and drafts.has_method("accept_persona"),"Separate save acknowledgments must exist")
	if not drafts.has_method("accept_preferences") or not drafts.has_method("accept_persona"):
		drafts.free()
		quit(1)
		return
	drafts.set_conversation([],"小鸭")
	var base: Array[String] = ["原偏好"]
	drafts.set_memories(base,"鸭性格")
	drafts.preferences_input.text = "未保存偏好"
	drafts.persona_input.text = "未保存鸭性格"
	drafts.message_input.grab_focus()
	drafts.category_tabs.current_tab = 0
	drafts.set_conversation([{"role":"assistant","content":"新的回复"}],"小鸭")
	drafts.set_memories(base,"鸭性格")
	check(drafts.preferences_input.text == "未保存偏好" and drafts.persona_input.text == "未保存鸭性格","Reply and focus/tab changes preserve both independent dirty drafts")
	var accepted: Array[String] = ["已保存偏好"]
	drafts.accept_preferences(accepted)
	check(drafts.preferences_input.text == "已保存偏好" and drafts.persona_input.text == "未保存鸭性格","Preference acceptance leaves persona draft intact")
	drafts.preferences_input.text = "第二版偏好草稿"
	drafts.accept_persona("已保存鸭性格")
	check(drafts.preferences_input.text == "第二版偏好草稿" and drafts.persona_input.text == "已保存鸭性格","Persona acceptance leaves preference draft intact")
	drafts.set_memories(accepted,"已保存鸭性格")
	check(drafts.preferences_input.text == "第二版偏好草稿","Refresh preserves dirty preferences after persona save")
	drafts.persona_input.text = "鸭角色草稿"
	drafts.set_conversation([],"柯基")
	drafts.set_memories(accepted,"柯基性格")
	check(drafts.preferences_input.text == "第二版偏好草稿" and drafts.persona_input.text == "柯基性格","Role switch retains global preferences and loads clean target persona")
	drafts.persona_input.text = "柯基角色草稿"
	drafts.set_conversation([],"小鸭")
	drafts.set_memories(accepted,"已保存鸭性格")
	check(drafts.persona_input.text == "鸭角色草稿","Returning to companion restores its unsaved persona")
	drafts.set_conversation([],"柯基")
	drafts.set_memories(accepted,"柯基性格")
	check(drafts.persona_input.text == "柯基角色草稿","Each companion retains its own unsaved persona")
	drafts.hide()
	drafts.show()
	drafts.set_memories(accepted,"柯基性格")
	check(drafts.preferences_input.text == "第二版偏好草稿" and drafts.persona_input.text == "柯基角色草稿","Closing and reopening preserves dirty editors")
	drafts.accept_preferences(accepted)
	drafts.accept_persona("柯基性格")
	var refreshed: Array[String] = ["外部保存的新偏好"]
	drafts.set_memories(refreshed,"外部保存的新性格")
	check(drafts.preferences_input.text == "外部保存的新偏好" and drafts.persona_input.text == "外部保存的新性格","Clean editors follow external persisted changes")
	drafts.free()
	var window := Window.new()
	window.visible = false
	window.size = Vector2i(520,720)
	window.min_size = Vector2i(360,420)
	root.add_child(window)
	var bounded = load("res://ui/ai_chat_panel.gd").new()
	window.add_child(bounded)
	bounded.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bounded.offset_top = 52
	for level in range(4):
		bounded.set_font_level(level)
		window.min_size = Vector2i(maxi(360,ceili(bounded.get_combined_minimum_size().x)),maxi(420,ceili(bounded.get_combined_minimum_size().y)+52))
		window.size = window.size.max(window.min_size)
		await process_frame
		await process_frame
		check(window.size == Vector2i(520,720),"Native-window fitting preserves 520x720 at font level %d" % level)
	window.free()
	var pending = load("res://ui/ai_chat_panel.gd").new()
	root.add_child(pending)
	pending.set_conversation([{"role":"assistant","content":"即将关闭"}],"小鸭")
	pending._scroll_to_latest()
	pending._scroll_to_latest()
	var bound_callbacks := 0
	for connection in process_frame.get_connections():
		if connection.callable.get_object() == pending: bound_callbacks += 1
	check(bound_callbacks == 1,"Repeated refresh queues one lifetime-bound next-frame scroll callback")
	pending.call_deferred("free")
	await process_frame
	await process_frame
	check(not is_instance_valid(pending),"Pending scroll callback permits panel disposal before next frame without runtime errors")
	print("AI CHAT UI: ",failures," failures")
	quit(0 if failures == 0 else 1)
