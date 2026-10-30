extends Node

const AIMemory = preload("res://ai/memory_store.gd")
const AIConfig = preload("res://ai/config_store.gd")
const Plan = preload("res://study/study_plan.gd")
const Store = preload("res://study/plan_store.gd")
const ThemeResource = preload("res://ui/study_theme.tres")
const DEFAULT_SKIN = preload("res://pet/skins/warm_jade/skin.tres")
const Appearance = preload("res://pet/appearance.gd")
const SkinCatalog = preload("res://pet/skin_catalog.gd")
const PreferencesStore = preload("res://study/preferences_store.gd")
const PlanTransfer = preload("res://study/plan_transfer.gd")
var ai_brain = preload("res://ai/companion_brain.gd").new()
var ai_bubble = preload("res://ui/ai_bubble.gd").new()
var ai_config: Dictionary = AIConfig.defaults()
var ai_config_path := "user://ai_private.cfg"
var ai_memory_path := "user://ai_memory.json"
var ai_memory_data: Dictionary = AIMemory.defaults()
var chat_panel: PanelContainer
var chat_window: Window
var _chat_clear_dialog := ConfirmationDialog.new()
var _ai_memory_blocked := false
var _ai_chat_pending := false
var _ai_chat_pending_text := ""
var _ai_chat_pending_role := ""
var _ai_manual_caption := false
var _ai_request_skin := ""
var _ai_testing := false
var _ai_fallback := false
var _ai_idle_elapsed := 0.0
var _ai_event := ""
var _ai_event_at := 0
var _ai_recent_actions: Array[String] = []
var focus_session = preload("res://study/focus_session.gd").new()
var scheduler = preload("res://pet/ambient_scheduler.gd").new()
var screen_roaming = preload("res://pet/screen_roaming.gd").new()
var social_interaction = preload("res://pet/social_interaction.gd").new()
var data_dialog = preload("res://ui/plan_data_dialog.gd").new()
var companion_mode := "natural"
var reduced_motion := false
var performance_mode := "smooth"
var topmost_enabled := true
var _preferences_blocked := false
var _last_session_tick := 0
var _session_since_save := 0.0
var _ambient_elapsed := 0.0
var _focus_display_key := ""
var _pending_import: Dictionary = {}
var _first_plan := false
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
var startup = preload("res://desktop/startup_macos.gd").new() if OS.get_name() == "macOS" else preload("res://desktop/startup.gd").new()
var icon_awareness = preload("res://desktop/icon_awareness.gd").new()
var _avoid_target := Vector2.INF
var _avoid_elapsed := 0.0
var _icon_hover := 0.0
var _icon_focus := Vector2.INF
var font_level := 0
var renderer_mode := "3d"
var selected_skin := "warm_jade"
var _last_animal_click := -1000

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
		ai_config_path = data_directory.path_join("ai_private.cfg")
		ai_memory_path = data_directory.path_join("ai_memory.json")
	Engine.max_fps = 60
	OS.low_processor_usage_mode = false
	OS.low_processor_usage_mode_sleep_usec = 16666
	get_tree().auto_accept_quit = false
	add_child(desktop)
	add_child(breath_effect)
	add_child(pet)
	add_child(ai_brain)
	add_child(ai_bubble)
	ai_bubble.activated.connect(_show_ai_chat)
	ai_brain.decision_ready.connect(_on_ai_decision)
	ai_brain.failed.connect(_on_ai_failure)
	ai_brain.chat_ready.connect(_on_ai_chat_ready)
	ai_brain.status_changed.connect(func(message):
		if is_instance_valid(settings): settings.ai_panel.set_status(message,ai_brain.busy)
		if is_instance_valid(chat_panel) and _ai_chat_pending: chat_panel.set_status(message,ai_brain.busy)
	)
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
	settings_window = _make_window("设置", settings, Vector2i(480, 720))
	settings.ai_panel.save_requested.connect(_save_ai_settings)
	settings.ai_panel.test_requested.connect(_test_ai_connection)
	settings.ai_panel.chat_requested.connect(_show_ai_chat)
	chat_panel = preload("res://ui/ai_chat_panel.gd").new()
	chat_window = _make_window("聊天与记忆",chat_panel,Vector2i(520,720))
	chat_panel.send_requested.connect(_send_ai_chat)
	chat_panel.cancel_requested.connect(_cancel_ai_chat)
	chat_panel.preferences_requested.connect(_save_ai_preferences)
	chat_panel.persona_requested.connect(_save_ai_persona)
	chat_panel.clear_history_requested.connect(func(): _chat_clear_dialog.popup_centered(Vector2i(380,220)))
	chat_panel.dismiss_requested.connect(chat_window.hide)
	chat_window.visibility_changed.connect(func():
		if not chat_window.visible and _ai_chat_pending: _interrupt_ai()
	)
	_chat_clear_dialog.title = "清空当前伙伴的对话"
	_chat_clear_dialog.dialog_text = "清空当前伙伴的聊天记录？已保存的喜好和伙伴性格会保留。"
	_chat_clear_dialog.dialog_autowrap = true
	_chat_clear_dialog.ok_button_text = "清空对话"
	_chat_clear_dialog.cancel_button_text = "取消"
	_chat_clear_dialog.theme = ThemeResource.duplicate(true)
	chat_window.add_child(_chat_clear_dialog)
	preload("res://ui/window_chrome.gd").install(_chat_clear_dialog)
	_chat_clear_dialog.confirmed.connect(_clear_ai_chat_history)
	panel.complete_requested.connect(_complete)
	panel.next_requested.connect(_next)
	panel.content_replace_requested.connect(_replace)
	panel.settings_requested.connect(_show_settings)
	panel.dismiss_requested.connect(panel_window.hide)
	panel.layout_changed.connect(func(): _fit_settings_font.call_deferred())
	panel.append_requested.connect(_append_task)
	panel.details_requested.connect(_revise_current)
	panel.undo_requested.connect(_undo_complete)
	panel.focus_requested.connect(_focus_action)
	settings.dismiss_requested.connect(settings_window.hide)
	settings.hide_pet_requested.connect(func(): settings_window.hide(); panel_window.hide(); desktop.hide_pet())
	settings.quit_requested.connect(_quit)
	settings.display_scale_requested.connect(_set_scale)
	settings.action_preview_requested.connect(pet.select_action)
	settings.appearance_requested.connect(_set_appearance)
	settings.skin_requested.connect(_set_skin)
	settings.startup_requested.connect(_set_startup)
	settings.icon_awareness_requested.connect(_set_icon_awareness)
	settings.font_level_requested.connect(_set_font_level)
	settings.renderer_mode_requested.connect(_set_renderer_mode)
	settings.companion_mode_requested.connect(_set_companion_mode)
	settings.reduced_motion_requested.connect(_set_reduced_motion)
	settings.performance_requested.connect(_set_performance)
	settings.topmost_requested.connect(_set_topmost)
	settings.data_action_requested.connect(_data_action)
	add_child(data_dialog)
	data_dialog.setup(settings_window)
	data_dialog.import_path_selected.connect(_import_file)
	data_dialog.export_path_selected.connect(func(path: String, kind: String): _export_plan(kind, path))
	data_dialog.import_confirmed.connect(_confirm_import)
	_bind_renderer_signal()
	icon_awareness.state_changed.connect(_refresh_icon_awareness)
	_refresh_startup()
	desktop.pet_clicked.connect(_handle_pet_click)
	desktop.affection_requested.connect(func(): _manual_social(&"nuzzle"))
	desktop.edit_requested.connect(_show_plan)
	desktop.goal_requested.connect(_show_plan)
	desktop.chat_requested.connect(_show_ai_chat)
	desktop.settings_requested.connect(_show_settings)
	desktop.focus_requested.connect(_show_plan)
	desktop.quit_requested.connect(_quit)
	desktop.pet_visibility_changed.connect(func(active: bool):
		_interrupt_ai()
		pet.set_active(active)
		icon_awareness.set_active(active and _ambient_enabled())
		OS.low_processor_usage_mode = not active
		Engine.max_fps = 10 if not active else (30 if performance_mode == "eco" else 60)
		scheduler.reset()
		if not active:
			panel_window.hide()
			settings_window.hide()
			chat_window.hide()
	)
	desktop.drag_started.connect(func(): _interrupt_ai(); panel_window.hide(); settings_window.hide(); pet.play_action(&"dragging"))
	desktop.drag_finished.connect(func(_position: Vector2i): pet.play_action(&"idle"); _save_preferences())
	var preferences_result: Dictionary = PreferencesStore.load_config(preferences_path)
	preferences = preferences_result.config
	_preferences_blocked = preferences_result.error not in [OK, ERR_FILE_NOT_FOUND]
	_apply_skin_id(preferences.get_value("pet", "skin_id", "warm_jade"))
	_apply_renderer_mode(str(preferences.get_value("pet","renderer_mode","3d")))
	_apply_font_level(preferences.get_value("ui","font_level",0))
	_apply_appearance(preferences.get_value("pet","appearance_style","jade"),preferences.get_value("pet","appearance_color","jade"))
	companionship.restore(preferences.get_value("companionship", "active_seconds", 0.0))
	focus_session.restore(preferences.get_value("focus", "session", {}))
	companion_mode = "quiet" if preferences.get_value("pet", "companion_mode", "natural") == "quiet" else "natural"
	reduced_motion = preferences.get_value("pet", "reduced_motion", false) == true
	performance_mode = "eco" if preferences.get_value("pet", "performance", "smooth") == "eco" else "smooth"
	topmost_enabled = preferences.get_value("pet", "topmost", true) != false
	_preferences_ready = true
	icon_awareness.set_enabled(OS.get_name() == "Windows" and bool(preferences.get_value("pet","icon_awareness",true)))
	_apply_companion_options()
	_load_ai_settings()
	_load_ai_memory()
	_last_growth_tick = Time.get_ticks_msec()
	_last_session_tick = _last_growth_tick
	_apply_growth()
	var scale_value: Variant = preferences.get_value("pet", "scale", 1.0)
	pet.set_display_scale(float(scale_value) if (scale_value is float or scale_value is int) and is_finite(float(scale_value)) else 1.0)
	settings.set_display_scale_selection(pet.scale.x)
	var saved: Variant = preferences.get_value("pet", "position", Vector2i(-1, -1))
	if not saved is Vector2i or saved == Vector2i(-1, -1):
		var area := DisplayServer.screen_get_usable_rect()
		saved = area.end - get_window().size - Vector2i(36, 36)
	desktop.restore_visible_position(saved)
	_load_plan()
	_render()
	_refresh_focus_ui()
	if _first_plan:
		_show_plan()
		panel.show_notice("欢迎。轻点玉核看动作，按住拖动，右键打开菜单。这里是示例清单，你可以追加任务或替换成自己的计划。")
	if _preferences_blocked:
		startup_message += "\n设置文件与备份无法读取，已保留原文件；本次使用默认设置且暂停保存设置。可在数据与帮助中打开数据目录。"
	elif preferences_result.recovered:
		startup_message += "\n设置主文件损坏，已恢复上次设置备份。"
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
	_tick_companion()
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
	var allowed: bool = _ambient_enabled() and pet.is_active() and get_window().visible and get_window().mode != Window.MODE_MINIMIZED and not desktop.pointer_busy() and not panel_window.visible and not settings_window.visible and pet.current_action == &"idle"
	_tick_ai(_ambient_elapsed,allowed)
	var local_allowed: bool = allowed and _ai_surface_allowed() and not ai_brain.busy
	var next_action: StringName = scheduler.step(_ambient_elapsed, local_allowed, pet.skin.action_map.keys())
	if next_action != &"":
		if not pet.skin.action_map.has(next_action): next_action = &"curious"
		pet.play_action(next_action)
	var roam_allowed: bool = _ambient_enabled() and _ai_surface_allowed()
	var next_position: Vector2i = screen_roaming.step(_ambient_elapsed,get_window().position,get_window().size,desktop.usable_areas(),pet.current_action,roam_allowed)
	if next_position != get_window().position:
		desktop.restore_visible_position(next_position)

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
		_first_plan = true
		var titles: Array[String] = ["单例模式", "工厂模式", "策略模式", "观察者模式"]
		plan.replace_content("每天学习一个设计模式", titles)
		if store.save_plan(plan.to_dict()) != OK:
			storage_blocked = true
			startup_message = "无法创建学习数据，请检查用户目录权限。"
	else:
		storage_blocked = true
		startup_message = "学习文件与备份无法读取，已保留原文件。请先备份并修复数据。"

func _complete() -> void:
	for task in plan.data.tasks:
		if task.id == plan.data.current_id and task.completed: return
	var candidate = Plan.new()
	candidate.data = plan.to_dict()
	if candidate.mark_current_complete() == OK and _save_candidate(candidate):
		pet.play_action(&"celebrate")
		_queue_ai_event("task_completed")

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
	preload("res://ui/window_chrome.gd").install(window)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = preload("res://ui/window_chrome.gd").HEIGHT
	var surface: StyleBoxFlat = ThemeResource.get_stylebox("panel","PanelContainer").duplicate()
	surface.corner_radius_top_left = 0
	surface.corner_radius_top_right = 0
	content.add_theme_stylebox_override("panel",surface)
	window.close_requested.connect(window.hide)
	window.window_input.connect(func(event: InputEvent):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			window.hide()
			window.set_input_as_handled()
	)
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
	_interrupt_ai()
	if desktop.last_click_double:
		pet.select_action(&"greet" if selected_skin == "warm_jade" else &"bow")
		return
	pet.select_action(&"look")
	if not ai_config.get("bubbles",true):
		_show_ai_chat()
		return
	var greetings := {"warm_jade":"我在这里，点这句话聊聊。","corgi":"我来啦，想聊点什么？","duck":"有什么新鲜事？点这里聊聊。","jellyfish":"慢慢说，我听着呢。"}
	_ai_manual_caption = true
	ai_bubble.show_message(greetings.get(selected_skin,"点这里，和我聊聊。"),_ai_actor_rect(),desktop.usable_areas(),font_level,topmost_enabled)

func _show_plan() -> void:
	_interrupt_ai()
	chat_window.hide()
	desktop.show_pet()
	settings_window.hide()
	_place_panel(panel_window)
	panel_window.show()
	panel_window.grab_focus()
	pet.play_action(&"curious")

func _show_settings() -> void:
	_interrupt_ai()
	chat_window.hide()
	_refresh_startup()
	_refresh_icon_awareness()
	_refresh_focus_ui()
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
	icon_awareness.set_active(pet.is_active() and _ambient_enabled())
	_refresh_icon_awareness()
	_save_preferences()

func _refresh_icon_awareness() -> void:
	if is_instance_valid(settings): settings.set_icon_awareness_state(icon_awareness.enabled,icon_awareness.status)

func _observe_icons(delta: float) -> void:
	if not pet.actor.has_method("set_desktop_attention"): return
	if selected_skin != "warm_jade":
		_observe_animal_pointer()
		return
	var now := Time.get_ticks_msec()
	var origin: Vector2 = Vector2(get_window().position)+pet.position+pet.map_skin_point(Vector2(220,133))
	var relative_pointer: Vector2 = (Vector2(DisplayServer.mouse_get_position())-origin)/maxf(0.5,pet.scale.x)
	var response: Dictionary = social_interaction.step(_ambient_elapsed, relative_pointer, _social_allowed())
	var blocked: bool = not _social_allowed() or not icon_awareness.fresh(now) or icon_awareness.left_button_down
	var attention: Vector2 = response.attention
	if response.action != &"": pet.play_action(response.action)
	if not blocked and pet.current_action == &"idle":
		var target: Dictionary = icon_awareness.attention_target(Vector2(DisplayServer.mouse_get_position()),now)
		if target.has("point"):
			var point: Vector2 = target.point
			_icon_hover = _icon_hover+minf(delta,0.1) if point == _icon_focus else 0.0
			_icon_focus = point
			if _icon_hover >= 0.35:
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

func _social_allowed() -> bool:
	return pet.skin != null and pet.skin.id == &"warm_jade" and _ambient_enabled() and pet.is_active() and get_window().visible and get_window().mode != Window.MODE_MINIMIZED and pet.current_action == &"idle" and not desktop.pointer_busy() and not panel_window.visible and not settings_window.visible

func _manual_social(action: StringName) -> void:
	_interrupt_ai()
	if pet.skin != null and pet.skin.action_map.has(action):
		pet.select_action(action)
		social_interaction.reset()

func _observe_animal_pointer() -> void:
	var attention := Vector2.ZERO
	var allowed: bool = _ambient_enabled() and pet.is_active() and pet.current_action == &"idle" and not desktop.pointer_busy() and not panel_window.visible and not settings_window.visible
	if allowed:
		var local: Vector2 = (Vector2(DisplayServer.mouse_get_position() - get_window().position) - pet.position) / pet.scale
		var offset: Vector2 = local - pet.skin.visual_bounds.get_center()
		if offset.length() < 300.0:
			attention = offset.limit_length(150.0) / 150.0
	pet.actor.set_desktop_attention(attention)

func _set_scale(value: float) -> void:
	pet.set_display_scale(value)
	settings.set_display_scale_selection(pet.scale.x)
	_save_preferences()

func _apply_renderer_mode(mode: String) -> void:
	renderer_mode = "3d" if mode == "3d" else "2d"
	if pet.actor.has_method("set_render_mode"): pet.actor.set_render_mode(renderer_mode)
	settings.appearance_preview.set_render_mode(renderer_mode)
	settings.set_renderer_mode(renderer_mode)

func _bind_renderer_signal() -> void:
	if pet.actor.has_signal("renderer_failed"):
		var actor_id: int = pet.actor.get_instance_id()
		pet.actor.connect("renderer_failed", func(message: String):
			_recover_skin_renderer.call_deferred(message, actor_id)
		)

func _recover_skin_renderer(message: String, source_id: int) -> void:
	if not is_instance_valid(pet.actor) or pet.actor.get_instance_id() != source_id: return
	if selected_skin != "warm_jade": _set_skin("warm_jade")
	else: _set_renderer_mode("2d")
	settings.set_renderer_mode(renderer_mode, message)

func _apply_skin_id(value: Variant) -> void:
	_interrupt_ai(true)
	var next_id := SkinCatalog.skin_id(value)
	if pet.skin == null or String(pet.skin.id) != next_id:
		var error: Error = pet.apply_skin(SkinCatalog.load_skin(next_id))
		if error != OK:
			next_id = "warm_jade"
			pet.apply_skin(DEFAULT_SKIN)
		_bind_renderer_signal()
	selected_skin = next_id
	if is_instance_valid(chat_panel): _refresh_ai_chat()
	_last_animal_click = -1000
	_avoid_target = Vector2.INF
	_icon_hover = 0.0
	settings.set_skin_selection(next_id)
	preferences.set_value("pet", "skin_id", next_id)
	_apply_appearance(preferences.get_value("pet", "appearance_style", "jade"), preferences.get_value("pet", "appearance_color", "jade"))
	_apply_renderer_mode(renderer_mode)
	_apply_companion_options()
	_apply_growth()
	_update_geometry()

func _set_skin(id: String) -> void:
	_apply_skin_id(id)
	_save_preferences()

func _set_renderer_mode(mode: String) -> void:
	_apply_renderer_mode(mode)
	_save_preferences()

func _apply_font_level(value: Variant) -> void:
	font_level = preload("res://ui/font_scale.gd").valid_level(value)
	settings.set_font_level(font_level)
	panel.set_font_level(font_level)
	desktop.set_font_level(font_level)
	ai_bubble.set_font_level(font_level)
	if is_instance_valid(chat_panel):
		chat_panel.set_font_level(font_level)
		preload("res://ui/font_scale.gd").apply(chat_window,font_level)
	for window in [panel_window,settings_window]:
		var chrome: Node = window.find_child("WindowChrome",true,false)
		if chrome != null: preload("res://ui/font_scale.gd").apply(chrome,font_level)
	if is_instance_valid(data_dialog.confirmation):
		preload("res://ui/font_scale.gd").apply(data_dialog.confirmation, font_level)
	_fit_settings_font.call_deferred()

func _fit_settings_font() -> void:
	var width := maxi(360,ceili(settings.get_combined_minimum_size().x))
	settings_window.min_size = Vector2i(width,420)
	if settings_window.size.x < width:
		settings_window.size.x = width
	if settings_window.visible: _place_panel(settings_window)
	var plan_minimum := panel.get_combined_minimum_size().ceil()
	panel_window.min_size = Vector2i(maxi(360,int(plan_minimum.x)),maxi(420,int(plan_minimum.y)+preload("res://ui/window_chrome.gd").HEIGHT))
	panel_window.size = panel_window.size.max(panel_window.min_size)
	if panel_window.visible: _place_panel(panel_window)
	if is_instance_valid(chat_panel):
		chat_window.min_size = Vector2i(maxi(360,ceili(chat_panel.get_combined_minimum_size().x)),maxi(420,ceili(chat_panel.get_combined_minimum_size().y)+preload("res://ui/window_chrome.gd").HEIGHT))
		chat_window.size = chat_window.size.max(chat_window.min_size)
		if chat_window.visible: _place_panel(chat_window)

func _set_font_level(value: int) -> void:
	_apply_font_level(value)
	_save_preferences()

func _apply_appearance(style: Variant, color: Variant) -> void:
	var selected := Appearance.selection(style,color)
	var selected_style: String = selected[0]
	var selected_color: String = selected[1]
	if pet.actor.has_method("set_appearance"): pet.actor.set_appearance(selected_style,selected_color)
	settings.set_appearance(selected_style,selected_color)
	_update_geometry()
	preferences.set_value("pet","appearance_style",selected_style)
	preferences.set_value("pet","appearance_color",selected_color)

func _set_appearance(style: String, color: String) -> void:
	_apply_appearance(style,color)
	_save_preferences()

func _save_preferences() -> void:
	if not _preferences_ready:
		return
	if _preferences_blocked:
		return
	preferences.set_value("pet", "scale", pet.scale.x)
	preferences.set_value("ui", "font_level", font_level)
	preferences.set_value("pet","renderer_mode",renderer_mode)
	preferences.set_value("pet", "skin_id", selected_skin)
	preferences.set_value("pet", "position", get_window().position)
	preferences.set_value("companionship", "active_seconds", companionship.active_seconds)
	preferences.set_value("pet","icon_awareness",icon_awareness.enabled)
	preferences.set_value("pet", "companion_mode", companion_mode)
	preferences.set_value("pet", "reduced_motion", reduced_motion)
	preferences.set_value("pet", "performance", performance_mode)
	preferences.set_value("pet", "topmost", topmost_enabled)
	preferences.set_value("focus", "session", focus_session.snapshot())
	var save_error: Error = PreferencesStore.save_config(preferences_path, preferences)
	if save_error == OK:
		_active_since_save = 0.0
		_session_since_save = 0.0
		_preferences_error_reported = false
	elif not _preferences_error_reported:
		_preferences_error_reported = true
		panel.show_error("设置与陪伴时长未能保存，请检查数据目录权限。更改设置或退出时会重试。")

func _apply_growth() -> void:
	if is_instance_valid(pet.actor) and pet.actor.has_method("set_growth"):
		pet.actor.set_growth(companionship.progress())
		settings.appearance_preview.set_growth(companionship.progress())

func _ambient_enabled() -> bool:
	return companion_mode == "natural" and not reduced_motion and focus_session.state != "running"

func _apply_companion_options() -> void:
	_interrupt_ai()
	pet.reduced_motion = reduced_motion
	desktop.set_topmost(topmost_enabled)
	Engine.max_fps = (30 if performance_mode == "eco" else 60) if pet.is_active() else 10
	icon_awareness.set_active(pet.is_active() and _ambient_enabled())
	settings.set_companion_options(companion_mode, reduced_motion, performance_mode, topmost_enabled)
	if pet.actor.has_method("set_focus_mode"): pet.actor.set_focus_mode(focus_session.state == "running")
	if settings.appearance_preview.actor.has_method("set_focus_mode"): settings.appearance_preview.actor.set_focus_mode(focus_session.state == "running")
	scheduler.reset()

func _set_companion_mode(mode: String) -> void:
	companion_mode = "quiet" if mode == "quiet" else "natural"
	_apply_companion_options()
	_save_preferences()

func _set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_apply_companion_options()
	_save_preferences()

func _set_performance(mode: String) -> void:
	performance_mode = "eco" if mode == "eco" else "smooth"
	_apply_companion_options()
	_save_preferences()

func _set_topmost(enabled: bool) -> void:
	topmost_enabled = enabled
	_apply_companion_options()
	_save_preferences()

func _focus_action(action: String, minutes: int = 25) -> void:
	match action:
		"start": focus_session.start(minutes, "自由专注" if plan.data.current_id.is_empty() else current_goal_title)
		"pause": focus_session.pause()
		"resume": focus_session.resume()
		"cancel": focus_session.cancel()
	_last_session_tick = Time.get_ticks_msec()
	_apply_companion_options()
	_refresh_focus_ui()
	_save_preferences()

func _tick_companion() -> void:
	var now := Time.get_ticks_msec()
	var elapsed := maxf(0.0, float(now-_last_session_tick)/1000.0)
	_ambient_elapsed = elapsed
	_last_session_tick = now
	var prior_state: String = focus_session.state
	var previous_total: float = focus_session.total_focus_seconds
	var finished: bool = focus_session.advance(elapsed, elapsed <= 2.0)
	_session_since_save += focus_session.total_focus_seconds-previous_total
	if prior_state != focus_session.state:
		_apply_companion_options()
		_save_preferences()
	elif _session_since_save >= 60.0:
		_save_preferences()
	if finished: _queue_ai_event("focus_finished")
	if finished and pet.is_active() and companion_mode != "quiet" and not reduced_motion and not desktop.pointer_busy() and pet.current_action == &"idle":
		pet.play_action(&"look")
	var display_key := _focus_ui_key()
	if display_key != _focus_display_key: _refresh_focus_ui()

func _refresh_focus_ui() -> void:
	_focus_display_key = _focus_ui_key()
	panel.set_focus_state(focus_session.snapshot())
	settings.set_companionship_info(companionship.active_seconds, focus_session.total_focus_seconds, focus_session.completed_sessions)

func _focus_ui_key() -> String:
	return "%s:%d:%d" % [focus_session.state, ceili(focus_session.remaining_seconds), roundi(companionship.active_seconds/360.0)]

func _append_task(title: String) -> void:
	var candidate = Plan.new()
	candidate.data = plan.to_dict()
	if candidate.append_task(title) == OK:
		_save_candidate(candidate)
	else:
		panel.show_error("任务需为 1–200 字，清单最多 500 项。")

func _revise_current(goal: String, title: String) -> void:
	var candidate = Plan.new()
	candidate.data = plan.to_dict()
	if candidate.set_goal(goal) != OK or (not candidate.data.current_id.is_empty() and candidate.rename_current(title) != OK):
		panel.show_error("目标最多 300 字，任务需为 1–200 字。")
		return
	_save_candidate(candidate)

func _undo_complete() -> void:
	var candidate = Plan.new()
	candidate.data = plan.to_dict()
	if candidate.undo_current_complete() == OK: _save_candidate(candidate)

func _data_action(action: String) -> void:
	match action:
		"import":
			_pending_import.clear()
			data_dialog.choose_import()
		"template", "backup": data_dialog.choose_export(action)
		"restore", "restore_import":
			_pending_import.clear()
			var result: Dictionary = store.preview_checkpoint() if action == "restore_import" else store.preview_backup()
			if result.error == OK:
				_offer_import(result.plan, "导入前计划" if action == "restore_import" else "上次计划备份")
			else:
				_data_notice("没有可读取的有效计划备份。", true)
		"folder": OS.shell_open(ProjectSettings.globalize_path(store.path.get_base_dir()))
		"help":
			_show_plan()
			panel.show_notice("轻点看动作，按住拖动，右键或托盘找回入口。引光显示当前任务；完成和推进分别由你操作。隐藏角色不会结束专注，退出后需手动继续。")

func _import_file(path: String) -> void:
	_pending_import.clear()
	var result: Dictionary = PlanTransfer.read_file(path)
	if result.error != OK:
		_data_notice("无法导入：文件损坏、格式不支持或超出限制，现有计划未改动。", true)
		return
	_offer_import(result.plan, "清单分享" if result.kind == "template" else "计划与进度备份")

func _offer_import(candidate: Dictionary, kind: String) -> void:
	if storage_blocked:
		_data_notice("当前学习文件与备份损坏。请先打开数据目录保留并修复原文件；本次没有覆盖。", true)
		return
	_pending_import = candidate.duplicate(true)
	var completed := 0
	for task in candidate.tasks:
		if task.completed: completed += 1
	var summary := "%s\n目标：%s\n%d 项任务，%d 项已完成。\n确认后替换当前计划，并保存覆盖前检查点。" % [kind, candidate.goal, candidate.tasks.size(), completed]
	data_dialog.confirm_import(summary)

func _confirm_import() -> void:
	if _pending_import.is_empty() or storage_blocked: return
	var candidate: Dictionary = _pending_import.duplicate(true)
	_pending_import.clear()
	var error: Error = store.import_plan(candidate, plan.to_dict())
	if error != OK:
		_data_notice("导入保存失败，原计划与当前进度保持不变。", true)
		return
	plan.data = candidate
	_render()
	_data_notice("计划已导入，覆盖前状态保存在 plan.json.before-import。")

func _export_plan(kind: String, path: String) -> void:
	var normalized := ProjectSettings.globalize_path(path).simplify_path().to_lower()
	for protected_path in [store.path, preferences_path, ai_config_path, ai_memory_path]:
		for suffix in ["", ".bak", ".bak.tmp", ".tmp", ".before-import", ".before-import.tmp"]:
			if normalized == ProjectSettings.globalize_path(protected_path+suffix).simplify_path().to_lower():
				_data_notice("请选择其他文件名，不能覆盖正在使用的数据文件。", true)
				return
	var payload: Dictionary = PlanTransfer.encode_template(plan.to_dict()) if kind == "template" else PlanTransfer.encode_backup(plan.to_dict())
	var error: Error = PlanTransfer.write_file(path, payload)
	_data_notice("清单已导出。" if error == OK else "导出失败，请检查文件位置与写入权限。", error != OK)

func _data_notice(message: String, failed := false) -> void:
	_show_plan()
	if failed: panel.show_error(message)
	else: panel.show_notice(message)

func _quit() -> void:
	_interrupt_ai()
	_save_preferences()
	get_tree().quit()

func _exit_tree() -> void:
	ai_brain.cancel()
	instance_guard.release()

# AI decisions are optional; local actions and all user interactions remain usable offline.
func _load_ai_settings() -> void:
	var result: Dictionary = AIConfig.load_config(ai_config_path)
	ai_config = result.config
	ai_brain.configure(ai_config)
	settings.ai_panel.set_config(ai_config)
	if result.error not in [OK,ERR_FILE_NOT_FOUND]:
		settings.ai_panel.set_status("AI 配置无法读取，原文件已保留；AI 暂未启用。")
	elif _ai_configured():
		settings.ai_panel.set_status("AI 陪伴已启用，空闲时最多每两分钟决策一次。")
	else:
		settings.ai_panel.set_status("AI 陪伴未启用，继续使用本地动作。")

func _save_ai_settings(config: Dictionary) -> Error:
	if not AIConfig.validate(config):
		settings.ai_panel.set_status("请检查服务商、模型和密钥设置。")
		return ERR_INVALID_DATA
	var error: Error = AIConfig.save_config(ai_config_path,config)
	if error != OK:
		settings.ai_panel.set_status("AI 配置保存失败，请检查本机数据目录权限。")
		return error
	_interrupt_ai(true)
	ai_config = config.duplicate(true)
	ai_brain.configure(ai_config)
	_ai_fallback = false
	settings.ai_panel.set_config(ai_config)
	settings.ai_panel.set_status("已保存到本机。" + ("空闲时启用 AI 陪伴。" if _ai_configured() else "继续使用本地动作。"))
	return OK

func _test_ai_connection(config: Dictionary) -> void:
	if _save_ai_settings(config) != OK: return
	_ai_testing = true
	var actions: Array[StringName] = [&"idle"]
	var context := {"companion":selected_skin,"event":"connection_test","focus":false,"idle_band":"short","recent_actions":[]}
	var error: Error = ai_brain.request_decision(context,actions,true)
	if error != OK:
		_ai_testing = false
		settings.ai_panel.set_status("暂时无法测试，请检查配置并稍后再试。",ai_brain.busy)

func _ai_configured() -> bool:
	return bool(ai_config.get("enabled",false)) and AIConfig.validate(ai_config) and not str(ai_config.get("model","")).is_empty() and not str(ai_config.get("api_key","")).is_empty()

func _ai_surface_allowed() -> bool:
	return pet.is_active() and get_window().visible and get_window().mode != Window.MODE_MINIMIZED and not desktop.pointer_busy() and not desktop.context_menu_active() and not panel_window.visible and not settings_window.visible and (not is_instance_valid(chat_window) or not chat_window.visible)

func _ai_context_allowed() -> bool:
	return _ambient_enabled() and _ai_surface_allowed()

func _ai_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for action in [&"idle"] + scheduler.ACTIONS:
		if action != &"idle" and String(action) in _ai_recent_actions: continue
		if pet.skin != null and pet.skin.action_map.has(action): actions.append(action)
	return actions

func _ai_context() -> Dictionary:
	return {"companion":selected_skin,"focus":focus_session.state == "running","idle_band":"long" if _ai_idle_elapsed >= 120.0 else "short","event":_ai_event if not _ai_event.is_empty() else "idle","recent_actions":_ai_recent_actions.duplicate(),"preferences":ai_memory_data.preferences.duplicate(),"persona":_ai_persona()}

func _tick_ai(delta: float, ready: bool) -> void:
	if not _ai_context_allowed():
		if not _ai_manual_caption or not _ai_surface_allowed():
			ai_bubble.dismiss()
		elif ai_bubble.visible:
			ai_bubble.update_anchor(_ai_actor_rect(),desktop.usable_areas())
		if not _ai_testing and not _ai_chat_pending and ai_brain.busy:
			ai_brain.cancel()
			_ai_request_skin = ""
		_ai_idle_elapsed = 0.0
		return
	if ai_bubble.visible: ai_bubble.update_anchor(_ai_actor_rect(),desktop.usable_areas())
	if ai_brain.busy and not _ai_testing and not _ai_chat_pending and pet.current_action != &"idle":
		ai_brain.cancel()
		_ai_request_skin = ""
	if not ready or not _ai_configured() or _ai_testing or _ai_chat_pending: return
	if delta > 2.0 or delta < 0.0:
		_interrupt_ai(true)
		return
	_ai_idle_elapsed += delta
	if not _ai_event.is_empty() and Time.get_ticks_msec()-_ai_event_at > 60000: _ai_event = ""
	if ai_brain.busy or (_ai_idle_elapsed < 120.0 and _ai_event.is_empty()): return
	if Time.get_ticks_msec() < ai_brain.next_allowed_msec: return
	_ai_request_skin = selected_skin
	var error: Error = ai_brain.request_decision(_ai_context(),_ai_actions())
	if error == OK:
		_ai_idle_elapsed = 0.0
		_ai_event = ""
		_ai_fallback = false
	elif error != ERR_BUSY:
		_ai_fallback = true
		_ai_idle_elapsed = 0.0

func _on_ai_decision(decision: Dictionary) -> void:
	if decision.get("test",false):
		_ai_testing = false
		settings.ai_panel.set_status("连接测试成功，模型已返回有效结果。")
		return
	var skin := _ai_request_skin
	_ai_request_skin = ""
	if not _ai_configured() or skin != selected_skin or not _ai_context_allowed() or pet.current_action != &"idle": return
	var action := StringName(decision.get("action",&"idle"))
	if not _ai_actions().has(action): return
	pet.play_action(action)
	_ai_recent_actions.append(String(action))
	if _ai_recent_actions.size() > 3: _ai_recent_actions.pop_front()
	var text: String = str(decision.get("text","")).strip_edges().left(24)
	# A second key check prevents accidentally exposing credentials through a model echo.
	if not str(ai_config.get("api_key","")).is_empty() and str(ai_config.api_key) in text: text = ""
	if ai_config.get("bubbles",true) and not text.is_empty():
		_ai_manual_caption = false
		ai_bubble.show_message(text,_ai_actor_rect(),desktop.usable_areas(),font_level,topmost_enabled)

func _on_ai_failure(message: String) -> void:
	if _ai_chat_pending:
		_ai_chat_pending = false
		_ai_chat_pending_text = ""
		_ai_chat_pending_role = ""
		_refresh_ai_chat(false)
		chat_panel.set_status(message + "；输入已保留，可稍后重试。")
		chat_panel.set_retry(true)
	_ai_testing = false
	_ai_request_skin = ""
	_ai_fallback = true
	settings.ai_panel.set_status(message)

func _interrupt_ai(clear_event: bool = false) -> void:
	_ai_manual_caption = false
	ai_brain.cancel()
	if _ai_chat_pending:
		_ai_chat_pending = false
		_ai_chat_pending_text = ""
		_ai_chat_pending_role = ""
		if is_instance_valid(chat_panel):
			_refresh_ai_chat(false)
			chat_panel.set_status("已停止回复，输入已保留。")
	ai_bubble.dismiss()
	_ai_request_skin = ""
	_ai_testing = false
	_ai_idle_elapsed = 0.0
	if clear_event:
		_ai_event = ""
		_ai_recent_actions.clear()

func _queue_ai_event(event: String) -> void:
	_ai_event = event
	_ai_event_at = Time.get_ticks_msec()

func _ai_actor_rect() -> Rect2i:
	var points := PackedVector2Array()
	var geometry: Dictionary = pet.get_visual_geometry()
	for polygon in geometry.get("render_polygons",[]): points.append_array(polygon)
	var bounds: Rect2 = geometry.get("bounds",Rect2(Vector2.ZERO,Vector2(100,100)))
	if not points.is_empty():
		bounds = Rect2(points[0],Vector2.ZERO)
		for point in points: bounds = bounds.expand(point)
	return Rect2i(Vector2i(Vector2(get_window().position)+pet.position+bounds.position),Vector2i(bounds.size.ceil()).max(Vector2i.ONE))

func _load_ai_memory() -> void:
	var result: Dictionary = AIMemory.load_data(ai_memory_path)
	ai_memory_data = result.data
	_ai_memory_blocked = result.error != OK
	_refresh_ai_chat()
	if _ai_memory_blocked:
		chat_panel.set_status("记忆文件无法读取，原文件已保留；请先备份并移走原文件再保存新记忆。")

func _ai_persona() -> String:
	return ai_memory_data.personas.get(selected_skin,AIMemory.default_persona(selected_skin))

func _ai_name() -> String:
	for entry in SkinCatalog.entries():
		if entry.id == selected_skin: return entry.name
	return "伙伴"

func _refresh_ai_chat(update_memories: bool = true) -> void:
	if not is_instance_valid(chat_panel): return
	chat_panel.set_conversation(ai_memory_data.histories.get(selected_skin,[]),_ai_name())
	if update_memories:
		var preferences: Array[String] = []
		preferences.assign(ai_memory_data.preferences)
		chat_panel.set_memories(preferences,_ai_persona())

func _show_ai_chat() -> void:
	_interrupt_ai()
	desktop.show_pet()
	panel_window.hide()
	settings_window.hide()
	_refresh_ai_chat()
	_place_panel(chat_window)
	chat_window.show()
	chat_window.grab_focus()
	chat_panel.message_input.grab_focus()
	if str(ai_config.api_key).is_empty() or str(ai_config.model).is_empty():
		chat_panel.set_status("先在设置 → 陪伴中选择服务商和模型，并填写 API Key；聊天不要求开启自主陪伴。")

func _send_ai_chat(text: String) -> void:
	if text.strip_edges().is_empty() or text.length() > 1000 or _ai_chat_pending: return
	if _ai_has_key(text):
		chat_panel.set_status("请勿在聊天中发送 API Key。")
		return
	if str(ai_config.api_key).is_empty() or str(ai_config.model).is_empty():
		chat_panel.set_status("请先在设置 → 陪伴中选择服务商和模型，并填写 API Key。")
		return
	_interrupt_ai()
	_ai_chat_pending_text = text.strip_edges()
	_ai_chat_pending_role = selected_skin
	_ai_chat_pending = true
	var messages: Array = AIMemory.recent_messages(ai_memory_data,selected_skin)
	messages.append({"role":"user","content":_ai_chat_pending_text})
	var preferences: Array[String] = []
	preferences.assign(ai_memory_data.preferences)
	var preview: Array = ai_memory_data.histories.get(selected_skin,[]).duplicate(true)
	preview.append({"role":"user","content":_ai_chat_pending_text})
	chat_panel.set_conversation(preview,_ai_name())
	var error: Error = ai_brain.request_chat(messages,preferences,_ai_persona(),selected_skin)
	if error != OK and _ai_chat_pending:
		_ai_chat_pending = false
		_ai_chat_pending_text = ""
		_ai_chat_pending_role = ""
		_refresh_ai_chat(false)
		chat_panel.set_status("暂时无法发送，请检查配置并稍后再试。",ai_brain.busy)
		chat_panel.set_retry(true)

func _on_ai_chat_ready(reply: String, memories: Array[String]) -> void:
	if not _ai_chat_pending or _ai_chat_pending_role != selected_skin or not chat_window.visible: return
	var user_text := _ai_chat_pending_text
	_ai_chat_pending = false
	_ai_chat_pending_text = ""
	_ai_chat_pending_role = ""
	if _ai_has_key(reply):
		chat_panel.set_status("回复包含敏感配置，未显示或保存。")
		return
	var safe_memories: Array[String] = []
	for value in memories:
		if not _ai_has_key(value): safe_memories.append(value)
	var candidate: Dictionary = AIMemory.append_exchange(ai_memory_data,selected_skin,user_text,reply,safe_memories)
	var error := _persist_ai_memory(candidate)
	_refresh_ai_chat()
	if chat_panel.message_input.text.strip_edges() == user_text: chat_panel.message_input.clear()
	chat_panel.set_status(("已回复；明确的喜好已记下，可在记忆页修改。" if not safe_memories.is_empty() else "已回复。") if error == OK else "已回复，但本机保存失败；本次记忆暂仅在运行期间保留。")

func _cancel_ai_chat() -> void:
	_interrupt_ai()

func _persist_ai_memory(candidate: Dictionary) -> Error:
	# Never overwrite an unreadable private file automatically.
	if _ai_memory_blocked and FileAccess.file_exists(ai_memory_path):
		ai_memory_data = candidate
		return ERR_FILE_CORRUPT
	var error: Error = AIMemory.save_data(ai_memory_path,candidate)
	ai_memory_data = candidate
	if error == OK: _ai_memory_blocked = false
	return error

func _save_ai_preferences(values: Array[String]) -> void:
	for value in values:
		if _ai_has_key(value):
			chat_panel.set_status("请勿将 API Key 保存在喜好中。")
			return
	_interrupt_ai()
	var error := _persist_ai_memory(AIMemory.set_preferences(ai_memory_data,values))
	if error == OK:
		var saved: Array[String] = []
		saved.assign(ai_memory_data.preferences)
		chat_panel.accept_preferences(saved)
	_refresh_ai_chat()
	chat_panel.set_status("长期喜好已更新；如需移除历史中的内容，请同时清空对话。" if error == OK else "记忆保存失败，请检查私有文件与目录权限。")

func _save_ai_persona(value: String) -> void:
	if _ai_has_key(value):
		chat_panel.set_status("请勿将 API Key 保存在伙伴性格中。")
		return
	_interrupt_ai()
	var error := _persist_ai_memory(AIMemory.set_persona(ai_memory_data,selected_skin,value))
	if error == OK: chat_panel.accept_persona(_ai_persona())
	_refresh_ai_chat()
	chat_panel.set_status("伙伴性格已保存。" if error == OK else "伙伴性格保存失败，请检查私有文件与目录权限。")

func _clear_ai_chat_history() -> void:
	_interrupt_ai()
	var error := _persist_ai_memory(AIMemory.clear_history(ai_memory_data,selected_skin))
	_refresh_ai_chat()
	chat_panel.set_status("当前伙伴的对话已清空；喜好与性格已保留。" if error == OK else "清空记录无法保存，请检查私有文件与目录权限。")

func _ai_has_key(text: String) -> bool:
	return not str(ai_config.get("api_key","")).is_empty() and str(ai_config.api_key) in text
