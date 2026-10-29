extends Node

signal pet_clicked
signal drag_started
signal drag_finished(position: Vector2i)
signal pet_visibility_changed(is_visible: bool)
signal edit_requested
signal goal_requested
signal settings_requested
signal focus_requested
signal quit_requested

const Geometry = preload("res://desktop/window_geometry.gd")
var _window: Window
var _pressed := false
var _dragging := false
var _press_mouse := Vector2i.ZERO
var _press_window := Vector2i.ZERO
var last_click_position := Vector2(-1000, -1000)
var _press_local := Vector2.ZERO
var _tray: StatusIndicator
var _menu: PopupMenu
var _right_pressed := false
var _context_pending := false
var _font_level := 0
var _menu_font_size := 16
var topmost_enabled := true

func _ready() -> void:
	_window = get_window()
	_window.gui_embed_subwindows = false
	_window.transparent = true
	_window.transparent_bg = true
	_window.borderless = true
	_window.always_on_top = topmost_enabled
	_window.unresizable = true
	_window.unfocusable = true
	# The desktop compositor presents this transparent window; avoid a second GL
	# swap wait falling to half refresh. main.gd retains the 60 FPS engine cap.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED, _window.get_window_id())
	_window.close_requested.connect(func(): quit_requested.emit())
	set_process(false)
	_menu = PopupMenu.new()
	_menu.name = "PetContextMenu"
	_menu.add_item("显示宠物", 0)
	_menu.add_item("今日目标（引光）", 4)
	_menu.add_item("学习计划…", 1)
	_menu.add_item("专注计时…", 6)
	_menu.add_item("设置…", 5)
	_menu.add_separator()
	_menu.add_item("隐藏宠物", 2)
	_menu.add_item("退出", 3)
	add_child(_menu)
	_menu_font_size = _menu.get_theme_font_size("font_size")
	_menu.id_pressed.connect(_on_menu)
	if DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		_tray = StatusIndicator.new()
		_tray.tooltip = "温玉灵核学习搭子 · 点击恢复，右键菜单"
		var image := GradientTexture2D.new()
		image.width = 32
		image.height = 32
		image.gradient = Gradient.new()
		image.gradient.colors = PackedColorArray([Color("357fe5"), Color("e6f3ff")])
		_tray.icon = image
		add_child(_tray)
		if NativeMenu.has_feature(NativeMenu.FEATURE_POPUP_MENU):
			# Let Windows own the tray popup and dismiss its overflow panel correctly.
			_tray.menu = _tray.get_path_to(_menu)
		_tray.pressed.connect(func(button: int, _position: Vector2i):
			if button == MOUSE_BUTTON_LEFT:
				if OS.get_name() == "macOS" and _font_level > 0:
					_queue_context_menu()
				else:
					show_pet()
			elif button == MOUSE_BUTTON_RIGHT and _tray.menu.is_empty():
				_queue_context_menu()
		)
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(func():
		if _window.visible and not _pressed:
			restore_visible_position(_window.position)
			_ensure_topmost()
	)
	add_child(timer)
	timer.start()
	_ensure_topmost.call_deferred()

func _ensure_topmost() -> void:
	if DisplayServer.get_name() == "headless" or not _window.visible or _window.mode == Window.MODE_MINIMIZED:
		return
	# Reassert at the display server: the Window property can already be true
	# while native window style or mode transitions have changed its Z order.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, topmost_enabled, _window.get_window_id())

func set_topmost(enabled: bool) -> void:
	topmost_enabled = enabled
	if is_instance_valid(_window):
		_window.always_on_top = enabled
		_ensure_topmost()

func set_visual_geometry(bounds: Rect2, hit_polygon: PackedVector2Array) -> void:
	var next_size := Vector2i(bounds.end.ceil())
	if _window.size != next_size:
		_window.size = next_size
		restore_visible_position(_window.position)
	_window.mouse_passthrough_polygon = hit_polygon

func set_font_level(level: int) -> void:
	_font_level = preload("res://ui/font_scale.gd").valid_level(level)
	_menu.hide()
	# Native system menus ignore application font sizes. Detach the tray menu
	# for larger levels and use the existing pressed -> popup fallback.
	if is_instance_valid(_tray):
		_tray.menu = _tray.get_path_to(_menu) if _font_level == 0 and NativeMenu.has_feature(NativeMenu.FEATURE_POPUP_MENU) else NodePath("")
	_menu.prefer_native_menu = false
	var menu_theme := Theme.new()
	menu_theme.set_font_size("font_size","PopupMenu",roundi(_menu_font_size*preload("res://ui/font_scale.gd").FACTORS[_font_level]))
	_menu.theme = menu_theme
	_menu.reset_size()

func usable_areas() -> Array[Rect2i]:
	var areas: Array[Rect2i] = []
	for screen in DisplayServer.get_screen_count():
		areas.append(DisplayServer.screen_get_usable_rect(screen))
	return areas

func pointer_busy() -> bool:
	return _pressed or _dragging or context_menu_active()

func context_menu_active() -> bool:
	return _right_pressed or _context_pending or (is_instance_valid(_menu) and _menu.visible)

func restore_visible_position(saved: Vector2i) -> void:
	var constrained := Geometry.restore_position(saved, _window.size, usable_areas())
	if _window.position != constrained:
		_window.position = constrained

func show_pet() -> void:
	restore_visible_position(_window.position)
	_window.mode = Window.MODE_WINDOWED
	_ensure_topmost.call_deferred()
	pet_visibility_changed.emit(true)

func hide_pet() -> void:
	# A missing tray must never make the only recovery entry disappear.
	if _tray == null:
		edit_requested.emit()
		return
	_window.mode = Window.MODE_MINIMIZED
	pet_visibility_changed.emit(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_dragging = false
				_press_mouse = DisplayServer.mouse_get_position()
				_press_window = _window.position
				_press_local = event.position
				set_process(true)
			else:
				_finish_pointer(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			if event.pressed:
				_right_pressed = true
			elif _right_pressed:
				_right_pressed = false
				_queue_context_menu()

func _queue_context_menu() -> void:
	if _context_pending: return
	_context_pending = true
	_finish_context_menu.call_deferred()

func _finish_context_menu() -> void:
	_context_pending = false
	_show_context_menu()

func _show_context_menu() -> void:
	_menu.position = DisplayServer.mouse_get_position()
	_menu.popup()

func _process(_delta: float) -> void:
	if not _pressed:
		return
	var distance := DisplayServer.mouse_get_position() - _press_mouse
	if not _dragging and Vector2(distance).length() >= 8.0:
		_dragging = true
		drag_started.emit()
	if _dragging:
		# Clamp every drag frame, not just on release: the whole animated pet stays visible.
		restore_visible_position(_press_window + distance)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_pointer()

func _finish_pointer(release_position: Variant = null) -> void:
	if not _pressed:
		return
	# A complete drag can happen between two render frames. It must not become a click.
	if not _dragging and release_position is Vector2 and release_position.distance_to(_press_local) >= 8.0:
		_dragging = true
		drag_started.emit()
		restore_visible_position(_press_window + Vector2i(release_position - _press_local))
	_pressed = false
	set_process(false)
	if _dragging:
		restore_visible_position(_window.position)
		drag_finished.emit(_window.position)
	else:
		last_click_position = _press_local
		pet_clicked.emit()
	_dragging = false

func _on_menu(id: int) -> void:
	_menu.hide()
	match id:
		0: show_pet()
		1:
			show_pet()
			edit_requested.emit()
		2: hide_pet()
		3: quit_requested.emit()
		4:
			show_pet()
			goal_requested.emit()
		5:
			show_pet()
			settings_requested.emit()
		6:
			show_pet()
			focus_requested.emit()
