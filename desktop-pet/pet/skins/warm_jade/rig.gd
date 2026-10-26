extends Node2D

# One geometric master per rigid stone; all motion preserves the facets.
var phase := 0.0
var lean := 0.0
var spread := 0.0
var lift := 0.0
var drift := 0.0
var energy := 0.0
var parts: Array[Transform2D] = []
var glow := GradientTexture2D.new()
var _secondary_left := Vector2.ZERO
var _secondary_right := Vector2.ZERO
var _lag_delta := 0.0
var _secondary_ready := false
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
		"breath": [5.6,-0.035,30.0,-20.0,0.0,1.0]
	}
	for action: String in poses:
		var values: Array = poses[action]
		var animation := Animation.new()
		animation.length = values[0]
		if action in ["float", "carry"]:
			animation.loop_mode = Animation.LOOP_LINEAR
		var properties := ["lean","spread","lift","drift","energy"]
		for index in properties.size():
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track,NodePath(".:" + properties[index]))
			animation.track_set_interpolation_type(track,Animation.INTERPOLATION_LINEAR)
			for sample in range(61):
				var key := sample / 60.0
				var envelope := smoothstep(0.0,0.20,key) * (1.0-smoothstep(0.74,1.0,key))
				if action == "breath": envelope = smoothstep(0.0,0.16,key)*(1.0-smoothstep(0.9,1.0,key))
				var value: float = values[index+1] * envelope
				if action == "swim":
					if properties[index] == "drift": value *= sin(TAU*key)
					if properties[index] == "lift": value *= sin(TAU*key*2)
					if properties[index] == "lean": value *= cos(TAU*key)
				if action == "look" and properties[index] in ["lean","drift"]: value *= sin(TAU*key)
				if action == "celebrate":
					if properties[index] in ["drift","lean"]: value *= sin(TAU*key)
					if properties[index] == "lift": value *= 1.0+0.22*sin(TAU*key*2)
					if properties[index] == "spread": value *= 1.0+0.14*sin(TAU*key*2)
				if action == "carry": value = values[index+1]
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

func advance_pose(delta: float) -> void:
	phase += maxf(0.0,delta)
	_lag_delta = maxf(0.0,delta)
	sync_pose()
	queue_redraw()

func sync_pose() -> void:
	var bob := sin(phase*TAU/4.8)*8.0
	var center := CENTER + Vector2(drift,bob+lift)
	var left := center+Vector2(-104-spread,28+sin(phase*1.31-0.5)*5+spread*-0.78)
	var right := center+Vector2(104+spread,28+sin(phase*1.31-1.0)*5+spread*-0.78)
	if not _secondary_ready:
		_secondary_left = left
		_secondary_right = right
		_secondary_ready = true
	_secondary_left = _secondary_left.lerp(left,1.0-exp(-_lag_delta/0.07))
	_secondary_right = _secondary_right.lerp(right,1.0-exp(-_lag_delta/0.12))
	_lag_delta = 0.0
	parts = [
		Transform2D(-0.17-spread*0.004+lean*0.65+sin(phase*1.3-0.5)*0.04,_secondary_left),
		Transform2D(lean+sin(phase*TAU/4.8)*0.018,center),
		Transform2D(0.22+spread*0.004+lean*0.7+sin(phase*1.3-1.0)*0.04,_secondary_right)
	]

func deform_point(point: Vector2) -> Vector2:
	return parts[1] * (point-CENTER)

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
	result.append(_ellipse(Vector2(220+drift,277),Vector2(51,10),24))
	for index in [0,2]: result.append(parts[index] * (Transform2D(0,Vector2.ONE*1.10,0,Vector2.ZERO) * SHARD))
	for index in range(26): result.append(_ellipse(_particle_position(index),Vector2.ONE*8,12))
	return result

func _ellipse(center: Vector2, radius: Vector2, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count): points.append(center+Vector2.from_angle(TAU*index/count)*radius)
	return points

func _particle_position(index: int) -> Vector2:
	var age := fposmod(phase*0.16+index*0.618034,1.0)
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
	for index in range(26):
		var age := fposmod(phase*0.16+index*0.618034,1.0)
		var point := _particle_position(index)
		var alpha := pow(sin(age*PI),2.0)*(0.24+bright*0.35)
		var radius := 0.7+float(index%3)*0.45
		draw_texture_rect(glow,Rect2(point-Vector2.ONE*7,Vector2.ONE*14),false,Color(1,1,1,alpha))
		draw_circle(point,radius,Color(1,0.94,0.72,alpha))
		if index%6 == 0:
			draw_line(point-Vector2(3,0),point+Vector2(3,0),Color(1,0.97,0.81,alpha),0.7,true)
			draw_line(point-Vector2(0,4),point+Vector2(0,4),Color(1,0.97,0.81,alpha),0.7,true)

func _draw_stone(outline: PackedVector2Array, core: bool, bright: float) -> void:
	var hub := Vector2(0,5) if core else Vector2(1,0)
	# Translucent jade, cool refraction at the edges and a warm lit interior.
	var colors := [Color(0.71,0.92,0.88,0.82),Color(0.29,0.64,0.65,0.78),Color(0.48,0.77,0.70,0.88),Color(0.80,0.93,0.80,0.79)]
	for index in range(4):
		var tint: Color = colors[index].lightened(bright*0.035)
		draw_polygon(PackedVector2Array([outline[index],outline[(index+1)%4],hub]),PackedColorArray([tint.lightened(0.25),tint,tint.lightened(0.18)]))
	if core:
		var inner := PackedVector2Array([Vector2(0,-68),Vector2(24,0),Vector2(0,73),Vector2(-24,0)])
		for index in range(4):
			draw_polygon(PackedVector2Array([outline[index],inner[index],inner[(index+1)%4],outline[(index+1)%4]]),PackedColorArray([Color(0.91,1,0.97,0.08),Color(0.95,1,0.91,0.28),Color(0.62,0.88,1,0.15),Color(0.73,0.9,0.96,0.04)]))
		var shine := 0.14+0.09*sin(phase*0.8)
		draw_polygon(PackedVector2Array([Vector2(-48,-4),Vector2(-8,-93),Vector2(-19,-7),Vector2(-4,68)]),PackedColorArray([Color(0.92,1,1,shine)]))
		var sweep := sin(phase*0.34)*90.0
		var band := PackedVector2Array([Vector2(-100,sweep-37),Vector2(100,sweep+7),Vector2(100,sweep+14),Vector2(-100,sweep-30)])
		for clipped in Geometry2D.intersect_polygons(CORE,band):
			draw_polygon(clipped,PackedColorArray([Color(0.9,0.98,1,0.11+energy*0.04)]))
		draw_line(Vector2(-21,-4),Vector2(0,-79),Color(1,1,0.94,0.35),0.8,true)
		draw_line(Vector2(24,0),Vector2(0,100),Color(0.71,0.91,1,0.42),0.8,true)
	var edge := outline.duplicate()
	edge.append(outline[0])
	draw_polyline(edge,Color(0.96,0.98,0.85,0.65),0.8,true)
	draw_line(outline[0],outline[3],Color(0.95,1,1,0.85),1.3,true)
	draw_line(outline[0],hub,Color(1,1,0.89,0.65),0.7,true)
	if not core: return
	# The seam is light on the same solid stone, never an opening in its body.
	draw_texture_rect(glow,Rect2(-31,-108,62,216),false,Color(1,1,1,bright))
	draw_polygon(PackedVector2Array([Vector2(0,-115),Vector2(5,-22),Vector2(13,4),Vector2(4,25),Vector2(0,115),Vector2(-4,25),Vector2(-12,4),Vector2(-5,-22)]),PackedColorArray([Color(1,0.91,0.64,0.5+0.4*bright)]))
	draw_polygon(PackedVector2Array([Vector2(0,-68),Vector2(2,-20),Vector2(8,4),Vector2(2,22),Vector2(0,83),Vector2(-2,22),Vector2(-8,4),Vector2(-2,-20)]),PackedColorArray([Color(1,0.99,0.85,bright)]))


