extends "res://pet/effects/goal_breath.gd"

# Share real goal text/layout with the old effect, but no vapor or noise shader.
func _ready() -> void:
	super._ready()
	material = null
	for label in [caption,goal_label]:
		label.add_theme_color_override("font_color",Color("375b55"))
		label.add_theme_color_override("font_outline_color",Color(1,0.99,0.9,0.6))

func _sheet_alpha() -> float:
	return smoothstep(0.62,1.05,elapsed)*(1.0-smoothstep(5.1,5.6,elapsed))

func contains_point(point: Vector2) -> bool:
	return visible and elapsed >= 1.05 and _sheet_alpha() > 0.1 and goal_rect.has_point(point)

func _curve(t: float) -> Vector2:
	var end := goal_rect.end-Vector2(24,12)*display_scale
	var a := origin+Vector2(0,-40)*display_scale
	var b := end+Vector2(28,32)*display_scale
	var u := 1.0-t
	return origin*u*u*u+a*3*u*u*t+b*3*u*t*t+end*t*t*t

func _flow_alpha() -> float:
	return smoothstep(0.25,0.65,elapsed)*(1.0-smoothstep(1.2,1.8,elapsed))+smoothstep(5.0,5.2,elapsed)*(1.0-smoothstep(5.4,5.6,elapsed))

func get_regions() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not visible or elapsed >= 5.6: return result
	if _sheet_alpha() > 0.001:
		var rect := goal_rect.grow(8*display_scale)
		result.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	if _flow_alpha() > 0.001:
		for index in range(12):
			var rect := Rect2(_curve(index/11.0)-Vector2.ONE*13*display_scale,Vector2.ONE*26*display_scale)
			result.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	return result

func _draw() -> void:
	if not visible or elapsed >= 5.6: return
	var alpha := _sheet_alpha()
	var flow := _flow_alpha()
	var size := display_scale
	if flow > 0.001:
		var points := PackedVector2Array()
		var reveal := smoothstep(0.25,0.75,elapsed)
		for index in range(41): points.append(_curve(index/40.0*reveal))
		draw_polyline(points,Color(0.96,0.83,0.49,flow*0.10),6*size,true)
		draw_polyline(points,Color(1,0.92,0.65,flow*0.6),1.6*size,true)
		draw_polyline(points,Color(1,1,0.91,flow*0.8),0.65*size,true)
		for index in range(9):
			var t := fposmod(elapsed*0.8-index*0.11,1.0)
			if elapsed > 5.0: t = 1.0-t
			var point := _curve(t*reveal)
			var amount := sin(t*PI)*flow
			draw_texture_rect(_mist,Rect2(point-Vector2.ONE*7*size,Vector2.ONE*14*size),false,Color(1,0.87,0.48,amount*0.38))
			draw_circle(point,1.1*size,Color(1,0.97,0.78,amount))
	if alpha <= 0.001: return
	var open := smoothstep(0.62,1.05,elapsed)
	var center := goal_rect.get_center()
	var half := goal_rect.size*Vector2(0.5,0.5*open)
	var cut := 12*size
	var paper := PackedVector2Array([center+Vector2(-half.x+cut,-half.y),center+Vector2(half.x-cut,-half.y),center+Vector2(half.x,-half.y+cut*open),center+Vector2(half.x,half.y-cut*open),center+Vector2(half.x-cut,half.y),center+Vector2(-half.x+cut,half.y),center+Vector2(-half.x,half.y-cut*open),center+Vector2(-half.x,-half.y+cut*open)])
	draw_polygon(paper,PackedColorArray([Color(0.94,0.98,0.91,alpha*0.91)]))
	var outline := paper.duplicate()
	outline.append(paper[0])
	draw_polyline(outline,Color(0.82,0.73,0.46,alpha*0.68),0.9*size,true)
	if open > 0.9:
		var y := goal_rect.position.y+38*size
		draw_line(Vector2(center.x-72*size,y),Vector2(center.x+72*size,y),Color(0.65,0.76,0.66,alpha*0.32),0.7*size,true)
		for side in [-1,1]:
			var tip := center+Vector2(side*(half.x-7*size),0)
			draw_polygon(PackedVector2Array([tip+Vector2(0,-4)*size,tip+Vector2(2,0)*size,tip+Vector2(0,4)*size,tip-Vector2(2,0)*size]),PackedColorArray([Color(1,0.89,0.57,alpha)]))
