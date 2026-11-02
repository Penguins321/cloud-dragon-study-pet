extends Control

var elapsed := 2.0
var pieces: Array[Dictionary] = []
var toast: Label
var burst_count := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast = Label.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", Color("28705a"))
	toast.add_theme_font_size_override("font_size", 18)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("f1f8f4")
	background.set_corner_radius_all(12)
	toast.add_theme_stylebox_override("normal", background)
	add_child(toast)
	toast.hide()

func burst(origin: Vector2, all_done: bool) -> void:
	burst_count += 1
	elapsed = 0.0
	pieces.clear()
	origin = size / 2.0
	var colors := [Color("8cc8f0"), Color("a8dbc9"), Color("f4d58e"), Color("e9b6c6"), Color("bcbbea")]
	for index in 64:
		pieces.append({"origin": origin, "velocity": Vector2(randf_range(-210, 210), randf_range(-330, -100)), "color": colors[index % colors.size()], "angle": randf_range(-PI, PI), "spin": randf_range(-6, 6), "width": randf_range(3, 6)})
	toast.text = "✓ 全部完成，今天辛苦了" if all_done else "✓ 又完成一件事"
	toast.show()
	queue_redraw()

func _process(delta: float) -> void:
	if elapsed >= 2.0: return
	if not get_window().visible:
		elapsed = 2.0
	else: elapsed += delta
	toast.position = Vector2(16, size.y - 58)
	toast.size = Vector2(size.x - 32, 34)
	toast.modulate.a = 1.0 - smoothstep(1.3, 2.0, elapsed)
	if elapsed >= 2.0:
		pieces.clear()
		toast.hide()
	queue_redraw()

func _draw() -> void:
	if elapsed >= 2.0: return
	for piece in pieces:
		var position: Vector2 = piece.origin + piece.velocity * elapsed + Vector2(0, 185 * elapsed * elapsed)
		var color: Color = piece.color
		color.a = (1.0 - smoothstep(0.8, 1.8, elapsed)) * 0.85
		draw_set_transform(position, piece.angle + piece.spin * elapsed)
		draw_rect(Rect2(-piece.width/2, -4, piece.width, 8), color)
	draw_set_transform(Vector2.ZERO)
