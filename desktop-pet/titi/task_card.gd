extends HBoxContainer

var completed := false

func _draw() -> void:
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("f8f9fb") if completed else Color("f5f6f8")
	surface.border_color = Color("e8eaee")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(14)
	draw_style_box(surface, Rect2(Vector2.ZERO, size))
