extends Node

const Plan = preload("res://study/study_plan.gd")
const Store = preload("res://study/plan_store.gd")
const ThemeResource = preload("res://ui/study_theme.tres")
const DEFAULT_SKIN = preload("res://pet/skins/warm_jade/skin.tres")
var plan = Plan.new()
var store = Store.new()
var pet = preload("res://pet/pet_view.gd").new()
var desktop = preload("res://desktop/pet_window.gd").new()
var breath_effect = preload("res://pet/effects/goal_light.gd").new()
var current_goal_title := "添加学习目标"
var panel_window: Window
var panel: PanelContainer
var settings_window: Window
var settings: PanelContainer
var preferences := ConfigFile.new()
var companionship = preload("res://pet/companionship.gd").new()
var _preferences_ready := false
var _preferences_error_reported := false
var _active_since_save := 0.0
var _last_growth_tick := 0
var storage_blocked := false
var startup_message := ""
var preferences_path := "user://preferences.cfg"
var instance_guard = preload("res://desktop/single_instance.gd").new()
var startup = preload("res://desktop/startup.gd").new()
var icon_awareness = preload("res://desktop/icon_awareness.gd").new()
var _avoid_target := Vector2.INF
var _avoid_elapsed := 0.0
var _icon_hover := 0.0
var _icon_focus := Vector2.INF

func _ready() -> void:
	var data_directory := OS.get_environment("CLOUD_DRAGON_DATA_DIR")
	var scope := "user://" if data_directory.is_empty() else data_directory
	if not instance_guard.acquire(scope):
		print("已有学习搭子实例，或本地互斥端口不可用；未修改学习数据。")
		get_tree().quit()
		return
	if not data_directory.is_empty():
		DirAccess.make_dir_recursive_absolute(data_directory)
		store = Store.new(data_directory.path_join("plan.json"))
		preferences_path = data_directory.path_join("preferences.cfg")
	Engine.max_fps = 60
	OS.low_processor_usage_mode = false
	OS.low_processor_usage_mode_sleep_usec = 16666
	get_tree().auto_accept_quit = false
	add_child(desktop)
	add_child(breath_effect)
	add_child(pet)
	add_child(icon_awareness)
	pet.position = Vector2(16, 94)
	pet.geometry_changed.connect(_update_geometry)
	var error: Error = pet.apply_skin(DEFAULT_SKIN)
	if error != OK:
		push_error("温玉灵核皮肤加载失败：%s" % error)
		get_tree().quit(1)
		return
	panel = preload("res://ui/plan_panel.tscn").instantiate()
	panel_window = _make_window("学习计划", panel, Vector2i(410, 610))
	settings = preload("res://ui/settings_panel.tscn").instantiate()
	settings_window = _make_window("设置", settings, Vector2i(480, 660))
	panel.complete_requested.connect(_complete)
	panel.next_requested.connect(_next)
	panel.content_replace_requested.connect(_replace)
	panel.settings_requested.connect(_show_settings)
	panel.dismiss_requested.connect(panel_window.hide)
	settings.dismiss_requested.connect(settings_window.hide)
	settings.hide_pet_requested.connect(func(): settings_window.hide(); panel_window.hide(); desktop.hide_pet())
	settings.quit_requested.connect(_quit)
	settings.display_scale_requested.connect(_set_scale)
	settings.action_preview_requested.connect(pet.select_action)
	settings.startup_requested.connect(_set_startup)
	settings.icon_awareness_requested.connect(_set_icon_awareness)
	icon_awareness.state_changed.connect(_refresh_icon_awareness)
	_refresh_startup()
	desktop.pet_clicked.connect(_handle_pet_click)
	desktop.edit_requested.connect(_show_plan)
	desktop.goal_requested.connect(func(): pet.select_action(&"breath"))
	desktop.settings_requested.connect(_show_settings)
	desktop.quit_requested.connect(_quit)
	desktop.pet_visibility_changed.connect(func(active: bool):
		pet.set_active(active)
		icon_awareness.set_active(active)
		OS.low_processor_usage_mode = not active
		if not active:
			panel_window.hide()
			settings_window.hide()
	)
	desktop.drag_started.connect(func(): panel_window.hide(); settings_window.hide(); pet.play_action(&"dragging"))
	desktop.drag_finished.connect(func(_position: Vector2i): pet.play_action(&"idle"); _save_preferences())
	preferences.load(preferences_path)
	companionship.restore(preferences.get_value("companionship", "active_seconds", 0.0))
	_preferences_ready = true
	icon_awareness.set_enabled(bool(preferences.get_value("pet","icon_awareness",true)))
	icon_awareness.set_active(true)
	_last_growth_tick = Time.get_ticks_msec()
	_apply_growth()
	pet.set_display_scale(float(preferences.get_value("pet", "scale", 1.0)))
	var saved: Variant = preferences.get_value("pet", "position", Vector2i(-1, -1))
	if not saved is Vector2i or saved == Vector2i(-1, -1):
		var area := DisplayServer.screen_get_usable_rect()
		saved = area.end - get_window().size - Vector2i(36, 36)
	desktop.restore_visible_position(saved)
	_load_plan()
	_render()
	if not startup_message.is_empty():
		_show_plan()
		panel.show_error(startup_message)
	# Command-line preview supports repeatable screenshot validation; not a product setting.
	var args := OS.get_cmdline_user_args()
	if args.has("--preview-plan"):
		_show_plan()
	if args.has("--preview-settings"):
		_show_settings()
	if args.has("--preview-breath"):
		pet.select_action(&"breath")

func _process(delta: float) -> void:
	if pet.skin == null:
		return
	pet.set_interaction_paused(desktop.context_menu_active())
	_observe_icons(delta)
	if _preferences_ready:
		var now := Time.get_ticks_msec()
		# Godot may cap frame delta after suspend; check the monotonic gap as well.
		var continuous := now - _last_growth_tick <= 2000
		_last_growth_tick = now
		_active_since_save += companionship.advance(delta, continuous and pet.is_active() and get_window().visible)
		_apply_growth()
		if _active_since_save >= 60.0:
			_save_preferences()
	var previous_visible: bool = breath_effect.visible
	var previous_stage: int = breath_effect.stage()
	_sync_breath()
	if previous_visible != breath_effect.visible or (breath_effect.visible and previous_stage != breath_effect.stage()):
		_update_geometry()

func _sync_breath() -> void:
	var active: bool = pet.is_active() and pet.current_action == &"breath"
	if active:
		breath_effect.set_frame(pet.position+pet.map_skin_point(pet.skin.breath_anchor),pet.scale.x,pet.player.current_animation_position,current_goal_title)
	else:
		breath_effect.visible = false

func _load_plan() -> void:
	var result: Dictionary = store.load_plan()
	if result.error == OK:
		plan.data = result.plan.duplicate(true)
		if result.recovered:
			startup_message = "主文件损坏，已恢复上次备份。最新一次进度可能未恢复。"
	elif result.error == ERR_FILE_NOT_FOUND:
		var titles: Array[String] = ["单例模式", "工厂模式", "策略模式", "观察者模式"]
		plan.replace_content("每天学习一个设计模式", titles)
		if store.save_plan(plan.to_dict()) != OK:
			storage_blocked = true
			startup_message = "无法创建学习数据，请检查用户目录权限。"
	else:
		storage_blocked = true
		startup_message = "学习文件与备份无法读取，已保留原文件。请先备份并修复数据。"

func _complete() -> void:
	var candidate = Plan.new()
	candidate.data = plan.to_dict()
	if candidate.mark_current_complete() == OK and _save_candidate(candidate):
		pet.play_action(&"celebrate")

func _next() -> void:
	var candidate = Plan.new()
	candidate.data = plan.to_dict()
	if candidate.start_next() == OK:
		_save_candidate(candidate)

func _replace(goal: String, titles: Array[String]) -> void:
	var candidate = Plan.new()
	if candidate.replace_content(goal, titles) == OK:
		_save_candidate(candidate)

func _save_candidate(candidate: RefCounted) -> bool:
	if storage_blocked:
		panel.show_error("保存已暂停，原文件未改动。请先处理数据目录错误。")
		return false
	var error: Error = store.save_plan(candidate.to_dict())
	if error != OK:
		panel.show_error("保存失败（%s），当前进度保持不变。" % error_string(error))
		return false
	plan = candidate
	_render()
	return true

func _render() -> void:
	panel.render_plan(plan.to_dict())
	var current: Dictionary = {}
	for task in plan.data.tasks:
		if task.id == plan.data.current_id:
			current = task
	if current.is_empty():
		current_goal_title = "添加学习目标"
	else:
		current_goal_title = current.title
	_update_geometry()

func _update_geometry() -> void:
	if not is_instance_valid(breath_effect) or not breath_effect.is_inside_tree():
		return
	var geometry: Dictionary = pet.get_visual_geometry()
	if geometry.is_empty():
		return
	var bounds: Rect2 = geometry.bounds
	pet.position = Vector2(16, 26) - bounds.position
	_sync_breath()
	var outlines: Array[PackedVector2Array] = []
	for outline in geometry.render_polygons:
		var window_points := PackedVector2Array()
		for point in outline:
			window_points.append(pet.position + point)
		outlines.append(window_points)
	outlines = preload("res://desktop/window_geometry.gd").merge_input_outlines(outlines,breath_effect.get_regions())
	var body_points := PackedVector2Array()
	for outline in outlines:
		body_points = preload("res://desktop/window_geometry.gd").combine_input_regions(body_points,outline)
	var extent: Vector2 = bounds.end + pet.position + Vector2(20, 12)
	desktop.set_visual_geometry(Rect2(Vector2.ZERO, extent), body_points)

func _make_window(title: String, content: Control, size: Vector2i) -> Window:
	var window := Window.new()
	window.title = "温玉灵核 · " + title
	window.size = size
	window.min_size = Vector2i(360, 420)
	window.visible = false
	window.transient = false
	window.theme = ThemeResource
	add_child(window)
	window.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.close_requested.connect(window.hide)
	return window

func _place_panel(window: Window) -> void:
	var areas: Array[Rect2i] = desktop.usable_areas()
	window.position = preload("res://desktop/window_geometry.gd").place_panel(Rect2i(get_window().position, get_window().size), window.size, areas)

func _toggle_plan() -> void:
	if panel_window.visible:
		panel_window.hide()
	else:
		_show_plan()

func _handle_pet_click() -> void:
	if breath_effect.contains_point(desktop.last_click_position):
		_toggle_plan()
	else:
		pet.cycle_action()

func _show_plan() -> void:
	desktop.show_pet()
	_place_panel(panel_window)
	panel_window.show()
	panel_window.grab_focus()
	pet.play_action(&"curious")

func _show_settings() -> void:
	_refresh_startup()
	_refresh_icon_awareness()
	panel_window.hide()
	_place_panel(settings_window)
	settings_window.show()
	settings_window.grab_focus()

func _refresh_startup() -> void:
	settings.set_startup_state(startup.available,startup.is_enabled(),startup.message)

func _set_startup(enabled: bool) -> void:
	startup.set_enabled(enabled)
	_refresh_startup()

func _set_icon_awareness(value: bool) -> void:
	icon_awareness.set_enabled(value)
	_refresh_icon_awareness()
	_save_preferences()

func _refresh_icon_awareness() -> void:
	if is_instance_valid(settings): settings.set_icon_awareness_state(icon_awareness.enabled,icon_awareness.status)

func _observe_icons(delta: float) -> void:
	if not pet.actor.has_method("set_desktop_attention"): return
	var now := Time.get_ticks_msec()
	var blocked: bool = not pet.is_active() or desktop.pointer_busy() or panel_window.visible or settings_window.visible or not icon_awareness.fresh(now) or icon_awareness.left_button_down
	var attention := Vector2.ZERO
	if not blocked and pet.current_action == &"idle":
		var target: Dictionary = icon_awareness.attention_target(Vector2(DisplayServer.mouse_get_position()),now)
		if target.has("point"):
			var point: Vector2 = target.point
			_icon_hover = _icon_hover+minf(delta,0.1) if point == _icon_focus else 0.0
			_icon_focus = point
			if _icon_hover >= 0.35:
				var origin: Vector2 = Vector2(get_window().position)+pet.position+pet.map_skin_point(Vector2(220,133))
				attention = (point-origin).normalized()
		else:
			_icon_hover = 0.0
			_icon_focus = Vector2.INF
	pet.actor.set_desktop_attention(attention)
	if blocked or pet.current_action == &"breath":
		_icon_hover = 0.0
		_icon_focus = Vector2.INF
		_avoid_target = Vector2.INF
		return
	_avoid_elapsed += minf(delta,0.1)
	var window := get_window()
	if _avoid_elapsed >= 2.0 and _avoid_target == Vector2.INF:
		_avoid_elapsed = 0.0
		var rectangle := Rect2(Vector2(window.position),Vector2(window.size))
		var footprint := Rect2(Vector2(window.position)+pet.position+Vector2(10,-190)*pet.scale,Vector2(420,505)*pet.scale)
		for area in desktop.usable_areas():
			if Rect2(area).has_point(rectangle.get_center()):
				var position: Vector2 = icon_awareness.avoid_position(rectangle,footprint,Rect2(area),now)
				if position.distance_to(rectangle.position) > 2: _avoid_target = position
				break
	if _avoid_target != Vector2.INF:
		var next := Vector2(window.position).move_toward(_avoid_target,110.0*minf(delta,0.1))
		desktop.restore_visible_position(Vector2i(next.round()))
		if Vector2(window.position).distance_to(_avoid_target) < 2:
			_avoid_target = Vector2.INF
			_avoid_elapsed = -3.0

func _set_scale(value: float) -> void:
	pet.set_display_scale(value)
	_save_preferences()

func _save_preferences() -> void:
	if not _preferences_ready:
		return
	preferences.set_value("pet", "scale", pet.scale.x)
	preferences.set_value("pet", "position", get_window().position)
	preferences.set_value("companionship", "active_seconds", companionship.active_seconds)
	preferences.set_value("pet","icon_awareness",icon_awareness.enabled)
	_active_since_save = 0.0
	if preferences.save(preferences_path) != OK and not _preferences_error_reported:
		_preferences_error_reported = true
		panel.show_error("设置与陪伴时长未能保存，请检查数据目录权限。")

func _apply_growth() -> void:
	if is_instance_valid(pet.actor) and pet.actor.has_method("set_growth"):
		pet.actor.set_growth(companionship.progress())

func _quit() -> void:
	_save_preferences()
	get_tree().quit()

func _exit_tree() -> void:
	instance_guard.release()
