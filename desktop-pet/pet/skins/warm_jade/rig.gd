extends Node2D

# One geometric master per rigid stone; all motion preserves the facets.
var phase := 0.0
var lean := 0.0
var spread := 0.0
var lift := 0.0
var drift := 0.0
var energy := 0.0
var gait := 0.0
var turn := 0.0
var parts: Array[Transform2D] = []
var glow := GradientTexture2D.new()
var _secondary_left := Vector2.ZERO
var _secondary_right := Vector2.ZERO
var _lag_delta := 0.0
var _secondary_ready := false
var _growth := 0.0
const Appearance = preload("res://pet/appearance.gd")
const Elements = preload("res://pet/element_effects.gd")
const FlameFlow = preload("res://pet/flame_flow.gd")
const ElementLayer = preload("res://pet/effects/element_layer.gd")
var _effect_layers: Array[Node2D] = []
var appearance_style := "jade"
var appearance_color := "jade"
var _tint := Color("79bca9")
var _light := Color(1,0.91,0.64)
var _attention := Vector2.ZERO
var _attention_goal := Vector2.ZERO
const CENTER := Vector2(220, 133)
var CORE := PackedVector2Array([Vector2(0,-117),Vector2(58,0),Vector2(0,117),Vector2(-58,0)])
var SHARD := PackedVector2Array([Vector2(-9,-40),Vector2(19,-10),Vector2(9,40),Vector2(-17,8)])

func _init() -> void:
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	add_child(player)
	var library := AnimationLibrary.new()
	# The first and last keys are the same hover pose, with eased velocity.
	var poses := {
		"float": [4.8,0.0,0.0,0.0,0.0,0.0],
		"swim": [5.8,-0.23,12.0,-16.0,-58.0,0.5],
		"look": [4.6,-0.25,9.0,-9.0,-16.0,0.5],
		"stretch": [4.8,0.0,44.0,-28.0,0.0,0.8],
		"rest": [4.8,0.08,-19.0,25.0,0.0,-0.45],
		"celebrate": [5.2,0.14,38.0,-30.0,16.0,1.0],
		"carry": [2.0,-0.10,-10.0,-4.0,0.0,0.3],
		"breath": [5.6,-0.035,30.0,-20.0,0.0,1.0],
		"walk": [6.2,0.14,8.0,-16.0,70.0,0.6],
		"laugh": [5.4,0.24,-12.0,-12.0,0.0,0.9],
		"jump": [4.4,0.12,24.0,-155.0,0.0,1.0],
		"hop": [5.4,0.16,18.0,-95.0,36.0,0.8],
		"spin": [6.0,0.0,52.0,-24.0,0.0,1.0],
		"sway": [6.4,0.44,14.0,-14.0,58.0,0.6],
		"bow": [5.2,0.0,0.0,0.0,0.0,0.0],
		"roll": [5.8,0.0,0.0,0.0,0.0,0.0],
		"dance": [6.6,0.0,0.0,0.0,0.0,0.0]
	}
	# Authored beats: anticipation, clear gesture, overshoot, then quiet hover.
	# Columns are time, lean, spread, lift, drift, energy, gait, turn.
	var choreography := {
		"bow": [
			[0.0,0,0,0,0,0,0,0], [0.16,-0.16,12,-12,-5,0.3,-8,0],
			[0.38,0.76,26,30,17,0.55,15,0], [0.58,0.76,26,30,17,0.55,15,0],
			[0.80,-0.09,9,-8,-3,0.2,-5,0], [1.0,0,0,0,0,0,0,0]],
		"roll": [
			[0.0,0,0,0,0,0,0,0], [0.17,-0.22,-12,24,-18,0.35,-9,-0.18],
			[0.32,0.06,42,-78,-10,0.85,16,0.6], [0.52,0.0,58,-105,38,1.0,-18,PI],
			[0.76,0.08,44,-48,18,0.8,12,TAU], [0.86,-0.13,10,18,-5,0.35,-7,TAU],
			[1.0,0,0,0,0,0,0,0]],
		"dance": [
			[0.0,0,0,0,0,0,0,0], [0.12,-0.14,-6,14,-12,0.3,-9,0],
			[0.25,0.32,22,-30,48,0.8,27,0.16], [0.38,-0.30,34,-10,-48,0.85,-27,-0.16],
			[0.51,0.34,22,-36,52,1.0,29,0.2], [0.64,-0.32,34,-14,-52,0.85,-29,-0.2],
			[0.78,0.0,46,-42,0,1.0,0,0], [0.88,0.10,6,12,8,0.3,6,0],
			[1.0,0,0,0,0,0,0,0]]
	}
	for action: String in poses:
		var values: Array = poses[action]
		var animation := Animation.new()
		animation.length = values[0]
		if action in ["float", "carry"]:
			animation.loop_mode = Animation.LOOP_LINEAR
		var properties := ["lean","spread","lift","drift","energy","gait","turn"]
		for index in properties.size():
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track,NodePath(".:" + properties[index]))
			animation.track_set_interpolation_type(track,Animation.INTERPOLATION_LINEAR_ANGLE if properties[index] == "turn" else Animation.INTERPOLATION_LINEAR)
			for sample in range(61):
				var key := sample / 60.0
				var envelope := smoothstep(0.0,0.20,key) * (1.0-smoothstep(0.74,1.0,key))
				if action == "breath": envelope = smoothstep(0.0,0.16,key)*(1.0-smoothstep(0.9,1.0,key))
				var value: float = values[index+1] * envelope if index < 5 else 0.0
				var property: String = properties[index]
				if action == "walk":
					if property == "drift": value *= sin(TAU*key)
					if property == "lean": value *= 1.5*sin(TAU*key*6)
					if property == "lift": value *= absf(sin(TAU*key*6))
					if property == "gait": value = 22.0*sin(TAU*key*6)*envelope
				if action == "laugh":
					if property == "lean": value *= sin(TAU*key*7)
					if property == "lift": value *= 0.5+0.5*cos(TAU*key*14)
					if property == "gait": value = 7.0*sin(TAU*key*7)*envelope
				if action in ["walk", "laugh"] and property == "lift":
					# A preparatory dip makes the first step/chuckle feel weighted;
					# a smaller landing pulse releases that energy into hover.
					value *= smoothstep(0.16,0.25,key)
					value += 15.0*sin(PI*clampf(key/0.20,0.0,1.0))
					value += 7.0*sin(PI*clampf((key-0.82)/0.18,0.0,1.0))
				if action == "jump":
					if property == "lift": value = 23.0*smoothstep(0.0,0.16,key)*(1.0-smoothstep(0.16,0.28,key))-155.0*pow(maxf(0.0,sin(PI*clampf((key-0.24)/0.53,0.0,1.0))),1.2)+12.0*sin(PI*clampf((key-0.77)/0.23,0.0,1.0))
					if property == "lean": value *= sin(TAU*key)
				if action == "hop":
					if property == "lift": value *= pow(absf(sin(PI*key*3)),1.2)
					if property in ["drift","lean"]: value *= sin(TAU*key*1.5)
					if property == "gait": value = 13.0*sin(TAU*key*3)*envelope
				if action == "spin" and property == "turn": value = TAU*pow(sin(PI*key),2.0)
				if action == "sway":
					if property in ["drift","lean"]: value *= sin(TAU*key*2)
					if property == "lift": value *= 0.5+0.5*cos(TAU*key*4)
				if action == "swim":
					if properties[index] == "drift": value *= sin(TAU*key)
					if properties[index] == "lift": value *= sin(TAU*key*2)
					if properties[index] == "lean": value *= cos(TAU*key)
				if action == "look" and properties[index] in ["lean","drift"]: value *= sin(TAU*key)
				if action == "celebrate":
					if properties[index] in ["drift","lean"]: value *= sin(TAU*key)
					if properties[index] == "lift": value *= 1.0+0.22*sin(TAU*key*2)
					if properties[index] == "spread": value *= 1.0+0.14*sin(TAU*key*2)
				if action == "carry" and index < 5: value = values[index+1]
				if choreography.has(action):
					var beats: Array = choreography[action]
					for beat in range(1,beats.size()):
						if key <= beats[beat][0]:
							var before: Array = beats[beat-1]
							var after: Array = beats[beat]
							var blend := smoothstep(before[0],after[0],key)
							# 2π and zero are the same hover orientation. Keep the
							# completed roll through the landing, then ease its lean.
							var target: float = after[index+1]
							if action == "roll" and property == "turn" and beat == beats.size()-1:
								target = TAU
							value = lerpf(before[index+1],target,blend)
							break
					if key == 1.0: value = 0.0
				animation.track_insert_key(track,key*animation.length,value)
		library.add_animation(action,animation)
	player.add_animation_library(&"",library)
	glow.width = 128
	glow.height = 128
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5,0.5)
	glow.fill_to = Vector2(1.0,0.5)
	glow.gradient = Gradient.new()
	glow.gradient.offsets = PackedFloat32Array([0.0,0.24,0.6,1.0])
	glow.gradient.colors = PackedColorArray([Color(1,0.89,0.58,0.7),Color(1,0.88,0.58,0.28),Color(1,0.88,0.6,0.06),Color(1,0.9,0.7,0)])
	sync_pose()
	for front in [false,true]:
		var layer := ElementLayer.new()
		layer.foreground = front
		layer.show_behind_parent = not front
		add_child(layer)
		_effect_layers.append(layer)
		layer.refresh()

func advance_pose(delta: float) -> void:
	phase += maxf(0.0,delta)
	_attention = _attention.lerp(_attention_goal,1.0-exp(-maxf(0.0,delta)/0.22))
	_lag_delta = maxf(0.0,delta)
	sync_pose()
	queue_redraw()
	_refresh_effects()

func sync_pose() -> void:
	var bob := sin(phase*TAU/4.8)*8.0
	var center := CENTER + Vector2(drift+_attention.x*6,bob+lift-absf(_attention.y)*2)
	var left := center+Vector2(-104-spread,28+sin(phase*1.31-0.5)*5+spread*-0.78+gait)
	var right := center+Vector2(104+spread,28+sin(phase*1.31-1.0)*5+spread*-0.78-gait)
	if not _secondary_ready:
		_secondary_left = left
		_secondary_right = right
		_secondary_ready = true
	_secondary_left = _secondary_left.lerp(left,1.0-exp(-_lag_delta/0.07))
	_secondary_right = _secondary_right.lerp(right,1.0-exp(-_lag_delta/0.12))
	_lag_delta = 0.0
	parts = [
		Transform2D(-0.17-spread*0.004+lean*0.65+sin(phase*1.3-0.5)*0.04,_secondary_left),
		Transform2D(lean+turn+sin(phase*TAU/4.8)*0.018+_attention.x*0.12,center),
		Transform2D(0.22+spread*0.004+lean*0.7+sin(phase*1.3-1.0)*0.04,_secondary_right)
	]

func deform_point(point: Vector2) -> Vector2:
	return parts[1] * (point-CENTER)

func set_growth(value: float) -> void:
	_growth = clampf(value,0.0,1.0) if is_finite(value) else 0.0
	queue_redraw()
	_refresh_effects()

func _refresh_effects() -> void:
	for layer in _effect_layers: layer.refresh()

func set_appearance(style: String, color: String) -> void:
	var selected := Appearance.selection(style,color)
	appearance_style = selected[0]
	appearance_color = selected[1]
	_tint = Appearance.tint(appearance_color)
	_light = Color(1,0.91,0.64) if appearance_color in ["jade","amber"] else _tint.lightened(0.65)
	if appearance_style == "flame": _light = _tint.lightened(0.78)
	if appearance_style == "lightning": _light = Color("dceaff")
	if appearance_style == "snow": _light = Color("effbff")
	glow.gradient.colors = PackedColorArray([Color(_light,0.7),Color(_light,0.28),Color(_light,0.06),Color(_light,0.0)])
	queue_redraw()
	_refresh_effects()

func facet_colors() -> Array[Color]:
	var alpha := 0.64
	if appearance_style == "glass": alpha = 0.39
	if appearance_style == "opal": alpha = 0.72
	if appearance_style == "flame": alpha = 0.76
	var base := _tint
	if appearance_style == "flame": base = Color("e8bf8f").lerp(_tint,0.48)
	if appearance_style == "lightning": base = Color("8a80ae").lerp(_tint,0.35)
	if appearance_style == "snow": base = Color("bedddc").lerp(_tint,0.15)
	if appearance_style == "opal":
		var rainbow := Color.from_hsv(fposmod(_tint.h+0.12*sin(phase*0.38),1.0),0.40,0.94)
		base = base.lerp(rainbow,0.55)
	return [Color(base.lightened(0.43),alpha),Color(base.darkened(0.26),alpha-0.05),Color(base,alpha+0.04),Color(base.lightened(0.24),alpha-0.02)]

func set_desktop_attention(direction: Vector2) -> void:
	_attention_goal = direction.limit_length(1.0) if direction.is_finite() else Vector2.ZERO

func particle_count() -> int:
	return 28 + floori(44.0*_growth)

func flame_particle_count() -> int:
	return FlameFlow.ember_particles(self).size() if appearance_style == "flame" else 0


func _particle_visibility(index: int) -> float:
	# New motes emerge gradually rather than popping in at a level boundary.
	return clampf(28.0+44.0*_growth-index,0.0,1.0)

func region_sample_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for part in parts:
		points.append(part.origin)
		points.append(part * Vector2(0,-117))
	# Particle paths move even when the stone pose is nearly stationary.
	points.append(Vector2(phase*25,0))
	return points

func render_regions() -> Array[PackedVector2Array]:
	# Windows clips drawing to this region. Cover light and dust individually so
	# unrelated transparent gaps still pass through to the desktop.
	var result: Array[PackedVector2Array] = []
	result.append(_ellipse(parts[1].origin,Vector2(105,145),32))
	# The core and its internal light seam rotate as one rigid object.
	result.append(parts[1] * _ellipse(Vector2.ZERO,Vector2(72,126),32))
	result.append(_ellipse(Vector2(220+drift,277),Vector2(51,10),24))
	for index in [0,2]: result.append(parts[index] * (Transform2D(0,Vector2.ONE*1.10,0,Vector2.ZERO) * SHARD))
	if appearance_style == "flame":
		result.append_array(FlameFlow.regions(self))
	if appearance_style in ["lightning","snow"]:
		result.append_array(Elements.regions(self,appearance_style))
	for index in range(ceili(28+44*_growth)):
		var point := _particle_position(index)
		var radius := 9.0+3.0*_growth
		if appearance_style == "flame" and ((point-parts[1].origin-Vector2(10,-47))/Vector2(168,234)).length()+radius/168.0 < 0.98:
			continue
		# The main halo already covers inner motes. Only outlying glows need their
		# own native polygon, avoiding dozens of redundant unions as it grows.
		if ((point-parts[1].origin)/Vector2(105,145)).length()+radius/105.0 > 1.0:
			result.append(_ellipse(point,Vector2.ONE*radius,12))
	return result

func _ellipse(center: Vector2, radius: Vector2, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count): points.append(center+Vector2.from_angle(TAU*index/count)*radius)
	return points

func _particle_position(index: int) -> Vector2:
	var age := fposmod(phase*0.16+index*0.417219,1.0)
	var angle := index*2.39996+phase*0.12
	return parts[1].origin+Vector2(sin(angle)*(82+index%5*9),98-age*224)

func _draw() -> void:
	var bright := clampf(0.68+0.12*sin(phase*1.31)+energy*0.25,0.25,1.0)
	var center := parts[1].origin
	draw_texture_rect(glow,Rect2(center-Vector2(100,140),Vector2(200,280)),false,Color(1,1,1,0.42*bright))
	# Grounding shadow expands softly with hover height.
	for ring in range(12,0,-1):
		draw_set_transform(Vector2(220+drift,277),0,Vector2(1,0.16))
		draw_circle(Vector2.ZERO,24.0+ring*2.0,Color(0.18,0.24,0.19,0.009))
	draw_set_transform(Vector2.ZERO)
	for index in [0,2,1]:
		var part := parts[index]
		draw_set_transform(part.origin,part.get_rotation())
		_draw_stone(CORE if index == 1 else SHARD,index == 1,bright)
	draw_set_transform(Vector2.ZERO)
	# Deterministic, looping dust: fade in/out at respawn; never pop or accumulate.
	for index in range(ceili(28+44*_growth)):
		var age := fposmod(phase*0.16+index*0.417219,1.0)
		var point := _particle_position(index)
		var alpha := minf(0.95,pow(sin(age*PI),2.0)*(0.29+bright*0.35)*(1.0+_growth*0.65))*_particle_visibility(index)
		var radius := (0.75+float(index%3)*0.45)*(1.0+_growth*0.3)
		var halo := 7.0+3.0*_growth
		draw_texture_rect(glow,Rect2(point-Vector2.ONE*halo,Vector2.ONE*halo*2),false,Color(1,1,1,alpha))
		draw_circle(point,radius,Color(_light.lightened(0.18),alpha))
		if index%6 == 0:
			draw_line(point-Vector2(3+_growth,0),point+Vector2(3+_growth,0),Color(1,0.97,0.81,alpha),0.7,true)
			draw_line(point-Vector2(0,4+_growth),point+Vector2(0,4+_growth),Color(1,0.97,0.81,alpha),0.7,true)



func _draw_stone(outline: PackedVector2Array, core: bool, bright: float) -> void:
	var hub := Vector2(0,5) if core else Vector2(1,0)
	# Translucent jade, cool refraction at the edges and a warm lit interior.
	var colors := facet_colors()
	for index in range(4):
		var tint: Color = colors[index].lightened(bright*0.035)
		draw_polygon(PackedVector2Array([outline[index],outline[(index+1)%4],hub]),PackedColorArray([tint.lightened(0.25),tint,tint.lightened(0.18)]))
	if core:
		_draw_crystal_interior(bright)
		var inner := PackedVector2Array([Vector2(0,-68),Vector2(24,0),Vector2(0,73),Vector2(-24,0)])
		for index in range(4):
			draw_polygon(PackedVector2Array([outline[index],inner[index],inner[(index+1)%4],outline[(index+1)%4]]),PackedColorArray([Color(0.91,1,0.97,0.08),Color(0.95,1,0.91,0.28),Color(0.62,0.88,1,0.15),Color(0.73,0.9,0.96,0.04)]))
		var shine := 0.14+0.09*sin(phase*0.8)
		if appearance_style == "glass": shine *= 1.6
		draw_polygon(PackedVector2Array([Vector2(-48,-4),Vector2(-8,-93),Vector2(-19,-7),Vector2(-4,68)]),PackedColorArray([Color(0.92,1,1,shine)]))
		var sweep := sin(phase*0.34)*90.0
		var band := PackedVector2Array([Vector2(-100,sweep-37),Vector2(100,sweep+7),Vector2(100,sweep+14),Vector2(-100,sweep-30)])
		for clipped in Geometry2D.intersect_polygons(CORE,band):
			draw_polygon(clipped,PackedColorArray([Color(0.9,0.98,1,0.11+energy*0.04)]))
		var prism := PackedVector2Array([Vector2(-100,sweep-32),Vector2(100,sweep+12),Vector2(100,sweep+14),Vector2(-100,sweep-30)])
		for clipped in Geometry2D.intersect_polygons(CORE,prism):
			draw_polygon(clipped,PackedColorArray([Color(_tint.lightened(0.5),0.35 if appearance_style == "glass" else 0.22)]))
		if appearance_style == "opal":
			# Iridescence lives inside the same facets, not an extra silhouette.
			for layer in range(3):
				var iridescent := Color.from_hsv(fposmod(_tint.h+layer*0.22+sin(phase*0.3)*0.12,1.0),0.48,1.0,0.22)
				var offset := sin(phase*0.45+layer*1.7)*35.0
				var ribbon := PackedVector2Array([Vector2(-70,offset-55+layer*25),Vector2(70,offset-15+layer*25),Vector2(70,offset+5+layer*25),Vector2(-70,offset-35+layer*25)])
				for clipped in Geometry2D.intersect_polygons(CORE,ribbon):
					draw_polygon(clipped,PackedColorArray([iridescent]))
		if appearance_style == "glass":
			draw_polyline(PackedVector2Array([Vector2(0,-107),Vector2(41,0),Vector2(0,107),Vector2(-41,0),Vector2(0,-107)]),Color(_tint.lightened(0.7),0.48),0.8,true)
		draw_line(Vector2(-21,-4),Vector2(0,-79),Color(1,1,0.94,0.35),0.8,true)
		draw_line(Vector2(24,0),Vector2(0,100),Color(0.71,0.91,1,0.42),0.8,true)
	var edge := outline.duplicate()
	edge.append(outline[0])
	draw_polyline(edge,Color(0.96,0.98,0.85,0.65),0.8,true)
	draw_line(outline[0],outline[3],Color(0.95,1,1,0.85),1.3,true)
	draw_line(outline[0],hub,Color(1,1,0.89,0.65),0.7,true)
	if appearance_style in ["flame","lightning","snow"]:
		var gold := Color("f0dfb4").lerp(_light,0.3)
		draw_line(outline[0],hub,Color(gold,0.72),0.85,true)
		if core:
			# Painted secondary planes and fine mineral-gold facets, still rigid.
			var plane := PackedVector2Array([Vector2(0,-104),Vector2(-37,-9),Vector2(-13,9),Vector2(0,103),Vector2(14,-4)])
			draw_polygon(plane,PackedColorArray([Color(gold,0.05),Color(_tint,0.10),Color(gold,0.18),Color(gold,0.03),Color(_light,0.12)]))
			for side in [-1,1]:
				var line := PackedVector2Array([Vector2(side*10,-65),Vector2(side*31,-12),Vector2(side*17,21),Vector2(side*6,69)])
				draw_polyline(line,Color(gold,0.30),0.65,true)
	if not core: return
	# The seam is light on the same solid stone, never an opening in its body.
	draw_texture_rect(glow,Rect2(-31,-108,62,216),false,Color(1,1,1,bright))
	draw_polygon(PackedVector2Array([Vector2(0,-115),Vector2(5,-22),Vector2(13,4),Vector2(4,25),Vector2(0,115),Vector2(-4,25),Vector2(-12,4),Vector2(-5,-22)]),PackedColorArray([Color(_light,0.5+0.4*bright)]))
	draw_polygon(PackedVector2Array([Vector2(0,-68),Vector2(2,-20),Vector2(8,4),Vector2(2,22),Vector2(0,83),Vector2(-2,22),Vector2(-8,4),Vector2(-2,-20)]),PackedColorArray([Color(_light.lightened(0.65),bright)]))

func _draw_crystal_interior(bright: float) -> void:
	# Embedded, fine mineral veins; no holes, extra shards or changes of outline.
	var veins := [
		PackedVector2Array([Vector2(-16,-72),Vector2(-26,-43),Vector2(-20,-10),Vector2(-33,12),Vector2(-21,42),Vector2(-12,67)]),
		PackedVector2Array([Vector2(18,-58),Vector2(29,-21),Vector2(20,11),Vector2(31,27),Vector2(17,66)]),
		PackedVector2Array([Vector2(-26,-43),Vector2(-37,-21),Vector2(-38,-6)]),
		PackedVector2Array([Vector2(-33,12),Vector2(-41,21),Vector2(-29,50)]),
		PackedVector2Array([Vector2(29,-21),Vector2(38,-5),Vector2(33,15)]),
		PackedVector2Array([Vector2(20,11),Vector2(13,29),Vector2(17,48)])
	]
	draw_texture_rect(glow,Rect2(-37,-83,56,156),false,Color(0.59,0.95,1,0.26))
	draw_texture_rect(glow,Rect2(-12,-24,51,114),false,Color(0.70,0.85,1,0.18))
	for index in range(veins.size()):
		var amount := (0.20+bright*0.14)*(0.85+0.15*sin(phase*0.6+index))
		draw_polyline(veins[index],Color(_tint.lightened(0.15),amount*0.45),2.0,true)
		draw_polyline(veins[index],Color(_tint.lightened(0.75),amount),0.65,true)
	# Offset rear facets provide depth through the translucent front surface.
	draw_polygon(PackedVector2Array([Vector2(-5,-80),Vector2(31,-8),Vector2(5,76),Vector2(15,6)]),PackedColorArray([Color(0.69,0.90,1,0.06),Color(0.74,0.93,1,0.19),Color(0.53,0.81,0.89,0.05),Color(0.94,1,0.97,0.15)]))


