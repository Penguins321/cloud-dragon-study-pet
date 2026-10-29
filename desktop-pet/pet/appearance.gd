extends RefCounted

# Shared by the desktop actor, settings preview and persisted preferences.
const STYLES := [
	{"id":"jade", "name":"温润玉晶", "detail":"柔和玉质 · 细密晶纹"},
	{"id":"glass", "name":"澄透水晶", "detail":"通透切面 · 冷冽折光"},
	{"id":"opal", "name":"幻彩欧泊", "detail":"虹彩游移 · 多层流光"},
	{"id":"lightning", "name":"雷电精灵", "detail":"分岔电弧 · 脉冲雷光"},
	{"id":"snow", "name":"冰雪精灵", "detail":"冰晶霜纹 · 轻盈飘雪"}
]
const COLORS := [
	{"id":"jade", "name":"青玉", "color":Color("79bca9")},
	{"id":"ice", "name":"冰蓝", "color":Color("649edc")},
	{"id":"violet", "name":"紫晶", "color":Color("aa7acb")},
	{"id":"rose", "name":"蔷薇", "color":Color("d889a5")},
	{"id":"amber", "name":"琥珀", "color":Color("d5a24c")},
	{"id":"moon", "name":"月白", "color":Color("c6d4de")},
	{"id":"ember", "name":"赤焰", "color":Color("e56b35")}
]

static func style_id(value: Variant) -> String:
	for entry in STYLES:
		if value == entry.id: return entry.id
	return "jade"

static func color_id(value: Variant) -> String:
	if value == "gold": return "amber"
	if value == "bluefire": return "ice"
	for entry in COLORS:
		if value == entry.id: return entry.id
	return "jade"

static func selection(style: Variant, color: Variant) -> Array[String]:
	# All retired fire appearances return to the original clean crystal.
	if style == "flame": return ["jade","jade"]
	return [style_id(style),color_id(color)]

static func tint(value: Variant) -> Color:
	var selected := color_id(value)
	for entry in COLORS:
		if entry.id == selected: return entry.color
	return COLORS[0].color
