extends RefCounted

# Analytic paths keep every strand alive between frames; no random topology swaps.
const FLAKE_COUNT := 32
const PATH_STEPS := 28

static func _geometry_cache(rig: Node2D) -> Dictionary:
	var cache: Dictionary = rig.get_meta(&"element_flow_geometry",{})
	if cache.get("phase",-1.0)!=rig.phase or cache.get("parts",[])!=rig.parts:
		cache = {"phase":rig.phase,"parts":rig.parts.duplicate()}
		rig.set_meta(&"element_flow_geometry",cache)
	return cache

static func lightning_paths(rig: Node2D) -> Array[PackedVector2Array]:
	var cache := _geometry_cache(rig)
	if cache.has("lightning"): return cache.lightning
	var paths: Array[PackedVector2Array] = []
	var center: Vector2 = rig.parts[1].origin
	for strand in range(3):
		var path := PackedVector2Array()
		for step in range(PATH_STEPS+1):
			var t := step/float(PATH_STEPS)
			var breath: float = sin(rig.phase*0.72+t*8.0+strand)*14.0*sin(PI*t)
			var zig: float = sin(step*2.41+strand*3.7)*(5.0+3.0*sin(t*13.0-rig.phase*1.4))*sin(PI*t)
			var x := sin(t*TAU-0.8)*104.0+t*38.0+breath+zig
			var y := 158.0-t*364.0
			if strand==1:
				x = -124.0+t*156.0+sin(t*PI*1.4)*43.0+breath+zig
				y = 108.0-t*286.0+sin(t*17.0-rig.phase)*3.0
			elif strand==2:
				x = -106.0+t*222.0+sin(t*PI)*48.0+breath+zig*0.3
				y = 131.0-t*72.0+sin(t*PI)*36.0
			path.append(center+Vector2(x,y))
		paths.append(path)
	# Side currents follow the satellites while the upper forks stay attached.
	for side in [0,2]:
		var source: Vector2 = rig.parts[side]*Vector2(0,-30)
		var target: Vector2 = rig.parts[1]*Vector2(-29 if side==0 else 29,-66)
		var path := PackedVector2Array()
		var normal := (target-source).normalized().orthogonal()
		for step in range(17):
			var t := step/16.0
			path.append(source.lerp(target,t)+normal*sin(PI*t)*(18.0+11.0*sin(t*9.0-rig.phase*1.7+side)))
		paths.append(path)
	for branch in range(6):
		var source_path: PackedVector2Array = paths[branch%3]
		var junction := 7+branch*3
		var source: Vector2 = source_path[junction]
		var direction := -1.0 if branch%2==0 else 1.0
		var path := PackedVector2Array()
		for step in range(9):
			var t := step/8.0
			var bend := sin(t*7.0-rig.phase*1.9+branch)*3.5*sin(PI*t)
			path.append(source+Vector2(direction*(25.0+branch*4.0)*t+bend,-(23.0+branch*3.0)*t))
		paths.append(path)
	cache.lightning = paths
	return paths

static func _ribbon(path: PackedVector2Array, width: float, phase: float = 0.0) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	var reverse := PackedVector2Array()
	for index in range(path.size()):
		var t := index/float(path.size()-1)
		var tangent := path[mini(index+1,path.size()-1)]-path[maxi(0,index-1)]
		var normal := tangent.normalized().orthogonal()
		var taper := 0.09+0.91*pow(sin(PI*t),0.7)
		var extent := normal*width*taper*(0.78+0.22*sin(t*11.0-phase))
		polygon.append(path[index]+extent*(0.68+0.32*sin(t*17.0+phase*0.3)))
		reverse.append(path[index]-extent*(0.56+0.37*cos(t*9.0-phase*0.7)))
	reverse.reverse()
	polygon.append_array(reverse)
	return polygon

static func draw_lightning(rig: Node2D, foreground: bool = true, canvas: CanvasItem = null) -> void:
	var painter: CanvasItem = rig if canvas==null else canvas
	var violet := Color("a697ef").lerp(rig._tint,0.07)
	var paths := lightning_paths(rig)
	for index in range(paths.size()):
		if (index%3==1) != foreground: continue
		var path: PackedVector2Array = paths[index]
		var main := index<3
		var phase: float = rig.phase*1.7+index*1.3
		var strength: float = (0.75+0.12*sin(phase*0.62))*(0.86+maxf(0.0,rig.energy)*0.14)
		if main:
			painter.draw_colored_polygon(_ribbon(path,7.0 if foreground else 11.0,phase),Color(violet,0.14*strength))
			painter.draw_colored_polygon(_ribbon(path,3.2 if foreground else 4.5,phase+0.9),Color(violet.lightened(0.15),0.32*strength))
		for segment in range(path.size()-1):
			var t := (segment+0.5)/float(path.size()-1)
			var taper := 0.2+0.8*sin(PI*t)
			var traveling := 0.59+0.29*sin(t*12.0-phase)
			var alpha := strength*traveling*taper
			painter.draw_line(path[segment],path[segment+1],Color(violet,alpha*0.35),5.0 if main else 2.6,true)
			painter.draw_line(path[segment],path[segment+1],Color("e9dfff",alpha),taper*(1.65 if main else 0.95),true)
			if main and segment%4==0:
				painter.draw_line(path[segment],path[segment+1],Color("fff3d8",alpha*0.75),0.65,true)

static func snow_particle(rig: Node2D, index: int) -> Dictionary:
	var seed := float(index)
	var speed := 0.075+0.018*sin(seed*2.3)
	var age := fposmod(seed*0.61803398875+rig.phase*speed,1.0)
	var x := -153.0+306.0*fposmod(seed*0.754877666,1.0)
	x += sin(rig.phase*0.55+seed*2.4)*18.0+sin(age*TAU+seed)*10.0
	var radius := 2.2+4.1*fposmod(seed*0.41421356,1.0)
	return {"position":rig.parts[1].origin+Vector2(x,-177.0+330.0*age),
		"radius":radius,"angle":seed*1.7+rig.phase*(0.12+0.03*sin(seed)),
		"alpha":0.72*smoothstep(0.0,0.13,age)*(1.0-smoothstep(0.80,1.0,age)),
		"age":age,"lifetime":1.0/speed,"foreground":index%3==0,"shard":index%5==0}

static func snowflake_lines(center: Vector2, radius: float, angle: float, branches: bool) -> PackedVector2Array:
	var lines := PackedVector2Array()
	for arm in range(6):
		var axis := Vector2.from_angle(angle+TAU*arm/6.0)
		lines.append(center)
		lines.append(center+axis*radius)
		if branches:
			var junction := center+axis*radius*0.62
			for side in [-1.0,1.0]:
				lines.append(junction)
				lines.append(junction+axis.rotated(side*PI/3.0)*radius*0.29)
	return lines

static func snow_shard(particle: Dictionary) -> PackedVector2Array:
	var center: Vector2 = particle.position
	var axis: Vector2 = Vector2.from_angle(particle.angle)*particle.radius
	var across: Vector2 = axis.orthogonal()*0.32
	return PackedVector2Array([center-axis,center+across,center+axis,center-across])

static func mist_paths(rig: Node2D) -> Array[PackedVector2Array]:
	var cache := _geometry_cache(rig)
	if cache.has("mist"): return cache.mist
	var paths: Array[PackedVector2Array] = []
	for strand in range(2):
		var path := PackedVector2Array()
		for step in range(PATH_STEPS+1):
			var t := step/float(PATH_STEPS)
			var drift: float = sin(t*11.0-rig.phase*0.7+strand)*13.0*sin(PI*t)
			var x := sin(t*TAU-0.45)*112.0+t*30.0+drift
			var y := 151.0-t*350.0
			if strand==1:
				x = -113.0+sin(t*PI)*69.0-t*25.0+drift
				y = 124.0-t*283.0+sin(t*8.0+rig.phase*0.4)*8.0
			path.append(rig.parts[1].origin+Vector2(x,y))
		paths.append(path)
	cache.mist = paths
	return paths

static func frost_paths(rig: Node2D) -> Array[PackedVector2Array]:
	var cache := _geometry_cache(rig)
	if cache.has("frost"): return cache.frost
	var paths: Array[PackedVector2Array] = []
	var veins := [
		PackedVector2Array([Vector2(-8,-101),Vector2(-24,-72),Vector2(-23,-47),Vector2(-37,-25),Vector2(-32,-6)]),
		PackedVector2Array([Vector2(-24,-72),Vector2(-12,-67),Vector2(-9,-52)]),
		PackedVector2Array([Vector2(-23,-47),Vector2(-34,-45),Vector2(-38,-35)]),
		PackedVector2Array([Vector2(38,20),Vector2(23,44),Vector2(21,66),Vector2(7,97)]),
		PackedVector2Array([Vector2(23,44),Vector2(10,40),Vector2(7,28)]),
		PackedVector2Array([Vector2(21,66),Vector2(30,61),Vector2(34,49)])]
	for index in range(veins.size()):
		var vein: PackedVector2Array = veins[index]
		var amount: float = 0.68+0.22*sin(rig.phase*0.65-index*0.57)
		var path := PackedVector2Array()
		for vertex in range(vein.size()):
			var reached := clampf(amount*(vein.size()-1)-vertex+1,0.0,1.0) if vertex>0 else 1.0
			var point := vein[maxi(0,vertex-1)].lerp(vein[vertex],reached)
			path.append(rig.parts[1]*point)
		paths.append(path)
	for part in [0,2]:
		paths.append(rig.parts[part]*PackedVector2Array([Vector2(-7,-32),Vector2(2,-17),Vector2(-4,-4),Vector2(3,10)]))
	cache.frost = paths
	return paths

static func frost_polygons(rig: Node2D) -> Array[PackedVector2Array]:
	var patches: Array[PackedVector2Array] = []
	for part in range(3):
		var amount: float = 0.78+0.16*sin(rig.phase*0.55+part*1.8)
		var points := PackedVector2Array([Vector2(0,-116),Vector2(13,-89),Vector2(5,-94),Vector2(1,-84),Vector2(-4,-96),Vector2(-10,-94)]) if part==1 else PackedVector2Array([Vector2(-9,-39),Vector2(6,-23),Vector2(-1,-27),Vector2(-4,-18),Vector2(-12,-25)])
		for vertex in range(1,points.size()): points[vertex] = points[0].lerp(points[vertex],amount)
		patches.append(rig.parts[part]*points)
	return patches

static func draw_snow(rig: Node2D, foreground: bool = true, canvas: CanvasItem = null) -> void:
	var painter: CanvasItem = rig if canvas==null else canvas
	var ice := Color("e7faff").lerp(rig._tint,0.035)
	var paths := mist_paths(rig)
	for index in range(paths.size()):
		if (index==1) != foreground: continue
		var path: PackedVector2Array = paths[index]
		var phase: float = rig.phase*0.9+index*1.7
		painter.draw_colored_polygon(_ribbon(path,8.0 if foreground else 12.0,phase),Color("94cfe2",0.13 if foreground else 0.19))
		painter.draw_colored_polygon(_ribbon(path,3.1 if foreground else 4.5,phase+1.4),Color(ice,0.17 if foreground else 0.26))
		for segment in range(path.size()-1):
			var alpha := (0.12+0.12*sin(segment*0.38-phase))*sin(PI*(segment+0.5)/(path.size()-1))
			painter.draw_line(path[segment],path[segment+1],Color(ice,alpha),0.8,true)
	if foreground:
		for patch in frost_polygons(rig): painter.draw_colored_polygon(patch,Color(ice,0.73))
		var veins := frost_paths(rig)
		for index in range(veins.size()):
			var alpha: float = 0.55+0.14*sin(rig.phase*0.65-index*0.57)
			painter.draw_polyline(veins[index],Color("8ed6f1",alpha*0.35),3.0,true)
			painter.draw_polyline(veins[index],Color(ice,alpha),0.95,true)
	for index in range(FLAKE_COUNT):
		var particle := snow_particle(rig,index)
		if particle.foreground != foreground: continue
		var alpha: float = particle.alpha*(0.9 if foreground else 0.48)
		if particle.shard:
			var shard := snow_shard(particle)
			painter.draw_polygon(shard,PackedColorArray([Color(ice,alpha*0.12),Color(ice,alpha*0.85),Color(ice,alpha*0.3),Color("84bfdc",alpha*0.48)]))
			painter.draw_line(shard[0],shard[2],Color(ice,alpha*0.85),0.7,true)
		else:
			painter.draw_multiline(snowflake_lines(particle.position,particle.radius,particle.angle,index%4==0),Color(ice,alpha),0.85 if foreground else 0.65,true)

static func _circle(center: Vector2, radius: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for vertex in range(13): polygon.append(center+Vector2.from_angle(0.17+TAU*vertex/13.0)*radius)
	return polygon

static func _path_regions(result: Array[PackedVector2Array], path: PackedVector2Array, radius: float) -> void:
	# One narrow outline per strand keeps native mask unions cheap and gaps open.
	var unique := PackedVector2Array()
	for point in path:
		if unique.is_empty() or point.distance_squared_to(unique[-1])>0.001: unique.append(point)
	if unique.size()<2: return
	var polygon := PackedVector2Array()
	var reverse := PackedVector2Array()
	for index in range(unique.size()):
		var point := unique[index]
		var direction := (unique[mini(index+1,unique.size()-1)]-unique[maxi(index-1,0)]).normalized()
		if index==0: point -= direction*radius
		if index==unique.size()-1: point += direction*radius
		var normal := direction.orthogonal()*radius
		if index>0 and index<unique.size()-1:
			var outgoing := (unique[index+1]-unique[index]).normalized().orthogonal()
			normal /= maxf(absf(direction.orthogonal().dot(outgoing)),0.3)
		polygon.append(point+normal)
		reverse.append(point-normal)
	reverse.reverse()
	polygon.append_array(reverse)
	result.append(polygon)

static func regions(rig: Node2D, style: String) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if style=="lightning":
		var paths := lightning_paths(rig)
		for index in range(paths.size()):
			_path_regions(result,paths[index],4.0)
			if index<3: result.append(_ribbon(paths[index],8.5 if index%3==1 else 12.5,rig.phase*1.7+index*1.3))
	elif style=="snow":
		var mist := mist_paths(rig)
		for index in range(mist.size()):
			_path_regions(result,mist[index],2.0)
			result.append(_ribbon(mist[index],9.5 if index==1 else 13.5,rig.phase*0.9+index*1.7))
		for path in frost_paths(rig): _path_regions(result,path,2.0)
		for patch in frost_polygons(rig):
			var bounds := Rect2(patch[0],Vector2.ZERO)
			for point in patch: bounds = bounds.expand(point)
			bounds = bounds.grow(1.0)
			result.append(PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]))
		for index in range(FLAKE_COUNT):
			var particle := snow_particle(rig,index)
			if particle.alpha>0.0001: result.append(_circle(particle.position,particle.radius+1.5))
	return result
