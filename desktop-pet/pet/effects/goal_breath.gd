extends Node2D

# Pure presentation: main supplies the current task. This effect does not edit plans.
var goal_label := Label.new()
var caption := Label.new()
var goal_rect := Rect2()
var origin := Vector2.ZERO
var display_scale := 1.0
var elapsed := 0.0
var _mist := GradientTexture2D.new()

func _ready() -> void:
	visible = false
	z_index = 10
	material = ShaderMaterial.new()
	material.shader = preload("res://pet/effects/cloud_mist.gdshader")
	_mist.width = 128
	_mist.height = 128
	_mist.fill = GradientTexture2D.FILL_RADIAL
	_mist.fill_from = Vector2(0.5,0.5)
	_mist.fill_to = Vector2(1.0,0.5)
	_mist.gradient = Gradient.new()
	_mist.gradient.offsets = PackedFloat32Array([0.0,0.55,1.0])
	_mist.gradient.colors = PackedColorArray([Color(1,1,1,0.95),Color(1,1,1,0.55),Color(1,1,1,0)])
	for label in [caption,goal_label]:
		label.theme = preload("res://ui/study_theme.tres")
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color",Color("244d48"))
		label.add_theme_color_override("font_outline_color",Color(0.94,1.0,0.98,0.8))
		label.add_theme_constant_override("outline_size",1)
		add_child(label)
	caption.text = "今日目标"
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.max_lines_visible = 2
	goal_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func set_frame(mouth: Vector2, size: float, time: float, title: String) -> void:
	visible = true
	origin = mouth
	display_scale = size
	elapsed = time
	material.set_shader_parameter("mist_time",time)
	var center := mouth + Vector2(-110,-110)*size
	goal_rect = Rect2(center-Vector2(112,64)*size,Vector2(224,128)*size)
	var padding := maxf(6.0,12.0*size)
	var caption_size := maxi(11,roundi(14.0*size))
	caption.add_theme_font_size_override("font_size",caption_size)
	caption.position = (goal_rect.position+Vector2(padding,padding)).floor()
	caption.size = Vector2(goal_rect.size.x-padding*2,caption_size+5)
	goal_label.add_theme_font_size_override("font_size",maxi(14,roundi(18.0*size)))
	goal_label.position = caption.position+Vector2(0,caption_size+5)
	goal_label.size = Vector2(goal_rect.size.x-padding*2,goal_rect.size.y-padding*2-caption_size-5)
	goal_label.text = title
	var text_alpha := smoothstep(1.0,1.25,time)*(1.0-smoothstep(5.1,5.6,time))
	for label in [caption,goal_label]:
		label.visible = text_alpha > 0.001
		label.modulate.a = text_alpha
	queue_redraw()

func stage() -> int:
	if elapsed < 0.35: return 0
	if elapsed < 0.75: return 1
	if elapsed < 5.1: return 2
	return 3

func contains_point(point: Vector2) -> bool:
	return visible and elapsed >= 0.75 and goal_rect.has_point(point)

func get_regions() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not visible or elapsed < 0.35:
		return result
	var center := goal_rect.get_center()
	var normal := Vector2(1,-1).normalized()*38.0*display_scale
	var direction := (center-origin).normalized()*26.0*display_scale
	result.append(PackedVector2Array([origin-direction+normal,center+direction+normal,center+direction-normal,origin-direction-normal]))
	if elapsed >= 0.75:
		# Native integer rounding must be conservative for the soft cloud and text.
		var rectangle := goal_rect.grow(2.0)
		result.append(PackedVector2Array([rectangle.position.floor(),Vector2(ceilf(rectangle.end.x),floorf(rectangle.position.y)),rectangle.end.ceil(),Vector2(floorf(rectangle.position.x),ceilf(rectangle.end.y))]))
	return result

func _draw() -> void:
	if not visible:
		return
	var scale_value := display_scale
	var center := goal_rect.get_center()
	var normal := Vector2(1,-1).normalized()
	var stream := smoothstep(0.35,0.5,elapsed)*(1.0-smoothstep(1.05,1.6,elapsed))
	if stream > 0.001:
		# Successive vapor parcels accelerate away from the lips, broaden and curl.
		# A deterministic clock keeps hiding, previews and animation seeking in sync.
		for parcel in range(26):
			var age := elapsed-0.35-parcel*0.035
			if age < 0.0 or age > 1.25: continue
			var t := clampf(age/0.85,0.0,1.0)
			var drift := sin(age*5.0+parcel*1.7)*(2.0+10.0*t)*scale_value
			var position_value := origin.lerp(center,t)+normal*drift
			var diameter := (7.0+34.0*sqrt(t))*scale_value
			var parcel_size := Vector2(diameter,diameter*0.85)
			var alpha := smoothstep(0.0,0.08,age)*(1.0-smoothstep(0.9,1.25,age))*stream
			draw_texture_rect(_mist,Rect2(position_value-parcel_size*0.5,parcel_size),false,Color(0.91,0.98,0.93,0.65*alpha))
	var cloud := smoothstep(0.75,1.05,elapsed)*(1.0-smoothstep(5.1,5.6,elapsed))
	if cloud <= 0.001:
		return
	draw_texture_rect(_mist,goal_rect,false,Color(0.82,0.93,0.87,cloud))
	for puff in range(9):
		var offset := Vector2(sin(puff*2.3+elapsed*0.3)*0.22,cos(puff*1.9+elapsed*0.25)*0.18)*goal_rect.size
		var size := goal_rect.size*Vector2(0.55,0.64)
		draw_texture_rect(_mist,Rect2(center+offset-size*0.5,size),false,Color(0.97,0.99,0.94,0.65*cloud))
