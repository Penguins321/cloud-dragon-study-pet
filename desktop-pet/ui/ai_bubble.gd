extends Window

signal activated

const FontScale = preload("res://ui/font_scale.gd")
const Geometry = preload("res://desktop/window_geometry.gd")
const LIFETIME := 6.0
const PADDING := 10
const CLOSE_WIDTH := 24

var message_label := Label.new()
var close_button := Button.new()
var _panel := Panel.new()
var _anchor := Rect2i()
var _areas: Array[Rect2i] = []
var _remaining := 0.0

func _init() -> void:
	visible = false
	borderless = true
	transparent = true
	transparent_bg = true
	unfocusable = true
	unresizable = true
	force_native = true
	wrap_controls = false
	set_process(false)

func _ready() -> void:
	set_process(false)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.97, 0.93, 0.96)
	style.border_color = Color(0.64, 0.77, 0.67, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	message_label.name = "Message"
	message_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	message_label.max_lines_visible = 4
	message_label.clip_text = true
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.add_theme_color_override("font_color", Color("284f40"))
	_panel.add_child(message_label)
	close_button.name = "Close"
	close_button.text = "×"
	close_button.tooltip_text = "关闭"
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_color_override("font_color", Color("426858"))
	close_button.pressed.connect(dismiss)
	_panel.add_child(close_button)
	window_input.connect(_on_window_input)
	close_requested.connect(dismiss)
	set_font_level(0)

func show_message(text: String, anchor: Rect2i, usable_areas: Array[Rect2i], level: int = 0, on_top: bool = true) -> void:
	# A Label displays markup literally. Normalize control characters to one line
	# before wrapping so an API response cannot force extra empty lines.
	var clean := ""
	for character in text:
		clean += character if character.unicode_at(0) >= 32 else " "
	clean = clean.strip_edges().left(72)
	if clean.is_empty():
		dismiss()
		return
	message_label.text = clean
	_anchor = anchor
	_areas = usable_areas.duplicate()
	always_on_top = on_top
	set_font_level(level)
	_remaining = clampf(clean.length()*0.22,LIFETIME,18.0)
	show()
	# Native creation may choose a default monitor; restore the supplied anchor.
	_layout_bubble()
	set_process(true)

func update_anchor(anchor: Rect2i, areas: Array[Rect2i]) -> void:
	_anchor = anchor
	_areas = areas.duplicate()
	if visible:
		_layout_bubble()

func dismiss() -> void:
	_remaining = 0.0
	hide()
	set_process(false)

func set_font_level(level: int) -> void:
	var pixels := roundi(16 * FontScale.FACTORS[FontScale.valid_level(level)])
	message_label.add_theme_font_size_override("font_size", pixels)
	close_button.add_theme_font_size_override("font_size", pixels)
	if is_node_ready():
		_layout_bubble()

func advance(delta: float) -> void:
	if not visible:
		return
	_remaining -= maxf(delta, 0.0)
	if _remaining <= 0.0:
		dismiss()

func _process(delta: float) -> void:
	advance(delta)

func _on_window_input(event: InputEvent) -> void:
	if not visible or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		dismiss()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if not close_button.get_rect().has_point(event.position):
			activated.emit()
		dismiss()

func _layout_bubble() -> void:
	var area := _target_area()
	var font := message_label.get_theme_font("font")
	var pixels := message_label.get_theme_font_size("font_size")
	var widest := 1.0
	for character in message_label.text:
		widest = maxf(widest, font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x)
	# Eighteen glyphs per line leave room for a small conversational paragraph.
	var natural_width := font.get_string_size(message_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
	var text_width := ceili(minf(natural_width, widest * 18.0)) + 2
	var available_width := maxi(1, mini(text_width, area.size.x - PADDING * 2 - CLOSE_WIDTH))
	var lines := maxi(1,ceili(natural_width / available_width))
	message_label.max_lines_visible = maxi(4,lines)
	var desired := Vector2i(text_width + PADDING * 2 + CLOSE_WIDTH, ceili(font.get_height(pixels) * lines) + (lines - 1) * 3 + PADDING * 2)
	size = Vector2i(mini(desired.x, area.size.x), mini(desired.y, area.size.y))
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(size)
	message_label.position = Vector2(PADDING, PADDING)
	message_label.size = Vector2(maxi(1, size.x - PADDING * 2 - CLOSE_WIDTH), maxi(1, size.y - PADDING * 2))
	close_button.position = Vector2(maxi(0, size.x - CLOSE_WIDTH - 4), 4)
	close_button.size = Vector2(CLOSE_WIDTH, CLOSE_WIDTH)
	var above := Vector2i(_anchor.get_center().x - size.x / 2, _anchor.position.y - size.y - 10)
	if above.y < area.position.y:
		above.y = _anchor.end.y + 10
	var target: Array[Rect2i] = [area]
	position = Geometry.restore_position(above, size, target)
	# Windows also uses this polygon as the native visual region. Keep it local
	# to this separate bubble Window, never combine it with the pet's outline.
	var outline := PackedVector2Array()
	var radius := minf(18.0, minf(size.x, size.y) / 2.0)
	var centers := [Vector2(radius, radius), Vector2(size.x - radius, radius), Vector2(size.x - radius, size.y - radius), Vector2(radius, size.y - radius)]
	for corner in range(4):
		for step in range(9):
			var angle := PI + corner * PI / 2.0 + step * PI / 16.0
			outline.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	mouse_passthrough_polygon = outline

func _target_area() -> Rect2i:
	var best := Rect2i(_anchor.position - Vector2i(600, 600), Vector2i(1200, 1200))
	var best_overlap := -1
	for area in _areas:
		if area.size.x <= 0 or area.size.y <= 0:
			continue
		var overlap := _anchor.intersection(area).get_area()
		if overlap > best_overlap:
			best = area
			best_overlap = overlap
	return best
