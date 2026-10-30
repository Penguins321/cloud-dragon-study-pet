extends SceneTree
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for frame in 6:
		await process_frame
		await RenderingServer.frame_post_draw
func capture(window: Window, name: String) -> void:
	var path := "res://docs/screenshots/ai-companion/"+name+".png"
	var image := window.get_texture().get_image()
	assert(not image.is_empty())
	assert(image.save_png(path) == OK)
func run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/ai-companion")
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app._set_skin("corgi")
	app.panel_window.hide()
	app.settings_window.hide()
	app._apply_font_level(0)
	app.desktop.last_click_double = false
	app._handle_pet_click()
	await settle()
	capture(app.ai_bubble,"short-invitation")
	app._show_ai_chat()
	var preferences: Array[String] = ["我喜欢安静一点的陪伴"]
	app.ai_memory_data = app.AIMemory.append_exchange(app.AIMemory.defaults(),"corgi","我喜欢安静一点的陪伴，不用总催我。","记住啦。我会安静陪着你，需要我时点一下就好。",preferences)
	app._refresh_ai_chat()
	app.chat_panel.message_input.text = "今天有点累，陪我聊聊吧。"
	app.chat_panel.set_status("演示对话；尚未发起真实 API 请求。")
	await settle()
	capture(app.chat_window,"chat")
	app.chat_panel.category_tabs.current_tab = 1
	await settle()
	capture(app.chat_window,"memory")
	app._set_font_level(3)
	app.chat_panel.category_tabs.current_tab = 0
	await settle()
	capture(app.chat_window,"chat-large-font")
	app._set_font_level(0)
	app._show_settings()
	app.settings.category_tabs.current_tab = 1
	await settle()
	capture(app.settings_window,"settings")
	var companion_scroll: ScrollContainer = app.settings.category_tabs.get_child(1)
	companion_scroll.scroll_vertical += roundi(app.settings.ai_panel.model_input.global_position.y-companion_scroll.global_position.y-40)
	await settle()
	capture(app.settings_window,"models")
	app.free()
	await process_frame
	print("AI COMPANION GPU PREVIEWS: captured invitation, chat, memory, fonts and settings")
	quit()
