extends Node

signal pet_clicked
signal drag_started
signal drag_finished(position: Vector2i)
signal pet_visibility_changed(is_visible: bool)
signal edit_requested
signal goal_requested
signal settings_requested
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

func _ready() -> void:
	_window = get_window()
	_window.gui_embed_subwindows = false
	_window.transparent = true
	_window.transparent_bg = true
	_window.borderless = true
	_window.always_on_top = false
	_window.unresizable = true
	_window.unfocusable = true
	# The desktop compositor presents this transparent window; avoid a second GL
	# swap wait falling to half refresh. main.gd retains the 60 FPS engine cap.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED, _window.get_window_id())
	_window.close_requested.connect(hide_pet)
	set_process(false)
	_menu = PopupMenu.new()
	_menu.add_item("显示宠物", 0)
	_menu.add_item("今日目标（引光）", 4)
	_menu.add_item("学习计划…", 1)
	_menu.add_item("设置…", 5)
	_menu.add_separator()
	_menu.add_item("隐藏宠物", 2)
	_menu.add_item("退出", 3)
	add_child(_menu)
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
		_tray.pressed.connect(func(button: int, _position: Vector2i):
			if button == MOUSE_BUTTON_LEFT:
				show_pet()
			elif button == MOUSE_BUTTON_RIGHT:
				_show_context_menu()
		)
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(func():
		if _window.visible and not _pressed:
			restore_visible_position(_window.position)
	)
	add_child(timer)
	timer.start()

func set_visual_geometry(bounds: Rect2, hit_polygon: PackedVector2Array) -> void:
	var next_size := Vector2i(bounds.end.ceil())
	if _window.size != next_size:
		_window.size = next_size
		restore_visible_position(_window.position)
	_window.mouse_passthrough_polygon = hit_polygon

func usable_areas() -> Array[Rect2i]:
	var areas: Array[Rect2i] = []
	for screen in DisplayServer.get_screen_count():
		areas.append(DisplayServer.screen_get_usable_rect(screen))
	return areas

func pointer_busy() -> bool:
	return _pressed or _dragging

func restore_visible_position(saved: Vector2i) -> void:
	var constrained := Geometry.restore_position(saved, _window.size, usable_areas())
	if _window.position != constrained:
		_window.position = constrained

func show_pet() -> void:
	restore_visible_position(_window.position)
	_window.mode = Window.MODE_WINDOWED
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
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
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
