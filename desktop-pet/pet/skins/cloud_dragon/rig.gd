extends Node2D

# Side-view bind pose: shoulder -> spine -> pelvis -> tail; neck and four limbs branch.
# Coordinates, weights and animations are independent of texture color.
var SIZE := Vector2(440.0, 178.86179)
const COLUMNS := 55
const ROWS := 30
var JOINTS := [
	["Shoulder", -1, Vector2(331, 115)],
	["SpineChest", 0, Vector2(280, 122)],
	["SpineWaist", 1, Vector2(235, 102)],
	["Pelvis", 2, Vector2(190, 105)],
	["TailRoot", 3, Vector2(137, 123)],
	["TailMiddle", 34, Vector2(80, 125)],
	["TailTip", 35, Vector2(32, 86)],
	["TailFlame", 6, Vector2(29, 80)],
	["Neck", 0, Vector2(348, 81)],
	["Head", 8, Vector2(384, 41)],
	["FrontNearUpper", 0, Vector2(339, 124)],
	["FrontNearLower", 10, Vector2(350, 147)],
	["FrontFarUpper", 0, Vector2(365, 121)],
	["FrontFarLower", 12, Vector2(383, 139)],
	["HindNearUpper", 3, Vector2(181, 115)],
	["HindNearLower", 14, Vector2(155, 144)],
	["HindFarUpper", 3, Vector2(201, 118)],
	["HindFarLower", 16, Vector2(194, 147)],
	["RightWhiskerRoot", 9, Vector2(411, 53)],
	["RightWhiskerMiddle", 18, Vector2(427, 63)],
	["RightWhiskerLower", 19, Vector2(423, 79)],
	["RightWhiskerTip", 20, Vector2(434, 96)],
	["LeftWhiskerRoot", 9, Vector2(376, 49)],
	["LeftWhiskerMiddle", 22, Vector2(354, 54)],
	["LeftWhiskerLower", 23, Vector2(337, 71)],
	["LeftWhiskerTip", 24, Vector2(316, 88)],
	["ManeRoot", 9, Vector2(362, 36)],
	["ManeTip", 26, Vector2(333, 43)],
	["FlameMiddle", 7, Vector2(31, 62)],
	["FlameTip", 28, Vector2(34, 40)],
	["FlameLeft", 28, Vector2(21, 64)],
	["FlameLeftTip", 30, Vector2(12, 52)],
	["FlameRight", 28, Vector2(43, 65)],
	["FlameRightTip", 32, Vector2(49, 57)],
	["TailInner", 4, Vector2(110, 127)],
	["TailOuter", 5, Vector2(55, 113)]
]
var limb_tips := [Vector2(370, 170), Vector2(391, 151), Vector2(145, 162), Vector2(204, 162)]
var face_landmarks := [Vector2(385, 35), Vector2(397, 45)]
var whisker_gain := 1.0
var neck_gain := 1.0

@export var swim_strength := 0.0
@export var swim_speed := 2.0
@export var neck_lift := 0.0
@export var leg_fold := 0.0
@export var tail_curl := 0.0
@export var stretch := 0.0
var phase := 0.0
var bones: Array[Bone2D] = []
var skin_matrices: Array[Transform2D] = []
var joint_globals: Array[Transform2D] = []
var vertices := PackedVector2Array()
var vertex_bindings: Array = []
var _deformed_vertices: Dictionary = {}
var _last_pose := PackedFloat64Array()
var _bone_order: Array[int] = []
var _flame_material: ShaderMaterial

func _ready() -> void:
	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	for joint in JOINTS:
		var bone := Bone2D.new()
		bone.name = joint[0]
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(20.0)
		var parent_index: int = joint[1]
		var parent_point := Vector2.ZERO if parent_index < 0 else Vector2(JOINTS[parent_index][2])
		bone.position = Vector2(joint[2]) - parent_point
		bone.rest = bone.transform
		bones.append(bone)
	# Stable IDs are retained as intermediate joints are added; parents may have later IDs.
	for index in JOINTS.size():
		_order_joint(index)
	for index in _bone_order:
		var parent: int = JOINTS[index][1]
		if parent < 0:
			skeleton.add_child(bones[index])
		else:
			bones[parent].add_child(bones[index])
	_flame_material = ShaderMaterial.new()
	_flame_material.shader = preload("res://pet/skins/cloud_dragon/flame.gdshader")
	get_node("Illustration").material = _flame_material
	_build_mesh(skeleton)
	sync_pose()

func _order_joint(index: int) -> void:
	if index in _bone_order:
		return
	var parent: int = JOINTS[index][1]
	if parent >= 0:
		_order_joint(parent)
	_bone_order.append(index)

func _build_mesh(skeleton: Skeleton2D) -> void:
	var illustration: Polygon2D = get_node("Illustration")
	var uv := PackedVector2Array()
	var faces: Array[PackedInt32Array] = []
	var all_weights: Array[PackedFloat32Array] = []
	for bone in bones:
		all_weights.append(PackedFloat32Array())
	for y in range(ROWS + 1):
		for x in range(COLUMNS + 1):
			var point := SIZE * Vector2(float(x) / COLUMNS, float(y) / ROWS)
			vertices.append(point)
			uv.append(point / SIZE * Vector2(illustration.texture.get_size()))
			var weights := _weights(point)
			var indices := PackedInt32Array()
			var values := PackedFloat32Array()
			for index in bones.size():
				all_weights[index].append(weights[index])
				if weights[index] > 0.0:
					indices.append(index)
					values.append(weights[index])
			vertex_bindings.append([indices, values])
	for y in ROWS:
		for x in COLUMNS:
			var a := y * (COLUMNS + 1) + x
			var b := a + 1
			var c := a + COLUMNS + 1
			faces.append(PackedInt32Array([a, b, c]))
			faces.append(PackedInt32Array([b, c + 1, c]))
	illustration.polygon = vertices
	illustration.uv = uv
	illustration.polygons = faces
	illustration.skeleton = illustration.get_path_to(skeleton)
	for index in bones.size():
		illustration.add_bone(skeleton.get_path_to(bones[index]), all_weights[index])

func _weights(point: Vector2) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(JOINTS.size())
	# Continuous spine influence; the face is handled separately as a rigid region.
	var chain := [6, 35, 5, 34, 4, 3, 2, 1, 0]
	if point.x <= 32.0:
		weights[6] = 1.0
	elif point.x >= 331.0:
		weights[0] = 1.0
	else:
		for index in range(chain.size() - 1):
			var left: int = chain[index]
			var right: int = chain[index + 1]
			var low: float = JOINTS[left][2].x
			var high: float = JOINTS[right][2].x
			if point.x >= low and point.x <= high:
				var blend := (point.x - low) / (high - low)
				weights[left] = 1.0 - blend
				weights[right] = blend
				break
	if point.x < 58.0:
		_mix(weights, 7, 1.0 - smoothstep(55.0, 85.0, point.y))
	# Shoulder to neck transition, then a rigid skull/face region.
	var neck := smoothstep(300.0, 352.0, point.x) * (1.0 - smoothstep(98.0, 135.0, point.y))
	_mix(weights, 8, neck)
	var head := smoothstep(333.0, 370.0, point.x) * (1.0 - smoothstep(63.0, 105.0, point.y))
	if point.x > 405.0:
		head = 1.0
	_mix(weights, 9, head)
	# Anatomical distance fields keep tail edges on the spine and toes on their limbs.
	# Rectangular limb masks can pull adjacent tail pixels into a leg and invert triangles.
	_paint_limbs(weights, point, chain)
	_paint_wind(weights, point)
	_paint_flame(weights, point)
	# Polygon2D uses the strongest four influences. Normalize that same set for CPU mapping.
	var order: Array[int] = []
	for index in weights.size():
		if weights[index] > 0.0:
			order.append(index)
	order.sort_custom(func(a: int, b: int): return weights[a] > weights[b])
	for index in range(4, order.size()):
		weights[order[index]] = 0.0
	var total := 0.0
	for value in weights:
		total += value
	for index in weights.size():
		weights[index] /= total
	return weights

func _paint_flame(weights: PackedFloat32Array, point: Vector2) -> void:
	var mask := (1.0 - smoothstep(54.0, 62.0, point.x)) * (1.0 - smoothstep(75.0, 86.0, point.y))
	_paint_chain(weights, -point.y, [7, 28, 29], [-80.0, -62.0, -40.0], mask)
	var left := mask * (1.0 - smoothstep(18.0, 30.0, point.x))
	_paint_chain(weights, -point.y, [30, 31], [-64.0, -52.0], left)
	var right := mask * smoothstep(35.0, 47.0, point.x)
	_paint_chain(weights, -point.y, [32, 33], [-65.0, -57.0], right)

func _paint_wind(weights: PackedFloat32Array, point: Vector2) -> void:
	# These fields follow the bind drawing, excluding eyes, muzzle and whisker roots.
	var mane := smoothstep(306.0, 330.0, point.x) * (1.0 - smoothstep(335.0, 350.0, point.x)) * (1.0 - smoothstep(48.0, 74.0, point.y))
	_mix(weights, 27, mane)
	var right := smoothstep(407.0, 418.0, point.x) * smoothstep(53.0, 62.0, point.y)
	_paint_chain(weights, point.y, [18, 19, 20, 21], [53.0, 63.0, 79.0, 96.0], right)
	var left := (1.0 - smoothstep(350.0, 373.0, point.x)) * smoothstep(46.0, 58.0, point.y) * (1.0 - smoothstep(80.0, 112.0, point.y)) * smoothstep(298.0, 315.0, point.x)
	_paint_chain(weights, -point.x, [22, 23, 24, 25], [-376.0, -354.0, -337.0, -316.0], left)

func _paint_chain(weights: PackedFloat32Array, coordinate: float, indices: Array, positions: Array, amount: float) -> void:
	if amount <= 0.0:
		return
	for index in weights.size():
		weights[index] *= 1.0 - amount
	if coordinate <= positions[0]:
		weights[indices[0]] += amount
		return
	for segment in range(indices.size() - 1):
		if coordinate <= positions[segment + 1]:
			var blend: float = inverse_lerp(positions[segment], positions[segment + 1], coordinate)
			weights[indices[segment]] += amount * (1.0 - blend)
			weights[indices[segment + 1]] += amount * blend
			return
	weights[indices[-1]] += amount

func _mix(weights: PackedFloat32Array, bone: int, amount: float) -> void:
	for index in weights.size():
		weights[index] *= 1.0 - amount
	weights[bone] += amount

func _paint_limbs(weights: PackedFloat32Array, point: Vector2, chain: Array) -> void:
	var body_distance := INF
	for index in range(chain.size() - 1):
		var nearest := Geometry2D.get_closest_point_to_segment(point, JOINTS[chain[index]][2], JOINTS[chain[index + 1]][2])
		body_distance = minf(body_distance, point.distance_to(nearest))
	var body_score := pow(6.0 / (6.0 + body_distance), 4.0)
	var scores := PackedFloat32Array()
	scores.resize(JOINTS.size())
	var total := body_score
	var limbs := [[10, 11, limb_tips[0]], [12, 13, limb_tips[1]], [14, 15, limb_tips[2]], [16, 17, limb_tips[3]]]
	for limb in limbs:
		var upper: int = limb[0]
		var lower: int = limb[1]
		var root: Vector2 = JOINTS[upper][2]
		var elbow: Vector2 = JOINTS[lower][2]
		var end: Vector2 = limb[2]
		var gate := smoothstep(110.0 if upper >= 14 else 118.0, 142.0, point.y)
		var upper_distance := point.distance_to(Geometry2D.get_closest_point_to_segment(point, root, elbow))
		var lower_distance := point.distance_to(Geometry2D.get_closest_point_to_segment(point, elbow, end))
		scores[upper] = pow(6.0 / (6.0 + upper_distance), 4.0) * gate
		scores[lower] = pow(6.0 / (6.0 + lower_distance), 4.0) * gate
		total += scores[upper] + scores[lower]
	for index in weights.size():
		weights[index] = (weights[index] * body_score + scores[index]) / total

func advance_pose(delta: float) -> void:
	phase = fposmod(phase + delta * swim_speed, TAU)
	sync_pose()

func sync_pose() -> void:
	if bones.is_empty():
		return
	var state := PackedFloat64Array([phase, swim_strength, neck_lift, leg_fold, tail_curl, stretch])
	if state == _last_pose:
		return
	_last_pose = state
	# Keep cubic interpolation overshoot within the calibrated anatomical range.
	var swim := clampf(swim_strength, 0.0, 1.1)
	var lift := clampf(neck_lift, -0.4, 1.0)
	var fold := clampf(leg_fold, 0.0, 1.0)
	var curl := clampf(tail_curl, 0.0, 0.4)
	var reach := clampf(stretch, 0.0, 1.0)
	var angles := PackedFloat32Array()
	angles.resize(bones.size())
	angles[0] = 1.5 * sin(phase) * swim
	angles[1] = 4.0 * sin(phase - 0.5) * swim - 3.0 * reach
	angles[2] = (6.0 * sin(phase - 1.1) + 0.8 * sin(phase * 2.0 - 1.3)) * swim + 5.0 * reach
	angles[3] = 4.0 * sin(phase - 1.5) * swim - 2.0 * reach
	# Five tail sections share the original total bend, rather than multiplying it.
	var tail_ids := [4, 34, 5, 35, 6]
	var amplitudes := [6.0, 5.0, 7.0, 6.0, 8.0]
	var curls := [6.0, 6.0, 8.0, 8.0, 11.0]
	for segment in range(5):
		var lag := 1.8 + segment * 0.3
		angles[tail_ids[segment]] = (amplitudes[segment] * sin(phase - lag) + 0.8 * sin(phase * 2.0 - lag - 0.4)) * swim + curls[segment] * curl
	angles[7] = (3.0 * sin(phase - 3.5) + 1.5 * sin(phase * 2.0 - 1.2)) * swim
	angles[8] = -10.0 * lift * neck_gain + 0.8 * sin(phase + 0.5) * swim
	angles[9] = -7.0 * lift * neck_gain + 0.5 * sin(phase + 0.8) * swim
	for side in range(2):
		# Paired limbs share a stroke with a small delay; front/rear pairs alternate.
		# This side-view mesh cannot exchange near/far occlusion as cutout layers could.
		var stroke := sin(phase + side * 0.35) * swim
		angles[10 + side * 2] = 0.65 * (10.0 * stroke - 16.0 * fold - 16.0 * reach)
		angles[11 + side * 2] = 0.65 * (7.0 * stroke + 20.0 * fold - 8.0 * reach)
		angles[14 + side * 2] = 0.65 * (-10.0 * stroke + 16.0 * fold + 16.0 * reach)
		angles[15 + side * 2] = 0.65 * (7.0 * stroke - 20.0 * fold + 8.0 * reach)
	# Continuous wind wave: roots are fixed; successive segments lag behind.
	# Integer harmonics preserve both pose and velocity at the phase wrap.
	for segment in range(3):
		var lag := float(segment) * 0.65
		angles[19 + segment] = (12.0 * sin(phase - lag) + 3.0 * sin(phase * 2.0 - lag - 0.8)) * swim * whisker_gain
		angles[23 + segment] = (7.0 * sin(phase - lag - 0.9) + 2.0 * sin(phase * 2.0 - lag - 1.4)) * swim * whisker_gain
	angles[27] = (4.0 * sin(phase - 0.7) + 1.5 * sin(phase * 2.0 - 1.5)) * swim
	angles[28] = (5.0 * sin(phase * 2.0 - 1.0) + 2.0 * sin(phase * 3.0)) * swim
	angles[29] = (7.0 * sin(phase * 2.0 - 1.9) + 2.0 * sin(phase * 3.0 - 0.9)) * swim
	angles[30] = 4.0 * sin(phase * 2.0 - 1.4) * swim
	angles[31] = 8.0 * sin(phase * 3.0 - 1.3) * swim
	angles[32] = -4.0 * sin(phase * 2.0 - 0.6) * swim
	angles[33] = 7.0 * sin(phase * 3.0 - 2.5) * swim
	_secondary_angles(angles, swim)
	_flame_material.set_shader_parameter("flow_phase", phase)
	_flame_material.set_shader_parameter("strength", swim)
	joint_globals.resize(bones.size())
	skin_matrices.resize(bones.size())
	for index in _bone_order:
		var parent: int = JOINTS[index][1]
		var bind: Vector2 = JOINTS[index][2]
		var origin := Vector2.ZERO if parent < 0 else Vector2(JOINTS[parent][2])
		var local := Transform2D(deg_to_rad(angles[index]), bind - origin)
		bones[index].transform = local
		var global_pose: Transform2D = local if parent < 0 else joint_globals[parent] * local
		joint_globals[index] = global_pose
		skin_matrices[index] = global_pose * Transform2D(0.0, -bind)
	_deformed_vertices.clear()

func _secondary_angles(_angles: PackedFloat32Array, _strength: float) -> void:
	pass

func _vertex(index: int) -> Vector2:
	if _deformed_vertices.has(index):
		return _deformed_vertices[index]
	var binding: Array = vertex_bindings[index]
	var point := Vector2.ZERO
	for influence in binding[0].size():
		point += (skin_matrices[binding[0][influence]] * vertices[index]) * binding[1][influence]
	_deformed_vertices[index] = point
	return point

func deform_point(point: Vector2) -> Vector2:
	# Exact barycentric mapping of the triangles used by Polygon2D, not a different warp.
	var grid := (point / SIZE * Vector2(COLUMNS, ROWS)).clamp(Vector2.ZERO, Vector2(COLUMNS, ROWS))
	var x := mini(int(grid.x), COLUMNS - 1)
	var y := mini(int(grid.y), ROWS - 1)
	var fraction := grid - Vector2(x, y)
	var a := y * (COLUMNS + 1) + x
	var b := a + 1
	var c := a + COLUMNS + 1
	if fraction.x + fraction.y <= 1.0:
		return _vertex(a) * (1.0 - fraction.x - fraction.y) + _vertex(b) * fraction.x + _vertex(c) * fraction.y
	return _vertex(b) * (1.0 - fraction.y) + _vertex(c + 1) * (fraction.x + fraction.y - 1.0) + _vertex(c) * (1.0 - fraction.x)

func region_sample_points() -> PackedVector2Array:
	# All affine influences cover the source rectangle; their displacement bounds LBS.
	var points := PackedVector2Array()
	sync_pose()
	for matrix in skin_matrices:
		for point in [Vector2.ZERO, Vector2(SIZE.x, 0), SIZE, Vector2(0, SIZE.y)]:
			points.append(matrix * point)
	return points

func prepare_outline(outline: PackedVector2Array) -> PackedVector2Array:
	# A contour edge crossing several mesh triangles is no longer straight after skinning.
	# Split at vertical, horizontal and diagonal grid edges before transforming it.
	var result := PackedVector2Array()
	for index in outline.size():
		var a := outline[index]
		var b := outline[(index + 1) % outline.size()]
		var start := a / SIZE * Vector2(COLUMNS, ROWS)
		var end := b / SIZE * Vector2(COLUMNS, ROWS)
		var times: Array[float] = [0.0]
		for pair in [Vector2(start.x, end.x), Vector2(start.y, end.y), Vector2(start.x + start.y, end.x + end.y)]:
			if absf(pair.y - pair.x) < 0.00001:
				continue
			for edge in range(floori(minf(pair.x, pair.y)) + 1, ceili(maxf(pair.x, pair.y))):
				var t: float = (edge - pair.x) / (pair.y - pair.x)
				if t > 0.00001 and t < 0.99999:
					times.append(t)
		times.sort()
		for time in times:
			result.append(a.lerp(b, time))
	return result
