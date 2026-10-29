extends SceneTree

var failures := 0
var events: Array = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func button_named(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text: return child
		var found := button_named(child,text)
		if found != null: return found
	return null

func run() -> void:
	if OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		printerr("UI checks require isolated CLOUD_DRAGON_DATA_DIR")
		quit(1)
		return
	var panel = load("res://ui/plan_panel.gd").new()
	panel.theme = load("res://ui/study_theme.tres")
	root.add_child(panel)
	var model = load("res://study/study_plan.gd").new()
	var titles: Array[String] = ["长任务标题".repeat(30),"第二项"]
	model.replace_content("一个可以完整阅读的近期目标".repeat(12),titles)
	panel.render_plan(model.to_dict())
	for event in ["append_requested","details_requested","undo_requested","focus_requested"]:
		check(panel.has_signal(event),"Plan exposes " + event)
	check(panel.has_method("set_focus_state"),"Plan renders focus snapshot")
	check(panel.has_method("show_notice"),"Plan can display saved/action notices")
	check(panel.body_scroll.follow_focus,"Plan scroll reveals keyboard focus")
	var dismiss_notice := button_named(panel,"×")
	check(dismiss_notice != null,"Plan notice has an explicit dismiss control")
	if dismiss_notice != null:
		panel.layout_changed.connect(func(): events.append("notice-layout"))
		panel.show_notice("欢迎提示保留完整可读内容")
		check(panel._message.visible and panel._message.text == "欢迎提示保留完整可读内容","Notice opens with full readable text")
		dismiss_notice.pressed.emit()
		check(not panel._message.visible,"Dismiss hides notice label")
		check(not panel._message.get_parent().visible,"Dismiss releases entire notice row")
		check(events.back() == "notice-layout","Dismiss requests host layout refresh")
		panel.show_error("保存失败，请重试")
		check(panel._message.visible and panel._message.text == "保存失败，请重试","A later error reopens after notice dismissal")
		check(panel._message.get_theme_color("font_color") == Color("a24c3f"),"Dismissal preserves subsequent error styling")
		dismiss_notice.pressed.emit()
	check(panel.current_label.max_lines_visible == -1,"Long current task remains readable")
	check(panel._goal.max_lines_visible == -1,"Long goal remains readable")
	if panel.has_signal("append_requested"):
		panel.append_requested.connect(func(title): events.append(["append",title]))
		panel._append_input.text = "追加任务"
		button_named(panel,"追加任务").pressed.emit()
		check(events.back() == ["append","追加任务"],"Append emits entered title without changing plan")
		check(panel._list.get_child_count() == 2,"Requests do not mutate task list")
		panel.details_requested.connect(func(goal,title): events.append(["details",goal,title]))
		button_named(panel,"修订当前内容").pressed.emit()
		panel._details_goal.text = "修订目标"
		panel._details_title.text = "修订任务"
		panel._details_dialog.confirmed.emit()
		check(events.back() == ["details","修订目标","修订任务"],"Details confirm emits both values")
		check(not panel._details_dialog.dialog_hide_on_ok,"Details remains open until candidate save succeeds")
		panel._details_title.text = ""
		panel._details_dialog.confirmed.emit()
		panel.show_error("当前任务标题不能为空")
		check(panel._details_dialog.visible and panel._details_goal.text == "修订目标","Rejected details preserve visible draft")
		var details_error = panel.get("_details_error")
		check(details_error is Label and details_error.visible and details_error.text == "当前任务标题不能为空","Details validation error is visible inside dialog")
		panel.render_plan(model.to_dict())
		check(not panel._details_dialog.visible,"Successful render closes saved details dialog")
		panel.set_focus_state({"state":"running","remaining_seconds":1499,"duration_seconds":1500,"task_title":"会话开始时的标题"})
		check(panel.focus_card.clock_label.text == "24:59","Focus formats seconds locally")
		check(panel.focus_card.primary_button.text == "暂停","Running offers pause")
		panel.focus_requested.connect(func(action,minutes): events.append([action,minutes]))
		panel.focus_card.primary_button.pressed.emit()
		check(events.back()[0] == "pause","Focus button routes pause request")
		panel.set_focus_state({"state":"paused","remaining_seconds":61})
		check(panel.focus_card.primary_button.text == "继续","Paused offers resume")
		panel.set_focus_state({"state":"finished","remaining_seconds":0})
		check(panel.focus_card.primary_button.text == "开始专注","Finished can start another session")
		check(panel.focus_card.minutes_input.min_value == 5 and panel.focus_card.minutes_input.max_value == 120 and panel.focus_card.minutes_input.step == 1,"Duration is integer 5..120 minutes")
		check(panel.focus_card.minutes_input.value == 25,"Start defaults to 25 minutes")
		panel.focus_card.primary_button.pressed.emit()
		check(events.back() == ["start",25],"Start emits selected integer duration")
		panel.set_focus_state({"state":"running","remaining_seconds":60})
		panel.focus_card.cancel_button.pressed.emit()
		check(events.back()[0] == "cancel","End emits cancel without mutating tasks")
		panel.set_focus_state({"state":"paused","duration_seconds":300,"remaining_seconds":0.5})
		check(panel.focus_card.clock_label.text == "00:01","Fractional final second rounds up")
		check(panel.focus_card.minutes_input.value == 5,"Restored five-minute session restores its duration")
		panel.set_focus_state({"state":"idle","duration_seconds":300,"remaining_seconds":300})
		panel.focus_card.minutes_input.value = 40
		panel.set_focus_state({"state":"idle","duration_seconds":300,"remaining_seconds":300})
		check(panel.focus_card.minutes_input.value == 40,"Idle refresh keeps user's next duration choice")
		check(panel.focus_card.clock_label.text == "40:00","Idle clock follows user's next duration choice")
	var settings = load("res://ui/settings_panel.tscn").instantiate()
	root.add_child(settings)
	check(settings.theme.resource_path == "res://ui/study_theme.tres","Settings and plan share one jade theme")
	check(settings.theme.get_color("font_focus_color","Button").is_equal_approx(Color("193f2b")),"Focused buttons retain dark jade text contrast")
	check(settings.theme.get_color("font_focus_color","OptionButton").is_equal_approx(Color("193f2b")),"Focused dropdowns retain dark jade text contrast")
	check(settings.theme.has_stylebox("panel","TabContainer") and settings.category_tabs.get_theme_stylebox("panel") is StyleBoxEmpty,"Category panel explicitly removes engine gray background")
	for event in ["companion_mode_requested","reduced_motion_requested","performance_requested","topmost_requested","data_action_requested"]:
		check(settings.has_signal(event),"Settings exposes " + event)
	check(settings.has_method("set_companion_options"),"Settings restores companion choices")
	check(settings.has_method("set_display_scale_selection"),"Scale selection is supplied by centralized preference owner")
	if settings.has_method("set_display_scale_selection"):
		settings.set_display_scale_selection(0.75)
		check(button_named(settings,"75%\n小").button_pressed and not button_named(settings,"100%\n中").button_pressed,"Central scale setter updates selection without reading files")
	if settings.has_method("set_companion_options"):
		settings.set_companion_options("quiet",true,"eco",false)
		check(settings.companion_mode.selected == 1 and settings.reduced_motion.button_pressed,"Quiet and reduced state restored")
		check(settings.performance_mode.selected == 1 and not settings.topmost_button.button_pressed,"Eco and topmost state restored")
		settings.companion_mode_requested.connect(func(mode): events.append(mode))
		settings.companion_mode.item_selected.emit(0)
		check(events.back() == "natural","Mode dropdown emits exact natural enum")
		settings.performance_requested.connect(func(mode): events.append(mode))
		settings.performance_mode.item_selected.emit(1)
		check(events.back() == "eco","Performance dropdown emits exact eco enum")
		settings.reduced_motion_requested.connect(func(value): events.append(value))
		settings.reduced_motion.toggled.emit(false)
		check(events.back() == false,"Reduced motion emits bool")
		settings.topmost_requested.connect(func(value): events.append(value))
		settings.topmost_button.toggled.emit(true)
		check(events.back() == true,"Topmost emits bool")
		check(settings.category_tabs.get_tab_count() == 4,"Four settings categories")
		for index in 4:
			settings.category_tabs.current_tab = index
			check(settings.category_tabs.get_tab_control(index).is_visible_in_tree(),"Category reachable: " + str(index))
			check(settings.category_tabs.get_tab_control(index).follow_focus,"Every settings category reveals keyboard focus")
		settings.data_action_requested.connect(func(action): events.append(action))
		for entry in [["导入计划","import"],["导出模板","template"],["导出备份","backup"],["恢复最近备份","restore"],["恢复导入前计划","restore_import"],["打开数据目录","folder"],["使用帮助","help"]]:
			var button := button_named(settings,entry[0])
			check(button != null,"Data action exists: " + entry[0])
			if button != null:
				button.pressed.emit()
				check(events.back() == entry[1],"Data action emits exact value")
		settings.set_companionship_info(7200,1800,2)
		check("2" in settings.companionship_info.text,"Companionship statistics visible")
		check(settings.preset_buttons.size() == 3,"Three curated appearance presets")
		settings.set_appearance("glass","moon")
		check(settings.preset_buttons[1].button_pressed,"Matching preset clearly selected")
		settings.set_appearance("glass","rose")
		check(not settings.preset_buttons.any(func(button): return button.button_pressed),"Custom appearance clears preset selection")
	var base: int = panel.current_label.get_theme_font_size("font_size")
	var tab_base: int = settings.category_tabs.get_tab_bar().get_theme_font_size("font_size")
	for level in 4:
		panel.set_font_level(level)
		settings.set_font_level(level)
		check(settings.font_buttons[level].button_pressed,"Font selection stays visible")
		if level > 0:
			check(settings.category_tabs.get_tab_bar().get_theme_font_size("font_size") > tab_base,"All four category tab titles share font level")
			check(panel.current_label.get_theme_font_size("font_size") > base,"Current task shares font level")
			check(panel._list.get_child(0).get_theme_font_size("font_size") > 16,"Regenerated rows share font level")
			check(panel._confirm.get_ok_button().get_theme_font_size("font_size") > 16,"Replacement confirmation shares font level")
			if panel.has_signal("append_requested"):
				check(panel.focus_card.primary_button.get_theme_font_size("font_size") > 16,"Focus controls share font level")
				check(panel._details_title.get_theme_font_size("font_size") > 16,"Maintenance dialog shares font level")
	panel.set_font_level(0)
	check(panel.current_label.get_theme_font_size("font_size") == base,"Repeated font changes do not compound")
	var dialog_script = load("res://ui/plan_data_dialog.gd") if ResourceLoader.exists("res://ui/plan_data_dialog.gd") else null
	check(dialog_script != null,"Plan data dialog exists")
	if dialog_script != null:
		var dialogs = dialog_script.new()
		root.add_child(dialogs)
		dialogs.setup(root)
		check(dialogs.file_dialog.use_native_dialog,"File picker requests platform native dialog")
		check(not dialogs.file_dialog.mode_overrides_title,"Native file modes preserve descriptive picker titles")
		dialogs.import_path_selected.connect(func(path): events.append(["import",path]))
		dialogs.export_path_selected.connect(func(path,kind): events.append([kind,path]))
		dialogs.import_confirmed.connect(func(): events.append("confirmed"))
		dialogs._export_kind = "backup"
		dialogs._on_file_selected("isolated.json")
		check(events.back() == ["backup","isolated.json"],"File selection emits path and kind only")
		dialogs.confirm_import("2 项任务，包含学习进度")
		check("2 项任务" in dialogs.summary_label.text and "替换" in dialogs.summary_label.text,"Import previews summary and replacement consequence")
		dialogs.confirmation.confirmed.emit()
		check(events.back() == "confirmed","Import requires confirmation event")
		dialogs.confirmation.hide()
		root.gui_embed_subwindows = true
		root.size = Vector2i(520,440)
		preload("res://ui/font_scale.gd").apply(dialogs.confirmation,3)
		dialogs.confirm_import("近期目标：" + "完整可读的目标内容".repeat(12))
		await process_frame
		await process_frame
		check(dialogs.confirmation.dialog_autowrap,"Import summary enables dialog text wrapping")
		check(dialogs.confirmation.size.x <= root.size.x and dialogs.confirmation.size.y <= root.size.y,"Large-font CJK import confirmation stays within viewport")
		check(dialogs.confirmation.size.y <= mini(400,root.size.y-32),"Import confirmation respects requested 400px height after layout")
		check(dialogs.confirmation.dialog_text.is_empty(),"Internal dialog label cannot impose unbounded summary minimum height")
		check(dialogs.get("summary_scroll") is ScrollContainer,"Import preview can scroll full summary without displacing buttons")
		check("完整可读的目标内容".repeat(12) in dialogs.summary_label.text and "确认后才会写入" in dialogs.summary_label.text,"Scrollable preview preserves the entire import summary")
		check(dialogs.summary_scroll.get_v_scroll_bar().max_value > dialogs.summary_scroll.size.y,"Long CJK summary scrolls at largest font")
		check(Rect2(Vector2.ZERO,Vector2(dialogs.confirmation.size)).encloses(dialogs.confirmation.get_ok_button().get_global_rect()),"Import confirm button stays inside bounded dialog")
		dialogs.free()
	await process_frame
	if panel.has_signal("append_requested"):
		check(panel.body_scroll.get_v_scroll_bar().max_value > panel.body_scroll.size.y,"Long plan body scrolls")
		button_named(panel,"编辑整份清单").grab_focus()
		await process_frame
		await process_frame
		check(panel.body_scroll.scroll_vertical > 0,"Tab focus can reveal a below-fold plan action")
	panel.free()
	settings.free()
	print("V016 UI failures: ",failures)
	quit(0 if failures == 0 else 1)
