extends Button

var symbol := "todo"

func _init() -> void:
	custom_minimum_size = Vector2(68, 60)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	var center := size / 2.0
	var ink := Color("252526")
	if is_hovered() or has_focus():
		draw_circle(center, 24, Color(0, 0, 0, 0.045), true, -1, true)
	if symbol == "todo":
		var outline := PackedVector2Array([Vector2(1,-11),Vector2(-9,-11),Vector2(-12,-8),Vector2(-12,10),Vector2(-9,13),Vector2(9,13),Vector2(12,10),Vector2(12,2)])
		for i in outline.size(): outline[i] += center
		draw_polyline(outline, ink, 2.4, true)
		var pencil := PackedVector2Array([Vector2(-4,5),Vector2(-2,-1),Vector2(10,-13),Vector2(15,-8),Vector2(3,4),Vector2(-4,5)])
		for i in pencil.size(): pencil[i] += center
		draw_polyline(pencil, ink, 2.4, true)
	else:
		for i in 3:
			var x := center.x + (i - 1) * 10
			draw_line(Vector2(x, center.y-12), Vector2(x, center.y+12), ink, 2.3, true)
			var y := center.y + (-5 if i != 1 else 6)
			draw_circle(Vector2(x,y), 4, ink, true,-1,true)
			draw_circle(Vector2(x,y), 2, Color.WHITE,true,-1,true)
