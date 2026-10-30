extends PanelContainer

const HEIGHT := 52
var host: Window

static func install(window: Window) -> Control:
	window.borderless = true
	var bar = load("res://ui/window_chrome.gd").new()
	bar.name = "WindowChrome"
	bar.host = window
	if window is AcceptDialog:
		# CanvasLayer keeps the title out of AcceptDialog's automatic body layout.
		var layer := CanvasLayer.new()
		window.add_child(layer)
		layer.add_child(bar)
		var dialog_theme: Theme = window.theme.duplicate() if window.theme != null else preload("res://ui/study_theme.tres").duplicate()
		var panel: StyleBoxFlat = preload("res://ui/study_theme.tres").get_stylebox("panel","PanelContainer").duplicate()
		panel.content_margin_top = HEIGHT+16
		dialog_theme.set_stylebox("panel","AcceptDialog",panel)
		window.theme = dialog_theme
		window.size_changed.connect(func(): bar.size.x = window.size.x)
		bar.size.x = window.size.x
	else:
		window.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	return bar

func _ready() -> void:
	theme = preload("res://ui/study_theme.tres")
	custom_minimum_size.y = HEIGHT
	size.y = HEIGHT
	var paint := StyleBoxFlat.new()
	paint.bg_color = Color("e7eedd")
	paint.border_color = Color("c7d6bd")
	paint.border_width_bottom = 1
	paint.content_margin_left = 14
	paint.content_margin_right = 4
	add_theme_stylebox_override("panel",paint)
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = "◇  " + host.title
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.add_theme_font_size_override("font_size",13)
	label.add_theme_color_override("font_color",Color("284a40"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	if not host is AcceptDialog:
		_button(row,"−","最小化",func(): host.mode = Window.MODE_MINIMIZED)
	_button(row,"×","关闭",_close)
	gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			DisplayServer.window_start_drag(host.get_window_id())
	)

func _button(row: HBoxContainer, caption: String, description: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.tooltip_text = description
	button.accessibility_name = description
	button.custom_minimum_size = Vector2(36,36)
	button.flat = true
	for state in ["normal","hover","pressed","disabled"]:
		var paint := StyleBoxFlat.new()
		paint.bg_color = Color("cedfc5") if state in ["hover","pressed"] else Color(0,0,0,0)
		button.add_theme_stylebox_override(state,paint)
	button.add_theme_font_size_override("font_size",20)
	button.pressed.connect(action)
	row.add_child(button)


func _close() -> void:
	if host is AcceptDialog:
		host.hide()
		host.emit_signal("canceled")
	else:
		host.close_requested.emit()
