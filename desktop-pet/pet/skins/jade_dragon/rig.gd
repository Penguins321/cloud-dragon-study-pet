extends "res://pet/skins/cloud_dragon/rig.gd"

var head_time := 0.0

# The shared motion driver stays independent of color; this skin owns its anatomy.
func _init() -> void:
	SIZE = Vector2(440.0, 175.95562)
	var positions := [
		Vector2(350,124), Vector2(300,127), Vector2(245,113), Vector2(200,103),
		Vector2(154,119), Vector2(91,129), Vector2(36,97), Vector2(30,94),
		Vector2(372,91), Vector2(399,60),
		Vector2(350,128), Vector2(356,148), Vector2(372,127), Vector2(386,144),
		Vector2(195,107), Vector2(175,138), Vector2(216,111), Vector2(214,137),
		Vector2(420,75), Vector2(435,104), Vector2(425,128), Vector2(434,158),
		Vector2(407,75), Vector2(422,103), Vector2(415,128), Vector2(429,162),
		Vector2(373,48), Vector2(343,62),
		Vector2(31,67), Vector2(29,25), Vector2(14,65), Vector2(11,46),
		Vector2(59,64), Vector2(70,45), Vector2(123,131), Vector2(62,115)
	]
	for index in JOINTS.size():
		JOINTS[index][2] = positions[index]
	limb_tips = [Vector2(380,167), Vector2(401,150), Vector2(188,158), Vector2(230,145)]
	face_landmarks = [Vector2(404,61), Vector2(418,70)]
	whisker_gain = 0.5
	neck_gain = 0.6
	var mane := [
		["NeckMane",8,Vector2(365,82)], ["NeckManeTip",36,Vector2(352,100)],
		["ShoulderMane",1,Vector2(287,112)], ["ShoulderManeTip",38,Vector2(270,90)],
		["WaistMane",2,Vector2(239,93)], ["WaistManeTip",40,Vector2(221,71)],
		["HipMane",3,Vector2(194,90)], ["HipManeTip",42,Vector2(172,75)],
		["TailMane",4,Vector2(140,119)], ["TailManeTip",44,Vector2(115,108)]
	]
	JOINTS.append_array(mane)

func _ready() -> void:
	super()
	_flame_material.shader = preload("res://pet/skins/jade_dragon/flame.gdshader")
	_flame_material.set_shader_parameter("closed_eye", preload("res://pet/skins/jade_dragon/head-closed.png"))

func advance_pose(delta: float) -> void:
	super(delta)
	head_time = fposmod(head_time + maxf(delta, 0.0), 16.0)
	_flame_material.set_shader_parameter("blink", sample_blink(head_time))

func sample_blink(seconds: float) -> float:
	var time := fposmod(seconds, 16.0)
	var amount := 0.0
	# Different intervals; fast close, a short hold, then a gentler reopening.
	for center in [4.1, 9.7, 14.3]:
		var distance: float = time - center
		amount = maxf(amount, smoothstep(-0.07, 0.0, distance) * (1.0 - smoothstep(0.025, 0.18, distance)))
	return amount

func _secondary_angles(angles: PackedFloat32Array, strength: float) -> void:
	var amplitudes := [4.0,3.5,4.0,3.5,3.0]
	for bundle in range(5):
		var lag := 0.7 * bundle
		angles[37+bundle*2] = (amplitudes[bundle]*sin(phase-lag) + sin(phase*2.0-lag-1.2))*strength

func _weights(point: Vector2) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(JOINTS.size())
	var chain := [6, 35, 5, 34, 4, 3, 2, 1, 0]
	_paint_chain(weights, point.x, chain, [36.0,62.0,91.0,123.0,154.0,200.0,245.0,300.0,350.0], 1.0)
	var neck := smoothstep(320.0, 373.0, point.x) * (1.0 - smoothstep(109.0, 138.0, point.y))
	_mix(weights, 8, neck)
	# The full antler crown, brow, eye and muzzle follow one rigid skull.
	var crown := smoothstep(288.0, 313.0, point.x) * (1.0 - smoothstep(40.0, 64.0, point.y))
	var face := smoothstep(355.0, 385.0, point.x) * (1.0 - smoothstep(76.0, 106.0, point.y))
	_mix(weights, 9, 1.0 if point.x > 405.0 else maxf(crown, face))
	_paint_limbs(weights, point, chain)
	_paint_wind(weights, point)
	_paint_flame(weights, point)
	var order: Array[int] = []
	for index in weights.size():
		if weights[index] > 0.0:
			order.append(index)
	order.sort_custom(func(a: int, b: int): return weights[a] > weights[b])
	for index in range(4, order.size()):
		weights[order[index]] = 0.0
	var total := 0.0
	for weight in weights:
		total += weight
	for index in weights.size():
		weights[index] /= total
	return weights

func _paint_wind(weights: PackedFloat32Array, point: Vector2) -> void:
	var mane := smoothstep(285.0,315.0,point.x) * (1.0-smoothstep(354.0,377.0,point.x)) * smoothstep(30.0,50.0,point.y) * (1.0-smoothstep(68.0,91.0,point.y))
	_mix(weights,27,mane)
	var right := smoothstep(402.0,419.0,point.x) * smoothstep(78.0,96.0,point.y)
	_paint_chain(weights,point.y,[18,19,20,21],[75.0,104.0,128.0,158.0],right)
	var left := 0.25 * (1.0-smoothstep(420.0,445.0,point.x)) * smoothstep(399.0,419.0,point.x) * smoothstep(80.0,99.0,point.y)
	_paint_chain(weights,point.y,[22,23,24,25],[75.0,103.0,128.0,162.0],left)
	var centers := [Vector2(344,82),Vector2(285,90),Vector2(244,69),Vector2(179,72),Vector2(108,99)]
	var radii := [Vector2(35,22),Vector2(34,20),Vector2(29,24),Vector2(38,19),Vector2(30,27)]
	var ends := [Vector2(96,119),Vector2(101,115),Vector2(75,90),Vector2(80,98),Vector2(113,127)]
	for bundle in range(5):
		var distance: float = ((point-centers[bundle])/radii[bundle]).length()
		var amount := 0.7 * pow(maxf(0.0,1.0-distance),2.0) * (1.0-smoothstep(ends[bundle].x,ends[bundle].y,point.y))
		_mix(weights,37+bundle*2,amount)

func _paint_flame(weights: PackedFloat32Array, point: Vector2) -> void:
	var mask := (1.0-smoothstep(70.0,112.0,point.x)) * (1.0-smoothstep(98.0,126.0,point.y))
	_paint_chain(weights,-point.y,[7,28,29],[-94.0,-67.0,-25.0],mask)
	_paint_chain(weights,-point.y,[30,31],[-65.0,-46.0],mask*(1.0-smoothstep(18.0,32.0,point.x)))
	_paint_chain(weights,-point.y,[32,33],[-64.0,-45.0],mask*smoothstep(38.0,65.0,point.x))
