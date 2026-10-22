extends PanelContainer

signal display_scale_requested(value: float)
signal dismiss_requested
signal hide_pet_requested
signal quit_requested

func _ready() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	box.add_child(HSeparator.new())
	var startup := CheckButton.new()
	startup.text = "开机自启动（待产品化）"
	startup.disabled = true
	startup.tooltip_text = "此原型不修改系统自启动配置。"
	box.add_child(startup)
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
	for entry in [["小", 0.75], ["中", 1.0], ["大", 1.25]]:
		var button := Button.new()
		button.text = entry[0]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = is_equal_approx(entry[1], selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): display_scale_requested.emit(entry[1]))
		sizes.add_child(button)
	for text in ["分享清单（待产品化）", "备份与恢复（待产品化）"]:
		var button := Button.new()
		button.text = text
		button.disabled = true
		box.add_child(button)
	var note := Label.new()
	note.text = "本地保存，无需账号\n当前为交互原型，角色动作尚未定稿。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	box.add_child(note)
	var footer := HBoxContainer.new()
	box.add_child(footer)
	for entry in [["收起", dismiss_requested], ["隐藏宠物", hide_pet_requested], ["退出", quit_requested]]:
		var button := Button.new()
		button.text = entry[0]
		var event: Signal = entry[1]
		button.pressed.connect(func(): event.emit())
		footer.add_child(button)
