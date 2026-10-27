extends PanelContainer

signal display_scale_requested(value: float)
signal action_preview_requested(action: StringName)
signal dismiss_requested
signal hide_pet_requested
signal quit_requested
signal startup_requested(enabled: bool)
signal icon_awareness_requested(enabled: bool)

var startup_button: CheckButton
var startup_status: Label
var icon_awareness_button: CheckButton
var icon_awareness_status: Label
var _sections: VBoxContainer

func _ready() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",18)
	add_child(outer)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation",4)
	outer.add_child(header)
	header.add_child(_label("◇  温玉灵核",13,Color("627861")))
	header.add_child(_label("设置",26,Color("284a40")))
	header.add_child(_label("让陪伴，恰到好处。",13,Color("627362")))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_sections = VBoxContainer.new()
	_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sections.add_theme_constant_override("separation",14)
	scroll.add_child(_sections)
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
	var saved := ConfigFile.new()
	var data_directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	saved.load("user://preferences.cfg" if data_directory.is_empty() else data_directory.path_join("preferences.cfg"))
	var selected: float = saved.get_value("pet","scale",1.0)
	for entry in [["50%\n更小",0.5],["75%\n小",0.75],["100%\n中",1.0],["125%\n大",1.25]]:
		var button := Button.new()
		button.text = entry[0]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = is_equal_approx(entry[1],selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",14)
		button.pressed.connect(func(): display_scale_requested.emit(entry[1]))
		sizes.add_child(button)
	var motion := _card()
	motion.add_child(_label("动作预览",16))
	var motions := GridContainer.new()
	motions.columns = 3
	motions.add_theme_constant_override("h_separation",6)
	motions.add_theme_constant_override("v_separation",6)
	motion.add_child(motions)
	for entry in [["巡游\n弧线行进",&"swim"],["感知\n左右探查",&"look"],["舒展\n展开玉片",&"stretch"],["收息\n安静回落",&"rest"],["共鸣\n起伏应和",&"celebrate"],["引光\n聚光成笺",&"breath"],["行走\n交替踏步",&"walk"],["捧腹大笑\n欢快颤动",&"laugh"],["跳跃\n蓄力腾空",&"jump"],["连跳\n轻盈三连",&"hop"],["回旋\n玉核转动",&"spin"],["摇摆\n左右荡漾",&"sway"]]:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",13)
		button.pressed.connect(func(): action_preview_requested.emit(entry[1]))
		motions.add_child(button)
	var note := _label("轻点切换动作，按住拖动；点光笺查看计划。",12,Color("627362"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sections.add_child(note)
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
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

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
	startup_status.text = detail if not detail.is_empty() else ("已开启，登录 Windows 后自动陪伴你。" if enabled else "已关闭，需要时手动启动。")

func set_icon_awareness_state(value: bool, detail: String) -> void:
	icon_awareness_button.set_pressed_no_signal(value)
	icon_awareness_status.text = detail
