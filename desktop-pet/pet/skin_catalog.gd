extends RefCounted

const PetSkinResource = preload("res://pet/pet_skin.gd")
const JADE_ACTIONS := [["漫游", &"swim"], ["感知", &"look"], ["舒展", &"stretch"], ["收息", &"rest"], ["共鸣", &"celebrate"], ["引光", &"breath"], ["踱步", &"walk"], ["轻笑", &"laugh"], ["跃起", &"jump"], ["轻跳", &"hop"], ["旋转", &"spin"], ["摇摆", &"sway"], ["鞠躬", &"bow"], ["翻滚", &"roll"], ["舞蹈", &"dance"], ["环绕", &"orbit"], ["螺旋", &"helix"], ["交错", &"cross_orbit"], ["折光", &"refract_turn"], ["招手", &"greet"], ["亲昵", &"nuzzle"], ["惊喜", &"startle"], ["小憩", &"doze"]]
const ANIMAL_ACTIONS := [["放松", &"idle"], ["散步", &"walk"], ["张望", &"look"], ["好奇", &"curious"], ["轻跃", &"jump"], ["开心", &"celebrate"], ["休息", &"rest"], ["呼吸", &"breath"], ["鞠躬", &"bow"], ["转圈", &"spin"], ["起舞", &"dance"]]

static func entries() -> Array[Dictionary]:
	return [{"id":"warm_jade", "name":"温玉灵核", "detail":"玉石与柔光 · 19 种动作"}, {"id":"corgi", "name":"柯基", "detail":"短腿小伙伴 · 原生骨骼动画"}, {"id":"duck", "name":"小鸭", "detail":"摇摇摆摆 · 原生骨骼动画"}, {"id":"jellyfish", "name":"水母", "detail":"轻盈漂浮 · 原生骨骼动画"}]

static func skin_id(value: Variant) -> String:
	var id := str(value)
	return id if id in ["warm_jade", "corgi", "duck", "jellyfish"] else "warm_jade"

static func actions(id: String) -> Array:
	return JADE_ACTIONS.duplicate(true) if skin_id(id) == "warm_jade" else ANIMAL_ACTIONS.duplicate(true)

static func load_skin(id: String) -> Resource:
	id = skin_id(id)
	if id == "warm_jade":
		return load("res://pet/skins/warm_jade/skin.tres")
	var result := PetSkinResource.new()
	result.id = StringName(id)
	result.scene = load("res://pet/skins/animals/" + id + ".tscn")
	result.visual_bounds = Rect2(60, -40, 320, 340)
	result.hit_polygon = PackedVector2Array([Vector2(110,50),Vector2(220,10),Vector2(330,50),Vector2(340,220),Vector2(220,270),Vector2(100,220)])
	result.bubble_anchor = Vector2(100,-35)
	result.breath_anchor = Vector2(220,110)
	for action in ANIMAL_ACTIONS:
		result.action_map[action[1]] = action[1]
	result.action_map[&"dragging"] = &"dragging"
	result.action_map[&"sleepy"] = &"rest"
	return result
