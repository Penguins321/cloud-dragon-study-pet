extends Button

func _init() -> void:
	toggle_mode = true
	custom_minimum_size = Vector2(40, 28)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	toggled.connect(func(_value: bool): queue_redraw())

func _draw() -> void:
	var center := size / 2.0
	var color := Color("007aff") if button_pressed else Color("d4d4d8")
	if disabled: color = Color("e7e7e9")
	draw_line(center - Vector2(8, 0), center + Vector2(8, 0), color, 22, true)
	draw_circle(center - Vector2(8, 0), 11, color, true, -1, true)
	draw_circle(center + Vector2(8, 0), 11, color, true, -1, true)
	draw_circle(center + Vector2(8 if button_pressed else -8, 0), 9, Color.WHITE, true, -1, true)
	if has_focus(): draw_arc(center, 15, 0, TAU, 40, Color("a9cfff"), 1, true)
