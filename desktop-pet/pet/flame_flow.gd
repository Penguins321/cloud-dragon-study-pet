extends RefCounted

# Analytic ribbons: paint and ripples travel from root to tip, independently of
# the rigid crystal pose. No particle nodes, image masks or frame accumulation.
const EMBER_COUNT := 18
const WISP_COUNT := 4
const STEPS := 32
static var _strip_index_cache: Dictionary = {}
static var _base_curves: Array[Dictionary] = []

static func strip_indices(point_count: int) -> PackedInt32Array:
	if _strip_index_cache.has(point_count): return _strip_index_cache[point_count]
	var indices := PackedInt32Array()
	for index in range(point_count-1):
		var opposite := point_count*2-1-index
		indices.append_array(PackedInt32Array([index,index+1,opposite-1,index,opposite-1,opposite]))
	_strip_index_cache[point_count] = indices
	return indices

static func paths(rig: Node2D) -> Array[Dictionary]:
	var key: Array = [rig.phase,rig.parts,rig.energy,rig._growth]
	if rig.has_meta(&"_flame_flow_geometry"):
		var cached: Dictionary = rig.get_meta(&"_flame_flow_geometry")
		if cached.key == key: return cached.paths
	var result: Array[Dictionary] = []
	var center: Vector2 = rig.parts[1].origin
	_prepare_base_curves()
	for index in _base_curves.size():
		var points := PackedVector2Array()
		var widths := PackedFloat32Array()
		var base: Dictionary = _base_curves[index]
		var origin: Vector2 = center if index < 3 else rig.parts[0 if index == 3 else 2].origin
		var scale := 1.0 if index < 3 else 0.90
		var broad := [18.0,15.0,12.0,8.0,7.0][index] as float
		broad *= 1.0+rig._growth*0.12+maxf(0.0,rig.energy)*0.05
		for sample in range(STEPS+1):
			var u := sample/float(STEPS)
			# Negative time phase transports disturbances upward along the stroke;
			# this changes actual geometry, instead of wobbling one static band.
			var travel: float = u*12.0-rig.phase*3.4+index*1.9
			var ripple: float = (sin(travel)*5.0+sin(travel*1.83+index)*2.1)*base.envelope[sample]
			points.append(origin+(base.points[sample]+base.normals[sample]*ripple)*scale)
			var flowing_width := 0.78+0.19*sin(travel-0.7)+0.10*sin(travel*2.1)
			widths.append(maxf(0.18,broad*base.taper[sample]*flowing_width)*scale)
		var path := {"points":points,"widths":widths,"foreground":index == 2 or index == 4,"seed":float(index)}
		_prepare_paint(path,rig.phase)
		result.append(path)
	key[1] = rig.parts.duplicate()
	rig.set_meta(&"_flame_flow_geometry",{"key":key,"paths":result})
	return result

static func _prepare_base_curves() -> void:
	if not _base_curves.is_empty(): return
	var strokes := [
		[Vector2(-5,132),Vector2(-88,95),Vector2(-107,35),Vector2(-74,-35),Vector2(-98,-95),Vector2(-58,-150),Vector2(-15,-173),Vector2(20,-209),Vector2(2,-248)],
		[Vector2(-50,124),Vector2(29,137),Vector2(96,94),Vector2(121,35),Vector2(99,-22),Vector2(65,-55),Vector2(77,-97),Vector2(119,-142),Vector2(98,-183)],
		[Vector2(-84,52),Vector2(-95,103),Vector2(-35,143),Vector2(43,132),Vector2(78,88),Vector2(72,50)],
		[Vector2(10,36),Vector2(-24,15),Vector2(-34,-14),Vector2(-10,-48),Vector2(-18,-83)],
		[Vector2(-8,35),Vector2(23,12),Vector2(30,-18),Vector2(13,-47),Vector2(27,-72)]
	]
	for controls in strokes:
		var points := PackedVector2Array()
		var normals := PackedVector2Array()
		var taper := PackedFloat32Array()
		var envelope := PackedFloat32Array()
		for sample in range(STEPS+1):
			var u := sample/float(STEPS)
			points.append(_curve(controls,u))
			normals.append((_curve(controls,minf(1.0,u+0.005))-_curve(controls,maxf(0.0,u-0.005))).normalized().orthogonal())
			envelope.append(sin(PI*u))
			taper.append(pow(maxf(0.0,sin(PI*u)),0.65)*pow(1.0-u*0.62,0.7))
		_base_curves.append({"points":points,"normals":normals,"taper":taper,"envelope":envelope})

static func _curve(controls: Array, u: float) -> Vector2:
	var coordinate := clampf(u,0.0,1.0)*(controls.size()-1)
	var segment := mini(floori(coordinate),controls.size()-2)
	var t := coordinate-segment
	var a: Vector2 = controls[maxi(0,segment-1)]
	var b: Vector2 = controls[segment]
	var c: Vector2 = controls[segment+1]
	var d: Vector2 = controls[mini(controls.size()-1,segment+2)]
	return 0.5*((2.0*b)+(-a+c)*t+(2.0*a-5.0*b+4.0*c-d)*t*t+(-a+3.0*b-3.0*c+d)*t*t*t)

static func _normal(points: PackedVector2Array, index: int) -> Vector2:
	return (points[mini(points.size()-1,index+1)]-points[maxi(0,index-1)]).normalized().orthogonal()

static func _prepare_paint(path: Dictionary, phase: float) -> void:
	var points: PackedVector2Array = path.points
	var normals := PackedVector2Array()
	var heat := PackedFloat32Array()
	var pigment := PackedFloat32Array()
	heat.resize(points.size()*2)
	pigment.resize(points.size()*2)
	for index in points.size():
		normals.append(_normal(points,index))
		var u := index/float(points.size()-1)
		var warmth: float = 0.37+0.24*sin(u*13.0-phase*3.4+path.seed)
		var brush: float = u*22.0-phase*4.4+path.seed*2.3
		var wash: float = (0.47+0.53*pow(0.5+0.5*sin(u*9.0-phase*2.1+path.seed),0.7))*(0.72+0.28*sin(PI*u))
		var opposite := points.size()*2-1-index
		heat[index] = clampf(warmth+0.18,0.0,1.0)
		heat[opposite] = clampf(warmth-0.18,0.0,1.0)
		pigment[index] = (0.10+0.90*pow(0.5+0.5*sin(brush+0.8),0.8))*wash
		pigment[opposite] = (0.10+0.90*pow(0.5+0.5*sin(brush-0.8),0.8))*wash
	path.normals = normals
	path.heat = heat
	path.pigment = pigment
	path.start_cap = (points[0]-points[1]).normalized()
	path.end_cap = (points[-1]-points[-2]).normalized()

static func _sample(path: Dictionary, u: float) -> Dictionary:
	var coordinate: float = clampf(u,0.0,1.0)*(path.points.size()-1)
	var index := mini(path.points.size()-2,floori(coordinate))
	var blend: float = coordinate-index
	var point: Vector2 = path.points[index].lerp(path.points[index+1],blend)
	var normal: Vector2 = path.normals[index].lerp(path.normals[index+1],blend).normalized()
	return {"point":point,"normal":normal,"width":lerpf(path.widths[index],path.widths[index+1],blend)}

static func wisp_paths(rig: Node2D) -> Array[Dictionary]:
	var main := paths(rig)
	var key: Array = rig.get_meta(&"_flame_flow_geometry").key
	if rig.has_meta(&"_flame_flow_wisps"):
		var cached: Dictionary = rig.get_meta(&"_flame_flow_wisps")
		if cached.key == key: return cached.paths
	var result: Array[Dictionary] = []
	for index in range(WISP_COUNT):
		var age := fposmod(rig.phase*(0.22+index*0.017)+index*0.271828,1.0)
		var points := PackedVector2Array()
		var widths := PackedFloat32Array()
		var side := -1.0 if index%2 == 0 else 1.0
		var source := _sample(main[index%2],0.035+age*0.84)
		var tangent: Vector2 = -source.normal.orthogonal()
		for step in range(19):
			var t := step/18.0
			var curl := sin(PI*t*0.94)*(15.0+5.0*sin(age*6.0+index))+sin(t*TAU)*2.0
			points.append(source.point+source.normal*side*(source.width*0.55+curl)+tangent*(t*46.0-sin(PI*t)*6.0))
			widths.append(maxf(0.12,pow(sin(PI*t),0.9)*(4.0+2.5*sin(age*9.0+index))*(1.0-t*0.65)))
		var path := {"points":points,"widths":widths,"foreground":false,"seed":index+5.0,"age":age,"alpha":0.85*pow(sin(PI*age),2.0)}
		_prepare_paint(path,rig.phase)
		result.append(path)
	rig.set_meta(&"_flame_flow_wisps",{"key":key,"paths":result})
	return result

static func _outline(path: Dictionary, scale: float, pad: float = 0.0, bias: float = 0.0) -> PackedVector2Array:
	var points: PackedVector2Array = path.points
	var normals: PackedVector2Array = path.normals
	var polygon := PackedVector2Array()
	polygon.resize(points.size()*2)
	for index in points.size():
		var cap := Vector2.ZERO
		if index == 0: cap = path.start_cap*pad
		if index == points.size()-1: cap = path.end_cap*pad
		polygon[index] = points[index]+cap+normals[index]*(path.widths[index]*(scale+bias)+pad)
		polygon[points.size()*2-1-index] = points[index]+cap+normals[index]*(path.widths[index]*(-scale+bias)-pad)
	return polygon

static func _paint(rig: Node2D, path: Dictionary, scale: float, pad: float, bias: float, base: Color, hot: Color, opacity: float, canvas: CanvasItem) -> void:
	var colors := PackedColorArray()
	var points: PackedVector2Array = path.points
	colors.resize(points.size()*2)
	for index in colors.size():
		colors[index] = Color(base.lerp(hot,path.heat[index]),opacity*path.pigment[index])
	# Adjacent edge pairs define the ribbon even when a wide curling wash folds.
	# Whole-outline ear clipping cannot represent those legitimate strip folds.
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(),strip_indices(points.size()),_outline(path,scale,pad,bias),colors)

static func draw(rig: Node2D, foreground: bool, canvas: CanvasItem = null) -> void:
	var target: CanvasItem = rig if canvas == null else canvas
	for path in paths(rig):
		if path.foreground != foreground: continue
		# Copper outer wash, vermilion body, orange paint, then a narrow gold vein.
		_paint(rig,path,1.0,4.0,0.0,Color("bd3c13"),Color("ea7e29"),0.11,target)
		_paint(rig,path,1.0,0.0,0.0,Color("ae3218"),Color("e36e27"),0.74,target)
		_paint(rig,path,0.67,0.0,-0.13,Color("ec6d27"),Color("ffc36a"),0.84,target)
		_paint(rig,path,0.24,0.0,-0.31,Color("ffad42"),Color("fff2ae"),0.85,target)
		# A short hot brush edge flows along each stroke and vanishes at wrap.
		var progress := fposmod(rig.phase*0.31+path.seed*0.29,1.0)
		var edge := PackedVector2Array()
		var points: PackedVector2Array = path.points
		for sample in range(9):
			var u := clampf(progress+(sample/8.0-0.5)*0.15,0.0,1.0)
			var coordinate := u*(points.size()-1)
			var index := mini(points.size()-2,floori(coordinate))
			var blend := coordinate-index
			var before: Vector2 = points[index]-path.normals[index]*path.widths[index]*0.82
			var after: Vector2 = points[index+1]-path.normals[index+1]*path.widths[index+1]*0.82
			edge.append(before.lerp(after,blend))
		if edge.size() > 1:
			target.draw_polyline(edge,Color(Color("fff1b5"),0.72*pow(sin(PI*progress),2.0)),0.85,true)
	for wisp in wisp_paths(rig):
		if wisp.foreground != foreground or wisp.alpha <= 0.001: continue
		_paint(rig,wisp,1.0,2.0,0.0,Color("b63d20"),Color("ef9641"),wisp.alpha*0.50,target)
		_paint(rig,wisp,0.80,0.0,0.0,Color("ed772d"),Color("ffd785"),wisp.alpha,target)
		_paint(rig,wisp,0.20,0.0,-0.22,Color("ffc663"),Color("fff0ad"),wisp.alpha*0.90,target)
		var filament := PackedVector2Array()
		for point in wisp.points.size():
			filament.append(wisp.points[point]+wisp.normals[point]*wisp.widths[point])
		target.draw_polyline(filament,Color(1,0.76,0.35,wisp.alpha*0.55),0.65,true)
	for ember in ember_particles(rig):
		if ember.foreground != foreground or ember.alpha <= 0.001: continue
		var point: Vector2 = ember.position
		var tail: Vector2 = ember.tail
		var alpha: float = ember.alpha
		target.draw_texture_rect(rig.glow,Rect2(point-Vector2.ONE*6.0,Vector2.ONE*12.0),false,Color(1,0.54,0.20,alpha*0.25))
		target.draw_line(tail,point,Color(1,0.51,0.16,alpha*0.5),2.5,true)
		target.draw_line(tail.lerp(point,0.55),point,Color(1,0.87,0.52,alpha),0.9,true)

static func ember_particles(rig: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count: float = EMBER_COUNT+12.0*rig._growth
	for index in range(ceili(count)):
		var age := fposmod(rig.phase*(0.20+float(index%4)*0.021)+index*0.61803398875,1.0)
		var side := -1.0 if index%2 == 0 else 1.0
		var x := side*(70.0+sin(age*7.0+index*1.7)*32.0+float(index%3)*12.0)
		var y := 134.0-age*(310.0+float(index%5)*12.0)
		var point: Vector2 = rig.parts[1].origin+Vector2(x,y)
		var velocity := Vector2(side*cos(age*7.0+index*1.7)*0.55,-1.0).normalized()
		result.append({"position":point,"tail":point-velocity*(3.0+float(index%3)*2.0),"alpha":0.80*pow(sin(PI*age),2.0)*clampf(count-index,0.0,1.0),"age":age,"foreground":index%4 == 0})
	return result

static func regions(rig: Node2D) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	# The dense flame field uses three conservative ellipses. Dozens of curved
	# native mask unions are far more expensive than the visible ribbon drawing.
	var fields := [
		{"center":rig.parts[1].origin+Vector2(10,-47),"radius":Vector2(168,234)},
		{"center":rig.parts[0].origin+Vector2(0,-20),"radius":Vector2(55,105)},
		{"center":rig.parts[2].origin+Vector2(0,-20),"radius":Vector2(55,105)}
	]
	for field in fields:
		var outline := PackedVector2Array()
		for vertex in range(48):
			outline.append(field.center+Vector2.from_angle(TAU*vertex/48.0)*field.radius)
		result.append(outline)
	for ember in ember_particles(rig):
		if ember.alpha <= 0.001: continue
		var center: Vector2 = ember.position.lerp(ember.tail,0.5)
		var inside := false
		for field in fields:
			# Includes the streak and its radial 6px halo, with polygon edge margin.
			if ((center-field.center)/field.radius).length()+12.0/minf(field.radius.x,field.radius.y) < 0.99:
				inside = true
				break
		if inside: continue
		var outline := PackedVector2Array()
		for vertex in range(10):
			# Includes up to 1/30s of retained flame geometry at rest, plus halo.
			outline.append(center+Vector2.from_angle(TAU*vertex/10.0)*16.0)
		result.append(outline)
	return result
