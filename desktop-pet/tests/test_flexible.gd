extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	view.apply_skin(load("res://pet/skins/cloud_dragon/skin.tres"))
	check.call(view.has_method("cycle_action"), "left-click action cycle is supported by pet module")
	check.call(view.actor.has_method("deform_point"), "dragon supports joint deformation rather than only root motion")
	if not view.has_method("cycle_action") or not view.actor.has_method("deform_point"):
		view.free()
		return
	var actions: Array[StringName] = []
	for i in range(5):
		actions.append(view.cycle_action())
	check.call(actions == [&"swim", &"look", &"stretch", &"rest", &"celebrate"], "click cycles five different actions")
	check.call(view.cycle_action() == &"swim", "action cycle wraps after celebration")
	view.select_action(&"look")
	check.call(view.cycle_action() == &"stretch", "click continues after an explicitly selected pose")
	view.play_action(&"dragging")
	view.cycle_action()
	check.call(view.current_action == &"dragging", "dragging does not switch pose")
	view.play_action(&"idle")
	view.select_action(&"swim")
	view.player.advance(0.4)
	var rig = view.actor
	var tail := Vector2(32, 70)
	var shoulder := Vector2(331, 115)
	rig.phase = 0.0
	rig.sync_pose()
	var first: Vector2 = rig.deform_point(tail) - rig.deform_point(shoulder)
	rig.phase = PI
	rig.sync_pose()
	var second: Vector2 = rig.deform_point(tail) - rig.deform_point(shoulder)
	check.call(first.distance_to(second) > 30.0, "tail moves substantially relative to shoulder instead of moving the entire image")
	check.call(rig.JOINTS[10][1] == 0 and rig.JOINTS[12][1] == 0 and rig.JOINTS[14][1] == 3 and rig.JOINTS[16][1] == 3, "four limbs remain attached to shoulder and pelvis")
	var bad_lengths := 0
	var bad_weights := 0
	var flips := 0
	var clipped := 0
	var deformed_faces := 0
	var image: Image = rig.get_node("Illustration").texture.get_image()
	for binding in rig.vertex_bindings:
		var total := 0.0
		for value in binding[1]:
			total += value
		if absf(total - 1.0) > 0.0001 or binding[0].size() > 4:
			bad_weights += 1
	var visible := _visible_triangles(rig, image)
	var stats: Array[int] = [0, 0, 0, 0]
	for action in [&"swim", &"look", &"stretch", &"rest", &"celebrate"]:
		view.select_action(action)
		view.player.advance(0.4)
		view.player.advance(0.0)
		for moment in [0.0, 0.125, 0.25, 0.5, 0.75, 0.875, 0.999]:
			view.player.seek(view.player.current_animation_length * moment, true)
			for step in range(16):
				rig.phase = TAU * step / 16.0
				rig.sync_pose()
				_measure_pose(view, visible, stats)
	# Also inspect actual crossfade frames, not just positions within a single clip.
	for action in [&"swim", &"rest", &"stretch", &"look", &"celebrate"]:
		view.select_action(action)
		for frame in range(18):
			view._process(1.0 / 60.0)
			_measure_pose(view, visible, stats)
	bad_lengths = stats[0]
	flips = stats[1]
	clipped = stats[2]
	deformed_faces = stats[3]
	check.call(bad_lengths == 0, "bone lengths stay fixed across poses and phases")
	check.call(bad_weights == 0, "mesh weights are normalized and match GPU four-influence limit")
	check.call(flips == 0, "visible mesh triangles never turn inside out; flips=%d" % flips)
	check.call(clipped == 0, "all tested joint poses fit the stable window bounds")
	check.call(deformed_faces == 0, "face proportions stay rigid during joint animation")
	view.select_action(&"swim")
	view.player.advance(0.5)
	view.player.advance(0.0)
	view.get_visual_geometry()
	var before_switch: Vector2 = view.map_skin_point(tail)
	view.select_action(&"rest")
	view.player.advance(0.0)
	view.get_visual_geometry()
	check.call(before_switch.distance_to(view.map_skin_point(tail)) < 0.001, "joint action switch starts at the current pose without a jump")
	view._process(1.0 / 60.0)
	check.call(before_switch.distance_to(view.map_skin_point(tail)) < 5.0, "joint transition has bounded first-frame movement")
	view.free()

static func _visible_triangles(rig: Node2D, image: Image) -> Array[PackedInt32Array]:
	# Mark every triangle touched by any visible source pixel, including thin whiskers.
	image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	var occupied: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			if pixels[(y * image.get_width() + x) * 4 + 3] < 13:
				continue
			var grid := (Vector2(x, y) + Vector2(0.5, 0.5)) / Vector2(image.get_size()) * Vector2(rig.COLUMNS, rig.ROWS)
			var gx := int(grid.x)
			var gy := int(grid.y)
			var offset := 1 if grid.x - gx + grid.y - gy > 1.0 else 0
			occupied[(gy * rig.COLUMNS + gx) * 2 + offset] = true
	var result: Array[PackedInt32Array] = []
	var polygons: Array = rig.get_node("Illustration").polygons
	for index in occupied:
		result.append(polygons[index])
	return result

static func _measure_pose(view: Node2D, visible: Array[PackedInt32Array], stats: Array[int]) -> void:
	var rig = view.actor
	var face_a: Vector2 = rig.deform_point(Vector2(385, 35))
	var face_b: Vector2 = rig.deform_point(Vector2(397, 45))
	if absf(face_a.distance_to(face_b) - Vector2(12, 10).length()) > 0.05:
		stats[3] += 1
	for index in range(1, rig.JOINTS.size()):
		var parent: int = rig.JOINTS[index][1]
		var expected: float = Vector2(rig.JOINTS[index][2]).distance_to(rig.JOINTS[parent][2])
		var actual: float = rig.joint_globals[index].origin.distance_to(rig.joint_globals[parent].origin)
		if absf(expected - actual) > 0.001:
			stats[0] += 1
	for triangle in visible:
		var a: Vector2 = rig.deform_point(rig.vertices[triangle[0]])
		var b: Vector2 = rig.deform_point(rig.vertices[triangle[1]])
		var c: Vector2 = rig.deform_point(rig.vertices[triangle[2]])
		for point in [a, b, c]:
			if not view.skin.visual_bounds.has_point(rig.transform * point):
				stats[2] += 1
		if (b - a).cross(c - a) <= 0.01:
			stats[1] += 1
