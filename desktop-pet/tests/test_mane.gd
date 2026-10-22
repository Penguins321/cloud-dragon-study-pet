extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var rig = load("res://pet/skins/jade_dragon/view.tscn").instantiate()
	tree.root.add_child(rig)
	check.call(rig.JOINTS.size() >= 46, "jade mane has independent neck, shoulder, waist, hip and tail bundles")
	if rig.JOINTS.size() < 46:
		rig.free()
		return
	var parents := [8,1,2,3,4]
	var attached := true
	for bundle in range(5):
		attached = attached and rig.JOINTS[36+bundle*2][1] == parents[bundle] and rig.JOINTS[37+bundle*2][1] == 36+bundle*2
	check.call(attached, "each mane root follows its own anatomical attachment")
	rig.swim_strength = 1.0
	var minimum := [INF,INF,INF,INF,INF]
	var maximum := [-INF,-INF,-INF,-INF,-INF]
	var differences := [0.0,0.0,0.0,0.0]
	for step in range(32):
		rig.phase = TAU*step/32.0
		rig.sync_pose()
		for bundle in range(5):
			var angle: float = rig.bones[37+bundle*2].rotation
			minimum[bundle] = minf(minimum[bundle],angle)
			maximum[bundle] = maxf(maximum[bundle],angle)
			if bundle > 0:
				differences[bundle-1] = maxf(differences[bundle-1],absf(angle-rig.bones[35+bundle*2].rotation))
	var moving := true
	var independent := true
	for bundle in range(5):
		moving = moving and maximum[bundle]-minimum[bundle] > deg_to_rad(2.0)
	for difference in differences:
		independent = independent and difference > deg_to_rad(0.5)
	check.call(moving, "all five mane tips bend relative to their own roots")
	check.call(independent, "neighboring mane bundles have different phases instead of moving as one fan")
	rig.free()
