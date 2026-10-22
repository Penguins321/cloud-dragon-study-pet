extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var rig = load("res://pet/skins/cloud_dragon/view.tscn").instantiate()
	tree.root.add_child(rig)
	check.call(rig.JOINTS.size() >= 36, "tail has intermediate joints and flame has independent tongues")
	if rig.JOINTS.size() < 36:
		rig.free()
		return
	var chain := [4, 34, 5, 35, 6, 7]
	var connected := true
	for segment in range(1, chain.size()):
		connected = connected and rig.JOINTS[chain[segment]][1] == chain[segment - 1]
	check.call(connected, "tail bend propagates through one continuous parent-child chain")
	rig.swim_strength = 1.0
	var peaks := [-INF, -INF, -INF, -INF, -INF]
	var peak_phases := [0.0, 0.0, 0.0, 0.0, 0.0]
	var center: Array[Vector2] = []
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	var left_relative: Array[Vector2] = []
	var right_relative: Array[Vector2] = []
	for step in range(64):
		rig.phase = TAU * step / 64.0
		rig.sync_pose()
		for segment in range(5):
			var angle: float = rig.bones[chain[segment]].rotation
			if angle > peaks[segment]:
				peaks[segment] = angle
				peak_phases[segment] = rig.phase
		var base_inverse: Transform2D = rig.skin_matrices[7].affine_inverse()
		center.append(base_inverse * rig.deform_point(Vector2(34, 34)))
		left.append(base_inverse * rig.deform_point(Vector2(12, 55)))
		right.append(base_inverse * rig.deform_point(Vector2(49, 59)))
		var body_inverse: Transform2D = rig.skin_matrices[28].affine_inverse()
		left_relative.append(body_inverse * rig.deform_point(Vector2(12, 55)))
		right_relative.append(body_inverse * rig.deform_point(Vector2(49, 59)))
	var delayed := true
	for segment in range(1, 5):
		var lag: float = peak_phases[segment] - peak_phases[segment - 1]
		delayed = delayed and lag > 0.0 and lag < 1.0
	check.call(delayed, "tail bend peaks travel from root toward tip with a bounded delay")
	var span = load("res://tests/test_wind.gd")
	check.call(span._span(center) > 4.0, "flame center bends relative to its attached base")
	check.call(span._span(left) > 2.0 and span._span(right) > 2.0, "side flame tongues move separately from the flame base")
	check.call(span._span(left_relative) > 1.0 and span._span(right_relative) > 1.0, "flame tongues also bend relative to the moving flame body")
	rig.free()
