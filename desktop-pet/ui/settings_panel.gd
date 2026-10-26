extends PanelContainer

signal display_scale_requested(value: float)
signal action_preview_requested(action: StringName)
signal dismiss_requested
signal hide_pet_requested
signal quit_requested
signal startup_requested(enabled: bool)

var startup_button: CheckButton
var startup_status: Label

func _ready() -> void:
	var outer := VBoxContainer.new()
	add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	box.add_child(HSeparator.new())
	startup_button = CheckButton.new()
	startup_button.text = "开机自启动"
	startup_button.disabled = true
	startup_button.tooltip_text = "登录 Windows 后自动启动当前程序。"
	startup_button.toggled.connect(func(enabled: bool): startup_requested.emit(enabled))
	box.add_child(startup_button)
	startup_status = Label.new()
	startup_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	startup_status.add_theme_font_size_override("font_size",13)
	box.add_child(startup_status)
	var size_label := Label.new()
	size_label.text = "宠物显示大小"
	box.add_child(size_label)
	var sizes := HBoxContainer.new()
	box.add_child(sizes)
	var group := ButtonGroup.new()
	var saved := ConfigFile.new()
	var data_directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	saved.load("user://preferences.cfg" if data_directory.is_empty() else data_directory.path_join("preferences.cfg"))
	var selected: float = saved.get_value("pet", "scale", 1.0)
	for entry in [["更小", 0.5], ["小", 0.75], ["中", 1.0], ["大", 1.25]]:
		var button := Button.new()
		button.text = entry[0]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = is_equal_approx(entry[1], selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): display_scale_requested.emit(entry[1]))
		sizes.add_child(button)
	var motion_label := Label.new()
	motion_label.text = "动作预览"
	box.add_child(motion_label)
	var motions := HBoxContainer.new()
	box.add_child(motions)
	for entry in [["巡游", &"swim"], ["感知", &"look"], ["舒展", &"stretch"], ["收息", &"rest"], ["共鸣", &"celebrate"], ["引光", &"breath"]]:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_constant_override("outline_size", 0)
		button.pressed.connect(func(): action_preview_requested.emit(entry[1]))
		motions.add_child(button)
	for text in ["分享清单（待产品化）", "备份与恢复（待产品化）"]:
		var button := Button.new()
		button.text = text
		button.disabled = true
		box.add_child(button)
	var note := Label.new()
	note.text = "左键循环动作（含引光查看目标），按住拖动\n右键打开菜单；点击引光雾幕打开学习计划。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	box.add_child(note)
	var footer := HBoxContainer.new()
	outer.add_child(footer)
	for entry in [["收起", dismiss_requested], ["隐藏宠物", hide_pet_requested], ["退出", quit_requested]]:
		var button := Button.new()
		button.text = entry[0]
		var event: Signal = entry[1]
		button.pressed.connect(func(): event.emit())
		footer.add_child(button)

func set_startup_state(supported: bool, enabled: bool, detail: String) -> void:
	startup_button.disabled = not supported
	startup_button.set_pressed_no_signal(enabled)
	startup_status.text = detail if not detail.is_empty() else ("已启用：登录 Windows 后自动启动。" if enabled else "已关闭：登录 Windows 后不自动启动。")
