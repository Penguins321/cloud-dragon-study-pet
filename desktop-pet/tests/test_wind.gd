extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var rig = load("res://pet/skins/cloud_dragon/view.tscn").instantiate()
	tree.root.add_child(rig)
	rig.swim_strength = 1.0
	check.call(rig.JOINTS.size() >= 26 and rig.JOINTS[18][1] == 9 and rig.JOINTS[22][1] == 9, "both whisker chains branch from the skull")
	var right: Array[Vector2] = []
	var left: Array[Vector2] = []
	var attached := true
	var smooth := true
	for step in range(65):
		rig.phase = TAU * step / 64.0
		rig.sync_pose()
		var head_inverse: Transform2D = rig.skin_matrices[9].affine_inverse()
		right.append(head_inverse * rig.deform_point(Vector2(433, 100)))
		left.append(head_inverse * rig.deform_point(Vector2(315, 87)))
		for root in [Vector2(411, 53), Vector2(376, 49)]:
			attached = attached and (head_inverse * rig.deform_point(root)).distance_to(root) < 0.6
		if step > 0:
			smooth = smooth and right[step].distance_to(right[step - 1]) < 5.0 and left[step].distance_to(left[step - 1]) < 5.0
	check.call(_span(right) > 8.0, "right whisker waves independently of the skull")
	check.call(_span(left) > 5.0, "left whisker waves independently of the skull")
	check.call(attached, "whisker roots stay attached to the face")
	check.call(smooth, "wind follow-through has no abrupt frame jumps")
	check.call(right[0].distance_to(right[-1]) < 0.001 and left[0].distance_to(left[-1]) < 0.001, "wind phase wraps seamlessly")
	rig.free()

static func _span(points: Array[Vector2]) -> float:
	var result := 0.0
	for a in points:
		for b in points:
			result = maxf(result, a.distance_to(b))
	return result
