extends PanelContainer

const Appearance = preload("res://pet/appearance.gd")
const AppearancePreview = preload("res://ui/appearance_preview.gd")
const FONT_SETTINGS_REVISION := "0.14.2-font-sync"

signal appearance_requested(style: String, color: String)
signal display_scale_requested(value: float)
signal action_preview_requested(action: StringName)
signal dismiss_requested
signal hide_pet_requested
signal quit_requested
signal startup_requested(enabled: bool)
signal icon_awareness_requested(enabled: bool)
signal font_level_requested(level: int)
signal renderer_mode_requested(mode: String)
signal companion_mode_requested(mode: String)
signal reduced_motion_requested(value: bool)
signal performance_requested(mode: String)
signal topmost_requested(value: bool)
signal data_action_requested(action: String)
var category_tabs := TabContainer.new()
var companion_mode := OptionButton.new()
var reduced_motion := CheckButton.new()
var performance_mode := OptionButton.new()
var topmost_button := CheckButton.new()
var companionship_info := Label.new()
var preset_buttons: Array[Button] = []
var _category_sections: Dictionary = {}
var renderer_button: CheckButton
var renderer_status: Label

var font_buttons: Array[Button] = []

var startup_button: CheckButton
var startup_status: Label
var icon_awareness_button: CheckButton
var icon_awareness_status: Label
var _sections: VBoxContainer
var appearance_preview: SubViewportContainer
var _appearance_title: Label
var _style_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}
var _scale_buttons: Dictionary = {}
var _selected_style := "jade"
var _selected_color := "jade"

func _ready() -> void:
	theme = preload("res://ui/study_theme.tres")
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",18)
	add_child(outer)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation",4)
	outer.add_child(header)
	header.add_child(_label("◇  温玉灵核",13,Color("627861")))
	header.add_child(_label("设置",26,Color("284a40")))
	header.add_child(_label("让陪伴，恰到好处。",13,Color("627362")))
	header.add_child(_label("版本 0.16 · 按自己的节奏，相伴学习",11,Color("627362")))
	category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_tabs.custom_minimum_size.y = 180
	outer.add_child(category_tabs)
	for category in ["外观","陪伴","桌面","数据与帮助"]: _add_category(category)
	_sections = _category_sections["外观"]
	var font_card := _card()
	font_card.add_child(_label("全局界面字号",16))
	var font_choices := GridContainer.new()
	font_choices.columns = 2
	font_choices.add_theme_constant_override("h_separation",6)
	font_choices.add_theme_constant_override("v_separation",6)
	font_card.add_child(font_choices)
	var font_group := ButtonGroup.new()
	for level in range(4):
		var button := Button.new()
		button.text = preload("res://ui/font_scale.gd").NAMES[level]
		button.toggle_mode = true
		button.button_group = font_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): font_level_requested.emit(level))
		font_choices.add_child(button)
		font_buttons.append(button)
	font_buttons[0].set_pressed_no_signal(true)
	var renderer_card := _card()
	renderer_card.add_child(_label("晶体渲染",16))
	renderer_button = CheckButton.new()
	renderer_button.text = "使用立体 3D 晶体"
	renderer_button.toggled.connect(func(enabled: bool): renderer_mode_requested.emit("3d" if enabled else "2d"))
	renderer_card.add_child(renderer_button)
	renderer_status = _label("玉晶、水晶、欧泊支持 3D；关闭恢复原版 2D。",12,Color("627362"))
	renderer_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	renderer_card.add_child(renderer_status)
	_build_appearance_card()
	_sections = _category_sections["桌面"]
	_build_desktop_options()
	var startup_card := _card()
	var startup_row := HBoxContainer.new()
	startup_card.add_child(startup_row)
	var startup_title := _label("开机自启动",16)
	startup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	startup_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	startup_row.add_child(startup_title)
	startup_button = CheckButton.new()
	startup_button.disabled = true
	startup_button.tooltip_text = "登录 Windows 后自动启动当前程序"
	startup_button.accessibility_name = "开机自启动"
	startup_button.toggled.connect(func(enabled: bool): startup_requested.emit(enabled))
	startup_row.add_child(startup_button)
	startup_status = _label("",12,Color("627362"))
	startup_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	startup_card.add_child(startup_status)
	var awareness_card := _card()
	var awareness_row := HBoxContainer.new()
	awareness_card.add_child(awareness_row)
	var awareness_title := _label("桌面图标感知",16)
	awareness_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	awareness_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	awareness_row.add_child(awareness_title)
	icon_awareness_button = CheckButton.new()
	icon_awareness_button.accessibility_name = "桌面图标感知"
	icon_awareness_button.toggled.connect(func(value: bool): icon_awareness_requested.emit(value))
	awareness_row.add_child(icon_awareness_button)
	icon_awareness_status = _label("靠近图标时轻轻转向，遮挡时自动让开。",12,Color("627362"))
	icon_awareness_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	awareness_card.add_child(icon_awareness_status)
	var display := _card()
	display.add_child(_label("显示大小",16))
	var sizes := HBoxContainer.new()
	sizes.add_theme_constant_override("separation",6)
	display.add_child(sizes)
	var group := ButtonGroup.new()
	var selected := 1.0
	for entry in [["50%\n更小",0.5],["75%\n小",0.75],["100%\n中",1.0],["125%\n大",1.25]]:
		var button := Button.new()
		button.text = entry[0]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = is_equal_approx(entry[1],selected)
		_scale_buttons[entry[1]] = button
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",14)
		button.pressed.connect(func(): display_scale_requested.emit(entry[1]))
		sizes.add_child(button)
	_sections = _category_sections["陪伴"]
	_build_companion_options()
	var motion := _card()
	motion.add_child(_label("动作预览",16))
	var motions := GridContainer.new()
	motions.columns = 2
	motions.add_theme_constant_override("h_separation",6)
	motions.add_theme_constant_override("v_separation",6)
	motion.add_child(motions)
	for entry in [["巡游\n弧线行进",&"swim"],["感知\n左右探查",&"look"],["舒展\n展开玉片",&"stretch"],["收息\n安静回落",&"rest"],["共鸣\n起伏应和",&"celebrate"],["引光\n聚光成笺",&"breath"],["行走\n交替踏步",&"walk"],["捧腹大笑\n欢快颤动",&"laugh"],["跳跃\n蓄力腾空",&"jump"],["连跳\n轻盈三连",&"hop"],["回旋\n玉核转动",&"spin"],["摇摆\n左右荡漾",&"sway"],["鞠躬\n轻轻致意",&"bow"],["翻滚\n玉核翻转",&"roll"],["舞蹈\n轻盈起舞",&"dance"],["环绕\n玉片绕行",&"orbit"],["螺旋\n盘旋升降",&"helix"],["交错环绕\n前后交汇",&"cross_orbit"],["巡光\n立体转身",&"refract_turn"]]:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",13)
		button.pressed.connect(func(): action_preview_requested.emit(entry[1]))
		motions.add_child(button)
	var note := _label("轻点切换动作，按住拖动；点光笺查看计划。",12,Color("627362"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sections.add_child(note)
	_sections = _category_sections["数据与帮助"]
	_build_data_help()
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	outer.add_child(footer)
	for entry in [["收起",dismiss_requested],["隐藏宠物",hide_pet_requested],["退出",quit_requested]]:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if entry[0] == "退出": button.add_theme_color_override("font_color",Color("98746a"))
		var event: Signal = entry[1]
		button.pressed.connect(func(): event.emit())
		footer.add_child(button)

func _label(text: String, size: int, color := Color("35564a")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func set_font_level(level: int) -> void:
	var selected := preload("res://ui/font_scale.gd").valid_level(level)
	for i in font_buttons.size(): font_buttons[i].set_pressed_no_signal(i == selected)
	preload("res://ui/font_scale.gd").apply(self,selected)
	category_tabs.add_theme_font_size_override("font_size",roundi(14*preload("res://ui/font_scale.gd").FACTORS[selected]))
	var tab_bar := category_tabs.get_tab_bar()
	if not tab_bar.has_meta("normal_font_size"):
		tab_bar.set_meta("normal_font_size",tab_bar.get_theme_font_size("font_size"))
	tab_bar.add_theme_font_size_override("font_size",roundi(int(tab_bar.get_meta("normal_font_size"))*preload("res://ui/font_scale.gd").FACTORS[selected]))

func set_renderer_mode(mode: String, message := "") -> void:
	renderer_button.set_pressed_no_signal(mode == "3d")
	renderer_status.text = message if not message.is_empty() else ("晶体使用立体 3D，保留原有动作。" if mode == "3d" else "使用原版 2D 晶体。")

func set_display_scale_selection(scale: float) -> void:
	for value in _scale_buttons:
		_scale_buttons[value].set_pressed_no_signal(is_equal_approx(float(value),scale))

func _card() -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffef8")
	style.border_color = Color("dfe7db")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel",style)
	_sections.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	return box

func set_startup_state(supported: bool, enabled: bool, detail: String) -> void:
	startup_button.disabled = not supported
	startup_button.set_pressed_no_signal(enabled)
	startup_status.text = detail if not detail.is_empty() else ("已开启，登录后自动陪伴你。" if enabled else "已关闭，需要时手动启动。")

func set_icon_awareness_state(value: bool, detail: String) -> void:
	icon_awareness_button.disabled = OS.get_name() != "Windows"
	icon_awareness_button.set_pressed_no_signal(value)
	icon_awareness_status.text = detail if OS.get_name() == "Windows" else "当前平台暂不支持桌面图标感知，其他陪伴功能正常可用。"

func _build_appearance_card() -> void:
	var card := _card()
	card.add_theme_constant_override("separation",7)
	var heading := HBoxContainer.new()
	card.add_child(heading)
	var title := _label("琢玉换彩",18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_label("实时预览",11,Color("7b8e7b")))
	var stage := PanelContainer.new()
	var background := StyleBoxFlat.new()
	background.bg_color = Color("f1f5eb")
	background.set_corner_radius_all(12)
	stage.add_theme_stylebox_override("panel",background)
	card.add_child(stage)
	appearance_preview = AppearancePreview.new()
	stage.add_child(appearance_preview)
	_appearance_title = _label("",14)
	card.add_child(_appearance_title)
	var presets := VBoxContainer.new()
	card.add_child(presets)
	for entry in [["青玉 · 温润日常","jade","jade"],["月白 · 澄澈静心","glass","moon"],["紫晶 · 幻彩灵感","opal","violet"]]:
		var button := Button.new()
		button.text = entry[0]
		button.toggle_mode = true
		button.set_meta("preset_style",entry[1])
		button.set_meta("preset_color",entry[2])
		button.pressed.connect(func(): _choose_appearance(entry[1],entry[2]))
		preset_buttons.append(button)
		presets.add_child(button)
	var styles := GridContainer.new()
	styles.columns = 2
	styles.add_theme_constant_override("h_separation",5)
	styles.add_theme_constant_override("v_separation",5)
	card.add_child(styles)
	for entry: Dictionary in Appearance.STYLES:
		var button := Button.new()
		button.text = entry.name
		button.tooltip_text = entry.detail
		button.accessibility_name = "材质：" + entry.name
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",12)
		_style_buttons[entry.id] = button
		button.pressed.connect(func(): _choose_appearance(entry.id,_selected_color))
		styles.add_child(button)
		_compact_appearance_button(button)
	var colors := GridContainer.new()
	colors.columns = 3
	colors.add_theme_constant_override("h_separation",6)
	colors.add_theme_constant_override("v_separation",6)
	card.add_child(colors)
	for entry: Dictionary in Appearance.COLORS:
		var button := Button.new()
		button.text = "● " + entry.name
		button.accessibility_name = "颜色：" + entry.name
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",13)
		var swatch: Color = entry.color
		var normal := StyleBoxFlat.new()
		normal.bg_color = swatch.lightened(0.72)
		normal.border_color = swatch.darkened(0.14)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(7)
		normal.set_content_margin_all(7)
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_color_override("font_color",Color("35564a"))
		_color_buttons[entry.id] = button
		button.pressed.connect(func(): _choose_appearance(_selected_style,entry.id))
		colors.add_child(button)
		_compact_appearance_button(button)
	var hint := _label("轻点即换装，陪伴也有新色彩。",11,Color("71816d"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(hint)
	set_appearance(_selected_style,_selected_color)

func _choose_appearance(style: String, color: String) -> void:
	set_appearance(style,color)
	appearance_requested.emit(_selected_style,_selected_color)

func set_appearance(style: String, color: String) -> void:
	var appearance_pair := Appearance.selection(style,color)
	_selected_style = appearance_pair[0]
	_selected_color = appearance_pair[1]
	if not is_instance_valid(appearance_preview): return
	appearance_preview.set_appearance(_selected_style,_selected_color)
	var style_name := ""
	var color_name := ""
	for entry: Dictionary in Appearance.STYLES:
		var selected: bool = entry.id == _selected_style
		_style_buttons[entry.id].set_pressed_no_signal(selected)
		_style_buttons[entry.id].text = ("✓ " if selected else "") + entry.name
		if selected: style_name = entry.name
	for entry: Dictionary in Appearance.COLORS:
		var selected: bool = entry.id == _selected_color
		_color_buttons[entry.id].set_pressed_no_signal(selected)
		_color_buttons[entry.id].text = ("✓ " if selected else "● ") + entry.name
		if selected: color_name = entry.name
	_appearance_title.text = style_name + " · " + color_name
	for button in preset_buttons:
		button.set_pressed_no_signal(button.get_meta("preset_style") == _selected_style and button.get_meta("preset_color") == _selected_color)

func _compact_appearance_button(button: Button) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		style.content_margin_left = 8
		style.content_margin_right = 8
		button.add_theme_stylebox_override(state,style)


func _add_category(title: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	category_tabs.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_top",12)
	scroll.add_child(margin)
	var sections := VBoxContainer.new()
	sections.add_theme_constant_override("separation",12)
	margin.add_child(sections)
	_category_sections[title] = sections

func _build_desktop_options() -> void:
	var card := _card()
	card.add_child(_label("窗口与性能",16))
	topmost_button.text = "保持宠物在最前"
	topmost_button.accessibility_name = "保持宠物在最前"
	topmost_button.toggled.connect(func(value): topmost_requested.emit(value))
	card.add_child(topmost_button)
	performance_mode.add_item("流畅 · 60 FPS")
	performance_mode.add_item("节能 · 30 FPS")
	performance_mode.accessibility_name = "性能档位"
	performance_mode.item_selected.connect(func(index): performance_requested.emit("smooth" if index == 0 else "eco"))
	card.add_child(performance_mode)
	card.add_child(_label("隐藏时自动降低处理；再次显示沿用所选档位。",12,Color("627362")))

func _build_companion_options() -> void:
	var card := _card()
	card.add_child(_label("陪伴的分寸",16))
	companion_mode.add_item("自然陪伴 · 偶尔轻轻活动")
	companion_mode.add_item("安静陪伴 · 不主动表演")
	companion_mode.accessibility_name = "陪伴模式"
	companion_mode.item_selected.connect(func(index): companion_mode_requested.emit("natural" if index == 0 else "quiet"))
	card.add_child(companion_mode)
	reduced_motion.text = "减少动态"
	reduced_motion.accessibility_name = "减少动态"
	reduced_motion.toggled.connect(func(value): reduced_motion_requested.emit(value))
	card.add_child(reduced_motion)
	var note := _label("专注时玉核会安静下来；你仍可主动预览动作。",12,Color("627362"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(note)
	companionship_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(companionship_info)
	set_companionship_info(0,0,0)

func set_companion_options(mode: String, reduced: bool, performance: String, topmost: bool) -> void:
	companion_mode.select(1 if mode == "quiet" else 0)
	reduced_motion.set_pressed_no_signal(reduced)
	performance_mode.select(1 if performance == "eco" else 0)
	topmost_button.set_pressed_no_signal(topmost)

func set_companionship_info(active_seconds: float, focus_seconds: float, completed_sessions: int) -> void:
	companionship_info.text = "相伴 %.1f 小时 · 累计专注 %d 分钟\n完整专注 %d 次 · 成长与专注分别记录" % [maxf(active_seconds,0)/3600.0,int(maxf(focus_seconds,0)/60.0),maxi(completed_sessions,0)]

func _build_data_help() -> void:
	var card := _card()
	card.add_child(_label("把计划妥善收好",16))
	for entry in [["导入计划","import"],["导出模板","template"],["导出备份","backup"],["恢复最近备份","restore"],["恢复导入前计划","restore_import"],["打开数据目录","folder"],["使用帮助","help"]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(func(): data_action_requested.emit(entry[1]))
		card.add_child(button)
	var scopes := _label("模板只含目标与任务，不含完成状态；备份保留计划进度。两者都不包含外观、陪伴设置或专注统计。导入先预览，确认后才替换当前计划。",12,Color("627362"))
	scopes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(scopes)
	var help := _card()
	help.add_child(_label("从这里开始",16))
	var instructions := _label("点玉核切换动作，按住拖动。点光笺查看近期目标与学习计划。\n\n任务由你手动标记完成，再手动开始下一项；专注计时不会改变清单进度。追加任务或修订当前内容可保留进度。\n\n专注支持暂停、继续和结束本次；系统休眠后恢复为暂停。\n\n收起或按 Escape 关闭面板。隐藏宠物后，可从托盘菜单再次显示；退出会结束程序。",13)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_child(instructions)
