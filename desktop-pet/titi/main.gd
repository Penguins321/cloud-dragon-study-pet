extends Node2D

const Store = preload("res://titi/store.gd")
const INK := Color("252526")
const MUTED := Color("686870")
const BLUE := Color("007aff")
const BODY_SIZE := 20
const CAPTION_SIZE := 18
const TITLE_SIZE := 36
const PET_CENTER_X := 200.0
var store = Store.new()
var guard = preload("res://desktop/single_instance.gd").new()
var startup = preload("res://desktop/startup_macos.gd").new("", "", "org.warmjade.titi")
var textures: Array[ImageTexture] = []
var polygons: Array[PackedVector2Array] = []
var animation = preload("res://titi/animation.gd").new()
var animation_time := 0.0
# Torso anchors, excluding extended tails. Keep the body above the menu.
const BODY_ANCHORS := [0.47, 0.40, 0.50, 0.50, 0.50, 0.50]
var pet_rect := Rect2()
var action := 1
var action_time := 0.0
var idle_time := 0.0
var inactivity := 0.0
var clock := 0.0
var hover_time := 0.0
var away_time := 0.0
var click_time := 0.0
var pressed := false
var dragging := false
var mouse_start := Vector2i.ZERO
var window_start := Vector2i.ZERO
var toolbar: PanelContainer
var toolbar_tween: Tween
var toolbar_hiding := false
var panel: Window
var celebration: Control
var content: VBoxContainer
var tasks_box: VBoxContainer
var done_box: VBoxContainer
var count_label: Label
var notice: Label
var input: LineEdit
var done_expanded := false
var page := "todo"
var tray: StatusIndicator
var menu: PopupMenu
var hidden_pet := false
var last_day := ""

func _ready() -> void:
	store.load_data()
	if not guard.acquire(store.path):
		get_tree().quit()
		return
	_load_art()
	var window := get_window()
	window.title = "提提"
	window.size = Vector2i(400, 430)
	window.transparent = true
	window.transparent_bg = true
	window.borderless = true
	window.unresizable = true
	window.unfocusable = true
	window.always_on_top = store.data.topmost
	window.gui_embed_subwindows = false
	get_tree().auto_accept_quit = false
	window.close_requested.connect(_quit)
	Engine.max_fps = 30
	_build_toolbar()
	_build_panel()
	_build_tray()
	var position_data: Array = store.data.position
	window.position = Vector2i(int(position_data[0]), int(position_data[1]))
	if window.position == Vector2i(-1, -1):
		var area := DisplayServer.screen_get_usable_rect()
		window.position = area.end - window.size - Vector2i(28, 28)
	_clamp_position()
	_set_action(4 if store.data.quiet else 1)
	if not store.message.is_empty(): _show_panel("todo")
	if OS.get_cmdline_user_args().has("--preview-plan"): _show_panel("todo")
	if OS.get_cmdline_user_args().has("--preview-settings"): _show_panel("settings")

func _load_art() -> void:
	animation.load_sheet()
	for pose in 6:
		textures.append(animation.clips[pose][0])
		polygons.append(animation.hulls[pose])

func _style(color: Color, radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	var symbols := {"设置": "⚙", "返回": "←", "添加": "＋", "隐藏提提": "◉", "×": "×"}
	if symbols.has(text):
		button.text = symbols[text]
		button.tooltip_text = "删除事项" if text == "×" else text
		button.add_theme_font_size_override("font_size", 26)
	button.custom_minimum_size = Vector2(44, 44)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _style(Color("ffffff"), 8))
	button.add_theme_stylebox_override("hover", _style(Color("f1f1f3"), 8))
	button.add_theme_stylebox_override("pressed", _style(Color("e8e8ec"), 8))
	button.pressed.connect(callback)
	return button

func _build_toolbar() -> void:
	toolbar = PanelContainer.new()
	toolbar.position = Vector2(66, 324)
	toolbar.size = Vector2(168, 68)
	toolbar.pivot_offset = toolbar.size / 2.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var todo := preload("res://titi/menu_button.gd").new()
	todo.symbol = "todo"
	todo.tooltip_text = "今日待办"
	todo.pressed.connect(func(): _show_panel("todo"))
	row.add_child(todo)
	var separator := VSeparator.new()
	separator.custom_minimum_size = Vector2(1, 32)
	separator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var line := StyleBoxLine.new()
	line.color = Color(0.15, 0.15, 0.18, 0.10)
	line.vertical = true
	separator.add_theme_stylebox_override("separator", line)
	row.add_child(separator)
	var settings := preload("res://titi/menu_button.gd").new()
	settings.symbol = "settings"
	settings.tooltip_text = "设置"
	settings.pressed.connect(func(): _show_panel("settings"))
	row.add_child(settings)
	toolbar.add_child(row)
	add_child(toolbar)
	toolbar.resized.connect(_center_toolbar)
	_center_toolbar()
	_style_toolbar()
	toolbar.hide()

func _center_toolbar() -> void:
	toolbar.position.x = PET_CENTER_X - toolbar.size.x / 2.0
	toolbar.pivot_offset = toolbar.size / 2.0
	if not textures.is_empty(): _geometry()

func _style_toolbar() -> void:
	var translucent: bool = store.data.get("menu_style", "shadow") == "translucent"
	var style := _style(Color(1,1,1,0.72 if translucent else 0.97), 34)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.set_border_width_all(1)
	style.border_color = Color(1,1,1,0.9)
	style.shadow_color = Color(0.08,0.08,0.12,0.05 if translucent else 0.07)
	style.shadow_size = 12 if translucent else 14
	style.shadow_offset = Vector2(0,4)
	toolbar.add_theme_stylebox_override("panel", style)

func _show_toolbar() -> void:
	if toolbar.visible and not toolbar_hiding: return
	if toolbar_tween: toolbar_tween.kill()
	toolbar_hiding = false
	toolbar.show()
	toolbar.modulate.a = 0.0
	toolbar.scale = Vector2(0.96, 0.96)
	toolbar_tween = create_tween().set_parallel(true)
	toolbar_tween.tween_property(toolbar, "modulate:a", 1.0, 0.16)
	toolbar_tween.tween_property(toolbar, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_geometry()

func _hide_toolbar(immediate := false) -> void:
	if immediate:
		if toolbar_tween: toolbar_tween.kill()
		toolbar.hide()
		toolbar_hiding = false
		_geometry()
		return
	if not toolbar.visible or toolbar_hiding: return
	toolbar_hiding = true
	if toolbar_tween: toolbar_tween.kill()
	toolbar_tween = create_tween()
	toolbar_tween.tween_property(toolbar, "modulate:a", 0.0, 0.12)
	toolbar_tween.tween_callback(func():
		toolbar.hide()
		toolbar_hiding = false
		_geometry()
	)

func _build_panel() -> void:
	panel = Window.new()
	panel.title = "提提 · 今日待办"
	panel.size = Vector2i(780, 800)
	panel.min_size = Vector2i(600, 560)
	panel.visible = false
	panel.transient = false
	var theme := Theme.new()
	theme.default_font_size = BODY_SIZE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC", "Helvetica Neue", "Arial"])
	theme.default_font = font
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "CheckButton", INK)
	theme.set_color("font_color", "OptionButton", INK)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_stylebox("normal", "LineEdit", _style(Color("f5f5f7"), 8))
	var focus_style := _style(Color.TRANSPARENT, 8)
	focus_style.set_border_width_all(2)
	focus_style.border_color = Color("a8ccf7")
	theme.set_stylebox("focus", "LineEdit", focus_style)
	theme.set_stylebox("normal", "OptionButton", _style(Color("f5f5f7"), 8))
	panel.theme = theme
	add_child(panel)
	var surface := PanelContainer.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := _style(Color.WHITE, 0)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 30
	style.content_margin_bottom = 24
	surface.add_theme_stylebox_override("panel", style)
	panel.add_child(surface)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	surface.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)
	panel.close_requested.connect(panel.hide)
	panel.window_input.connect(func(event: InputEvent):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: panel.hide()
	)
	celebration = preload("res://titi/celebration.gd").new()
	panel.add_child(celebration)

func _label(text: String, size := BODY_SIZE, color := INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(size * (1.2 if store.data.large_font else 1.0)))
	label.add_theme_color_override("font_color", color)
	return label

func _show_panel(next: String) -> void:
	page = next
	_show_pet()
	_render_panel()
	var area := DisplayServer.screen_get_usable_rect()
	panel.size = Vector2i(mini(panel.size.x, area.size.x - 32), mini(panel.size.y, area.size.y - 64))
	panel.position = get_window().position + Vector2i(-panel.size.x - 12, 0)
	panel.position.x = clampi(panel.position.x, area.position.x, maxi(area.position.x, area.end.x - panel.size.x))
	panel.position.y = clampi(panel.position.y, area.position.y, maxi(area.position.y, area.end.y - panel.size.y))
	panel.show()
	panel.grab_focus()

func _render_panel() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	panel.theme.default_font_size = 24 if store.data.large_font else BODY_SIZE
	var heading := HBoxContainer.new()
	var title := _label("今日待办" if page == "todo" else "设置", TITLE_SIZE)
	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(["PingFang SC", "Helvetica Neue", "Arial"])
	title_font.font_weight = 600
	title.add_theme_font_override("font", title_font)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_button("设置" if page == "todo" else "返回", func():
		page = "settings" if page == "todo" else "todo"
		_render_panel()
	))
	content.add_child(heading)
	if page == "todo": _render_todo()
	else: _render_settings()
	notice = _label(store.message, CAPTION_SIZE, MUTED)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(notice)

func _render_todo() -> void:
	var date := Time.get_date_dict_from_system()
	last_day = Time.get_date_string_from_system()
	var done := 0
	for task in store.data.tasks:
		if task.done: done += 1
	count_label = _label("%d 月 %d 日 · 已完成 %d / %d" % [date.month, date.day, done, store.data.tasks.size()], CAPTION_SIZE, MUTED)
	content.add_child(count_label)
	var progress_card := PanelContainer.new()
	progress_card.add_theme_stylebox_override("panel", _style(Color("f5f6f8"), 16))
	var progress_content := VBoxContainer.new()
	progress_content.add_theme_constant_override("separation", 12)
	progress_card.add_child(progress_content)
	progress_content.add_child(_label("留一点专注，给今天。" if done == 0 else "每完成一件，都在向前。", 22))
	progress_content.add_child(_label("全部完成，可以休息一下了" if done > 0 and done == store.data.tasks.size() else "还有 %d 件待办" % (store.data.tasks.size() - done), CAPTION_SIZE, MUTED))
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 5
	progress.max_value = maxi(1, store.data.tasks.size())
	progress.value = done
	for entry in [["background", Color("e5e8ed")], ["fill", Color("89b7ab")]]:
		var track := StyleBoxFlat.new()
		track.bg_color = entry[1]
		track.set_corner_radius_all(3)
		progress.add_theme_stylebox_override(entry[0], track)
	progress_content.add_child(progress)
	content.add_child(progress_card)
	content.add_child(_label("待完成", CAPTION_SIZE, MUTED))
	tasks_box = VBoxContainer.new()
	tasks_box.add_theme_constant_override("separation", 8)
	content.add_child(tasks_box)
	for task in store.data.tasks:
		if not task.done: _task_row(task, tasks_box)
	if store.data.tasks.size() == done:
		var empty := _label("今天的事情都完成了。" if done > 0 else "今天，想做点什么？", BODY_SIZE, MUTED)
		empty.custom_minimum_size.y = 76
		tasks_box.add_child(empty)
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 10)
	add_row.custom_minimum_size.y = 80
	input = LineEdit.new()
	input.placeholder_text = "添加一件想做的事"
	input.max_length = 200
	input.custom_minimum_size.y = 80
	input.add_theme_font_size_override("font_size", 26 if store.data.large_font else 24)
	input.tooltip_text = "输入事项后按回车添加"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_submitted.connect(_add_task)
	add_row.add_child(input)
	var add_button := _button("添加", func(): _add_task(input.text))
	add_button.add_theme_stylebox_override("normal", _style(Color("edf3fc"), 9))
	add_button.add_theme_color_override("font_color", BLUE)
	add_button.custom_minimum_size = Vector2(64, 80)
	add_row.add_child(add_button)
	content.add_child(add_row)
	if done > 0:
		var completed_header := HBoxContainer.new()
		var completed_toggle := _button("▾" if done_expanded else "▸", func():
			done_expanded = not done_expanded
			_render_panel()
		)
		completed_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		completed_toggle.tooltip_text = "收起已完成" if done_expanded else "展开已完成"
		completed_header.add_child(completed_toggle)
		completed_header.add_child(_label("已完成 %d" % done, CAPTION_SIZE, MUTED))
		content.add_child(completed_header)
		done_box = VBoxContainer.new()
		done_box.add_theme_constant_override("separation", 8)
		content.add_child(done_box)
		if done_expanded:
			for task in store.data.tasks:
				if task.done: _task_row(task, done_box)
	content.add_child(_label("未完成的事，明天也还在。", CAPTION_SIZE, MUTED))

func _task_row(task: Dictionary, parent: VBoxContainer) -> void:
	var row := preload("res://titi/task_card.gd").new()
	row.completed = task.done
	row.custom_minimum_size.y = 76
	row.add_theme_constant_override("separation", 8)
	var check := _button("✓" if task.done else "○", func():
		var completing: bool = not task.done
		var origin := row.get_global_rect().position + Vector2(24, 26)
		var candidate: Dictionary = store.data.duplicate(true)
		for item in candidate.tasks:
			if item.id == task.id: item.done = not item.done
		if _commit(candidate):
			if not task.done and not store.data.quiet: _set_action(5, 3.2)
			_render_panel()
			if completing and not store.data.quiet:
				var all_done := true
				for item in store.data.tasks:
					if not item.done: all_done = false
				celebration.burst(origin, all_done)
	)
	check.tooltip_text = "撤销完成" if task.done else "完成"
	check.add_theme_color_override("font_color", BLUE if task.done else MUTED)
	check.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, 12))
	row.add_child(check)
	var edit := LineEdit.new()
	edit.text = task.text
	edit.max_length = 200
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, 12))
	if task.done: edit.add_theme_color_override("font_color", MUTED)
	var save_edit := func():
		var value := edit.text.strip_edges()
		if value.is_empty():
			edit.text = task.text
			return
		if value == task.text: return
		var candidate: Dictionary = store.data.duplicate(true)
		for item in candidate.tasks:
			if item.id == task.id: item.text = value
		if _commit(candidate): task.text = value
	edit.text_submitted.connect(func(_text: String): save_edit.call())
	edit.focus_exited.connect(save_edit)
	row.add_child(edit)
	var delete_button := _button("×", func():
		var candidate: Dictionary = store.data.duplicate(true)
		candidate.tasks = candidate.tasks.filter(func(item: Dictionary): return item.id != task.id)
		if _commit(candidate): _render_panel()
	)
	delete_button.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, 12))
	row.add_child(delete_button)
	parent.add_child(row)

func _add_task(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty(): return
	if store.data.tasks.size() >= 500:
		notice.text = "清单最多保存 500 项。"
		return
	var candidate: Dictionary = store.data.duplicate(true)
	candidate.tasks.append({"id": str(Time.get_unix_time_from_system()) + "-" + str(randi()), "text": text, "done": false})
	if _commit(candidate):
		_render_panel()
		input.grab_focus()

func _render_settings() -> void:
	content.add_child(_label("按你的习惯，陪在身边。", CAPTION_SIZE, MUTED))
	var size_picker := OptionButton.new()
	for text in ["小", "中", "大"]: size_picker.add_item(text)
	size_picker.select([170, 210, 250].find(int(store.data.size)))
	size_picker.item_selected.connect(func(index: int): _preference("size", [170, 210, 250][index]))
	_setting_row("提提大小", size_picker)
	for entry in [["安静陪伴", "quiet"], ["始终置顶", "topmost"]]:
		var toggle := preload("res://titi/toggle.gd").new()
		toggle.button_pressed = store.data[entry[1]]
		toggle.toggled.connect(func(value: bool): _preference(entry[1], value))
		_setting_row(entry[0], toggle)
	var login := preload("res://titi/toggle.gd").new()
	login.button_pressed = startup.is_enabled()
	login.disabled = not startup.available
	login.tooltip_text = startup.message
	login.toggled.connect(func(value: bool):
		var error: Error = startup.set_enabled(value)
		login.set_pressed_no_signal(startup.is_enabled())
		notice.text = startup.message if not startup.message.is_empty() else ("已保存" if error == OK else "设置失败")
	)
	_setting_row("开机启动", login)
	var font := OptionButton.new()
	font.add_item("标准 · 20")
	font.add_item("大号 · 24")
	font.select(1 if store.data.large_font else 0)
	font.item_selected.connect(func(index: int):
		_preference("large_font", index == 1)
		_render_panel()
	)
	_setting_row("界面字号", font)
	var menu_style := OptionButton.new()
	menu_style.add_item("柔影")
	menu_style.add_item("轻透")
	menu_style.select(1 if store.data.get("menu_style", "shadow") == "translucent" else 0)
	menu_style.item_selected.connect(func(index: int):
		_preference("menu_style", "shadow" if index == 0 else "translucent")
		_style_toolbar()
	)
	_setting_row("悬浮菜单", menu_style)
	content.add_child(_button("隐藏提提", _hide_pet))
	content.add_child(_label("提提 0.24.1 · 试用版", CAPTION_SIZE, MUTED))

func _setting_row(text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48
	var label := _label(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(control)
	content.add_child(row)

func _commit(candidate: Dictionary) -> bool:
	var error: Error = store.commit(candidate)
	if error != OK:
		store.message = "保存失败，原数据未改动。请检查磁盘空间和目录权限。"
		if is_instance_valid(notice): notice.text = store.message
		return false
	store.data = candidate
	store.message = ""
	return true

func _preference(key: String, value: Variant) -> void:
	var candidate: Dictionary = store.data.duplicate(true)
	candidate[key] = value
	if _commit(candidate):
		get_window().always_on_top = store.data.topmost
		if key == "quiet": _set_action(4 if value else 5, 0.0 if value else 3.0)
		_geometry()
		queue_redraw()

func _build_tray() -> void:
	menu = PopupMenu.new()
	menu.add_item("显示提提", 0)
	menu.add_item("今日待办", 1)
	menu.add_item("设置", 2)
	menu.add_separator()
	menu.add_item("隐藏提提", 3)
	menu.add_item("退出提提", 4)
	add_child(menu)
	menu.id_pressed.connect(func(id: int):
		match id:
			0: _show_pet()
			1: _show_panel("todo")
			2: _show_panel("settings")
			3: _hide_pet()
			4: _quit()
	)
	if DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		tray = StatusIndicator.new()
		tray.icon = textures[1]
		tray.tooltip = "提提 · 今日待办"
		add_child(tray)
		tray.menu = tray.get_path_to(menu)
		tray.pressed.connect(func(_button: int, _position: Vector2i):
			if tray.menu.is_empty(): _show_panel("todo")
		)

func _hide_pet() -> void:
	if tray == null: return
	panel.hide()
	hidden_pet = true
	get_window().hide()
	Engine.max_fps = 5

func _show_pet() -> void:
	hidden_pet = false
	get_window().show()
	Engine.max_fps = 30

func _set_action(value: int, seconds := 0.0) -> void:
	if action != value: animation_time = 0.0
	action = value
	action_time = seconds
	idle_time = 0.0
	_geometry()
	queue_redraw()

func _geometry() -> void:
	if textures.is_empty(): return
	var size: Vector2 = textures[action].get_size()
	var scale_value: float = (float(store.data.size) / 210.0) * 104.0 / animation.head_widths[action]
	var extent := size * scale_value
	pet_rect = Rect2(Vector2(PET_CENTER_X - extent.x * BODY_ANCHORS[action], 304.0 - extent.y), extent)
	var points := PackedVector2Array()
	for point in polygons[action]: points.append(pet_rect.position + point * scale_value)
	if toolbar.visible:
		var bounds := toolbar.get_rect().grow(4)
		points.append_array(PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]))
	get_window().mouse_passthrough_polygon = Geometry2D.convex_hull(points)

func _draw() -> void:
	if textures.is_empty(): return
	var rectangle := pet_rect
	var texture: Texture2D = animation.texture(action, animation_time)
	draw_texture_rect(texture, rectangle, false)

func _draw_local_motion(texture: Texture2D, rectangle: Rect2) -> void:
	const GRID := 12
	for y in GRID:
		for x in GRID:
			var uv := PackedVector2Array([
				Vector2(x, y) / GRID, Vector2(x + 1, y) / GRID,
				Vector2(x + 1, y + 1) / GRID, Vector2(x, y + 1) / GRID
			])
			var points := PackedVector2Array()
			for point in uv:
				points.append(rectangle.position + point * rectangle.size + animation.deformation(action, point, animation_time, rectangle.size))
			draw_polygon(points, PackedColorArray([Color.WHITE]), uv, texture)

func _process(delta: float) -> void:
	if hidden_pet: return
	clock += delta
	if not dragging: animation_time += delta
	if action_time > 0.0:
		action_time -= delta
		if action_time <= 0.0: _set_action(4 if store.data.quiet else 1)
	if click_time > 0:
		click_time -= delta
		if click_time <= 0: _set_action(3, 3.5)
	var local := Vector2(DisplayServer.mouse_get_position() - get_window().position)
	var bridge := pet_rect.merge(toolbar.get_rect()).grow(6)
	var near := pet_rect.grow(10).has_point(local) or (toolbar.visible and bridge.has_point(local))
	if near or panel.visible or pressed: inactivity = 0.0
	else: inactivity += delta
	if near and not pressed:
		hover_time += delta
		away_time = 0.0
		if hover_time >= 0.3: _show_toolbar()
	else:
		hover_time = 0.0
		away_time += delta
		if away_time > 0.45: _hide_toolbar()
	if pressed:
		var distance := DisplayServer.mouse_get_position() - mouse_start
		if distance.length() >= 8:
			dragging = true
			click_time = 0
			_hide_toolbar(true)
			get_window().position = window_start + distance
			_clamp_position()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): _release()
	elif not near and not panel.visible and not store.data.quiet and action_time <= 0:
		idle_time += delta
		if action == 1 and inactivity > 90: _set_action(4)
		elif action == 1 and idle_time > 22: _set_action(0, 3.5)
		if action == 4 and idle_time > 80: _set_action(5, 3.0)
	if panel.visible and page == "todo" and last_day != Time.get_date_string_from_system(): _render_panel()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			menu.position = DisplayServer.mouse_get_position()
			menu.popup()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if toolbar.visible and toolbar.get_rect().has_point(event.position): return
				if not pet_rect.has_point(event.position): return
				pressed = true
				dragging = false
				mouse_start = DisplayServer.mouse_get_position()
				window_start = get_window().position
				if event.double_click:
					click_time = 0
					_set_action(2, 4.5)
					pressed = false
			else: _release()

func _release() -> void:
	if not pressed: return
	var distance := DisplayServer.mouse_get_position() - mouse_start
	if distance.length() >= 8:
		dragging = true
		get_window().position = window_start + distance
		_clamp_position()
	pressed = false
	if dragging:
		dragging = false
		var candidate: Dictionary = store.data.duplicate(true)
		candidate.position = [get_window().position.x, get_window().position.y]
		_commit(candidate)
		_geometry()
	else: click_time = 0.32

func _clamp_position() -> void:
	var areas: Array[Rect2i] = []
	for index in DisplayServer.get_screen_count(): areas.append(DisplayServer.screen_get_usable_rect(index))
	get_window().position = preload("res://desktop/window_geometry.gd").restore_position(get_window().position, get_window().size, areas)

func _quit() -> void:
	get_tree().quit()

func _exit_tree() -> void:
	guard.release()
