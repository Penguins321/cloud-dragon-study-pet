extends Node2D

# Breath is a small visual response. Goals and dialogue live in their own UI.
var origin := Vector2.ZERO
var display_scale := 1.0
var elapsed := 0.0
var _glow := GradientTexture2D.new()

func _ready() -> void:
	visible = false
	z_index = 10
	_glow.width = 64
	_glow.height = 64
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_glow.gradient = Gradient.new()
	_glow.gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	_glow.gradient.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])

func set_frame(anchor: Vector2, size: float, time: float, _title: String) -> void:
	visible = true
	origin = anchor
	display_scale = maxf(size, 0.01)
	elapsed = time
	queue_redraw()

func stage() -> int:
	if elapsed < 0.15: return 0
	if elapsed < 0.5: return 1
	if elapsed < 1.9: return 2
	return 3

func contains_point(_point: Vector2) -> bool:
	return false

func _alpha() -> float:
	return smoothstep(0.15, 0.5, elapsed) * (1.0 - smoothstep(1.1, 1.9, elapsed))

func _particle(index: int) -> Vector2:
	var progress := clampf((elapsed - 0.25) / 1.65, 0.0, 1.0)
	return origin + Vector2(-8 - progress * (20 + index * 5), -4 + sin(index * 1.7) * 13 - progress * 24) * display_scale

func get_regions() -> Array[PackedVector2Array]:
	var regions: Array[PackedVector2Array] = []
	if not visible or elapsed < 0.15 or elapsed >= 1.9:
		return regions
	# Main refreshes native geometry on stage changes. Cover each particle's
	# complete short path so its soft texture stays visible between those updates.
	for index in range(5):
		var radius := (14.0 if index == 0 else 6.0) * display_scale
		var start := origin if index == 0 else origin + Vector2(-8, -4 + sin((index - 1) * 1.7) * 13) * display_scale
		var end := origin if index == 0 else start + Vector2(-20 - (index - 1) * 5, -24) * display_scale
		var rect := Rect2(end - Vector2.ONE * radius, start - end + Vector2.ONE * radius * 2)
		regions.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	return regions

func _draw() -> void:
	var alpha := _alpha()
	if not visible or alpha <= 0.001:
		return
	var radius := 14.0 * display_scale
	draw_texture_rect(_glow, Rect2(origin - Vector2.ONE * radius, Vector2.ONE * radius * 2), false, Color(0.86, 1.0, 0.81, alpha * 0.28))
	for index in range(4):
		var point := _particle(index)
		var amount := alpha * (0.65 + 0.35 * sin(elapsed * 3.0 + index))
		var half := 6.0 * display_scale
		draw_texture_rect(_glow, Rect2(point - Vector2.ONE * half, Vector2.ONE * half * 2), false, Color(0.96, 0.94, 0.68, amount * 0.3))
		draw_circle(point, 0.85 * display_scale, Color(1.0, 0.97, 0.78, amount * 0.65))
