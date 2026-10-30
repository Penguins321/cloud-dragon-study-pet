extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_standalone")

func _standalone() -> void:
	await run(self, func(ok: bool, message: String):
		if not ok:
			failures += 1
			printerr("FAIL: ", message))
	print("AI BUBBLE failures: ", failures)
	quit(0 if failures == 0 else 1)

static func run(tree: SceneTree, check: Callable) -> void:
	var script = load("res://ui/ai_bubble.gd")
	check.call(script != null, "AI bubble implementation exists")
	if script == null:
		return
	var bubble = script.new()
	tree.root.add_child(bubble)
	var root_size := tree.root.size
	var areas: Array[Rect2i] = [Rect2i(-1920, -100, 1920, 1080), Rect2i(0, 0, 1920, 1040)]
	var anchor := Rect2i(-1200, 500, 180, 180)
	check.call(not bubble.visible and not bubble.is_processing(), "bubble starts hidden without processing")
	check.call(bubble.borderless and bubble.transparent and bubble.unfocusable and bubble.unresizable, "bubble has independent nonfocusable transparent chrome")
	bubble.show_message("你好，今天也慢慢来。", anchor, areas)
	check.call(bubble.visible, "message shows bubble")
	check.call(bubble.position.y + bubble.size.y <= anchor.position.y, "bubble prefers above anchor")
	check.call(areas[0].encloses(Rect2i(bubble.position, bubble.size)), "negative monitor placement stays in its usable bounds")
	bubble.advance(5.0)
	check.call(bubble.visible, "bubble remains visible before six seconds")
	bubble.show_message("替换", anchor, areas, 0, false)
	check.call(bubble.message_label.text == "替换" and not bubble.always_on_top, "new message replaces text and respects topmost toggle")
	bubble.advance(5.0)
	check.call(bubble.visible, "replacement restarts lifetime")
	bubble.advance(1.1)
	check.call(not bubble.visible and not bubble.is_processing(), "six seconds dismisses and stops processing")
	var long_text := "话".repeat(80)
	var previous_width := 0
	for level in range(4):
		bubble.show_message(long_text, anchor, areas, level)
		await tree.process_frame
		check.call(bubble.message_label is Label and bubble.message_label.text.length() == 72, "plain label clamps message to 72 characters")
		check.call(bubble.message_label.max_lines_visible >= 4 and bubble.message_label.get_line_count() <= 4, "72 CJK characters fit four lines at font level %d" % level)
		check.call(bubble.size.x >= previous_width, "larger font expands bubble width")
		check.call(bubble.message_label.get_theme_font_size("font_size") == roundi(16 * preload("res://ui/font_scale.gd").FACTORS[level]), "bubble follows font scale")
		previous_width = bubble.size.x
	bubble.show_message("[b]纯文字[/b]", anchor, areas)
	check.call(bubble.message_label.text == "[b]纯文字[/b]", "markup remains literal text")
	var activations: Array[int] = []
	if bubble.has_signal("activated"):
		bubble.activated.connect(func(): activations.append(1))
	else:
		check.call(false, "caption exposes chat activation signal")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(16, 16)
	bubble.window_input.emit(click)
	check.call(not bubble.visible and activations.size() == 1, "caption body opens chat once and dismisses")
	bubble.window_input.emit(click)
	check.call(activations.size() == 1, "hidden caption cannot activate again")
	bubble.show_message("关闭", anchor, areas)
	click.position = bubble.close_button.get_rect().get_center()
	bubble.window_input.emit(click)
	bubble.close_button.pressed.emit()
	check.call(not bubble.visible and activations.size() == 1, "close button dismisses without opening chat")
	bubble.show_message("稍后再聊", anchor, areas)
	click.button_index = MOUSE_BUTTON_RIGHT
	bubble.window_input.emit(click)
	check.call(not bubble.visible and activations.size() == 1, "right click only dismisses")
	bubble.show_message("你好", anchor, areas)
	var short_height: int = bubble.size.y
	bubble.show_message(long_text, anchor, areas)
	check.call(bubble.size.y > short_height, "caption uses one or two lines of height to match its sentence")
	bubble.show_message("   \n\t", anchor, areas)
	check.call(not bubble.visible, "blank message dismisses")
	anchor = Rect2i(-1500, -95, 100, 100)
	bubble.show_message("下面", anchor, areas)
	check.call(bubble.position.y >= anchor.end.y, "top edge uses below-anchor placement")
	anchor.position = Vector2i(-1900, 800)
	bubble.update_anchor(anchor, areas)
	check.call(areas[0].encloses(Rect2i(bubble.position, bubble.size)), "following anchor reclamps at screen edges")
	var narrow: Array[Rect2i] = [Rect2i(-200, 10, 120, 150)]
	bubble.show_message(long_text, Rect2i(-180, 80, 30, 30), narrow, 3)
	await tree.process_frame
	check.call(narrow[0].encloses(Rect2i(bubble.position, bubble.size)), "narrow monitor constrains bubble dimensions")
	check.call(tree.root.size == root_size, "bubble never resizes root window")
	bubble.free()
	await tree.process_frame
