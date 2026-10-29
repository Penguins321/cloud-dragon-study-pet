extends PanelContainer

const Appearance = preload("res://pet/appearance.gd")
const AppearancePreview = preload("res://ui/appearance_preview.gd")

signal appearance_requested(style: String, color: String)
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
var appearance_preview: SubViewportContainer
var _appearance_title: Label
var _style_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}
var _selected_style := "jade"
var _selected_color := "jade"

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
	_build_appearance_card()
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
	for entry in [["巡游\n弧线行进",&"swim"],["感知\n左右探查",&"look"],["舒展\n展开玉片",&"stretch"],["收息\n安静回落",&"rest"],["共鸣\n起伏应和",&"celebrate"],["引光\n聚光成笺",&"breath"],["行走\n交替踏步",&"walk"],["捧腹大笑\n欢快颤动",&"laugh"],["跳跃\n蓄力腾空",&"jump"],["连跳\n轻盈三连",&"hop"],["回旋\n玉核转动",&"spin"],["摇摆\n左右荡漾",&"sway"],["鞠躬\n轻轻致意",&"bow"],["翻滚\n玉核翻转",&"roll"],["舞蹈\n轻盈起舞",&"dance"]]:
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

func _compact_appearance_button(button: Button) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		style.content_margin_left = 8
		style.content_margin_right = 8
		button.add_theme_stylebox_override(state,style)
