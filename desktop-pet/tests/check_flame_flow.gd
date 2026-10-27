extends SceneTree

var failures := 0
var diagnostic := ""
var diagnostic_count := 0

func check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ", message)
	if not ok: failures += 1

func _initialize() -> void:
	if not FileAccess.file_exists("res://pet/flame_flow.gd"):
		check(false,"live brush flame flow helper exists")
		quit(failures)
		return
	var flow = load("res://pet/flame_flow.gd")
	if not flow.has_method("strip_indices"):
		check(false,"flames use explicit cached triangle strip indices")
		quit(failures)
		return
	if not flow.has_method("wisp_paths"):
		check(false,"curling paint wisps travel independently along the main flame")
		quit(failures)
		return
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	rig.set_appearance("flame","amber")
	var young_count: int = flow.ember_particles(rig).size()
	rig.set_growth(1.0)
	check(flow.ember_particles(rig).size() > young_count,"growth gradually adds actual moving embers")
	var player: AnimationPlayer = rig.get_node("AnimationPlayer")
	root.add_child(rig)
	var finite := true
	var bounded := true
	var covered := true
	var continuous := true
	var flowing := false
	var exposed := true
	var both_layers := false
	var strips_valid := true
	var few_regions := true
	var ceiling := Rect2(-100,-360,650,750)
	for action in ["float","jump","dance","roll"]:
		player.play(action)
		for sample in range(25):
			player.seek(player.current_animation_length*sample/24.0,true)
			rig.phase = sample*0.239
			rig.sync_pose()
			diagnostic = action+" "+str(sample)+" origin "+str(rig.parts[1].origin)
			var paths: Array = flow.paths(rig)+flow.wisp_paths(rig)
			var regions: Array = flow.regions(rig)
			few_regions = few_regions and regions.size() <= 10
			var behind := false
			var front := false
			for path in paths:
				if path.get("alpha",1.0) <= 0.001: continue
				var painted: PackedVector2Array = flow._outline(path,1.0,2.0 if path.has("age") else 4.0)
				var indices: PackedInt32Array = flow.strip_indices(path.points.size())
				strips_valid = strips_valid and indices.size() == (path.points.size()-1)*6
				for vertex in indices: strips_valid = strips_valid and vertex >= 0 and vertex < painted.size()
				for p in painted: covered = covered and _covered(p,regions)
				behind = behind or not path.foreground
				front = front or path.foreground
				for i in path.points.size():
					var p: Vector2 = path.points[i]
					var width: float = path.widths[i]
					finite = finite and p.is_finite() and is_finite(width) and width >= 0.0
					bounded = bounded and ceiling.has_point(p-Vector2.ONE*(width+3)) and ceiling.has_point(p+Vector2.ONE*(width+3))
					covered = covered and _covered(p,regions)
				# Foreground flames may cross the foot, but leave the core hub exposed.
				if path.foreground:
					for p in path.points:
						exposed = exposed and p.distance_to(rig.parts[1].origin) > 35.0
			both_layers = both_layers or (behind and front)
			for ember in flow.ember_particles(rig):
				if ember.alpha <= 0.001: continue
				for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
					covered = covered and _covered(ember.position+direction*6.0,regions)
				covered = covered and _covered(ember.tail,regions)
			for region in regions:
				for p in region:
					finite = finite and p.is_finite()
					bounded = bounded and ceiling.has_point(p)
			rig.phase += 1.0/240.0
			var next: Array = flow.paths(rig)+flow.wisp_paths(rig)
			for j in paths.size():
				if minf(paths[j].get("alpha",1.0),next[j].get("alpha",1.0)) < 0.02: continue
				for i in paths[j].points.size():
					continuous = continuous and paths[j].points[i].distance_to(next[j].points[i]) < 2.0
			rig.phase += 1.0
			var later: Array = flow.paths(rig)+flow.wisp_paths(rig)
			var travel := 0.0
			for j in paths.size():
				for i in paths[j].points.size():
					travel += paths[j].points[i].distance_to(later[j].points[i])
			flowing = flowing or travel > 300.0
	check(finite,"ribbons and regions contain finite geometry")
	check(bounded,"flow and glows fit native window budget across jump/dance/roll")
	check(covered,"native regions cover ribbon paint, glow pads and moving ember streaks")
	check(strips_valid,"explicit ribbon strip indices remain finite and within paint vertices")
	check(few_regions,"three ellipse fields avoid per-ribbon native mask booleans")
	check(continuous,"1/240 second step has no ribbon position discontinuity")
	check(flowing,"one second advects ribbon geometry visibly")
	check(exposed and both_layers,"foreground wraps the feet while the crystal hub remains exposed")
	var wraps_fade := true
	for index in range(flow.EMBER_COUNT):
		rig.phase = (4.0-index*0.61803398875)/(0.20+float(index%4)*0.021)
		var ember: Dictionary = flow.ember_particles(rig)[index]
		wraps_fade = wraps_fade and ember.alpha < 0.0001
	check(wraps_fade,"embers fade to zero at lifetime wrap")
	var wisps_fade := true
	for index in range(flow.WISP_COUNT):
		rig.phase = (4.0-index*0.271828)/(0.22+index*0.017)
		wisps_fade = wisps_fade and flow.wisp_paths(rig)[index].alpha < 0.0001
	check(wisps_fade,"curling wisps fade invisibly before their advected lifetime wraps")
	var paint_valid := true
	var stress_covered := true
	for frame in range(3000):
		rig.phase = (frame+1)/30.0
		diagnostic = "stress "+str(frame)+" origin "+str(rig.parts[1].origin)
		var fields: Array = flow.regions(rig)
		for path in flow.paths(rig)+flow.wisp_paths(rig):
			if path.get("alpha",1.0) <= 0.001: continue
			for layer in [[1.0,2.0 if path.has("age") else 4.0,0.0],[0.8,0.0,0.0],[0.2,0.0,-0.22]]:
				for vertex in flow._outline(path,layer[0],layer[1],layer[2]):
					paint_valid = paint_valid and vertex.is_finite()
					stress_covered = stress_covered and _covered(vertex,fields)
	check(paint_valid and stress_covered,"3000 max-growth phases keep every strip vertex finite and inside native fields")
	var retained_covered := true
	for sample in range(200):
		rig.phase = sample*0.137
		rig.sync_pose()
		var retained: Array = flow.ember_particles(rig)
		rig.phase += 1.0/30.0
		rig.sync_pose()
		var current_masks: Array = flow.regions(rig)
		for ember in retained:
			if ember.alpha <= 0.01: continue
			for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
				retained_covered = retained_covered and _covered(ember.position+direction*6.0,current_masks)
			retained_covered = retained_covered and _covered(ember.tail,current_masks)
	check(retained_covered,"current masks retain visible ember halos from the previous 1/30 second")
	if OS.get_cmdline_user_args().has("--native-stress"):
		for frame in range(600):
			rig.advance_pose(1.0/30.0)
			await process_frame
			await RenderingServer.frame_post_draw
		print("NATIVE_FLAME_STRESS 600 max-growth frames")
	# Let the actual rig draw in a viewport as well as checking its geometry.
	await process_frame
	await process_frame
	rig.free()
	quit(failures)

func _covered(point: Vector2, regions: Array) -> bool:
	for region in regions:
		if Geometry2D.is_point_in_polygon(point,region): return true
		# All flame mask fields are convex. Avoid the ray-cast predicate's rare
		# vertex-alignment false negative over millions of sampled paint points.
		var positive := false
		var negative := false
		for index in region.size():
			var edge: Vector2 = region[(index+1)%region.size()]-region[index]
			var cross: float = edge.cross(point-region[index])
			positive = positive or cross > 0.001
			negative = negative or cross < -0.001
			if positive and negative: break
		if not (positive and negative): return true
	if diagnostic_count < 5: print("UNCOVERED ",diagnostic," point ",point," ellipse ",[regions[0][0],regions[0][12],regions[0][24],regions[0][36]])
	diagnostic_count += 1
	return false
