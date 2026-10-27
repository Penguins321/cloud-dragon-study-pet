extends RefCounted

# Shared by the desktop actor, settings preview and persisted preferences.
const STYLES := [
	{"id":"jade", "name":"温润玉晶", "detail":"柔和玉质 · 细密晶纹"},
	{"id":"glass", "name":"澄透水晶", "detail":"通透切面 · 冷冽折光"},
	{"id":"opal", "name":"幻彩欧泊", "detail":"虹彩游移 · 多层流光"},
	{"id":"flame", "name":"流焰灵核", "detail":"粒子燃烧 · 流动焰光"}
]
const COLORS := [
	{"id":"jade", "name":"青玉", "color":Color("79bca9")},
	{"id":"ice", "name":"冰蓝", "color":Color("649edc")},
	{"id":"violet", "name":"紫晶", "color":Color("aa7acb")},
	{"id":"rose", "name":"蔷薇", "color":Color("d889a5")},
	{"id":"amber", "name":"琥珀", "color":Color("d5a24c")},
	{"id":"moon", "name":"月白", "color":Color("c6d4de")},
	{"id":"ember", "name":"赤焰", "color":Color("e56b35")},
	{"id":"gold", "name":"熔金", "color":Color("efb52d")},
	{"id":"bluefire", "name":"蓝焰", "color":Color("468cf4")}
]

static func style_id(value: Variant) -> String:
	for entry in STYLES:
		if value == entry.id: return entry.id
	return "jade"

static func color_id(value: Variant) -> String:
	for entry in COLORS:
		if value == entry.id: return entry.id
	return "jade"

static func tint(value: Variant) -> Color:
	var selected := color_id(value)
	for entry in COLORS:
		if entry.id == selected: return entry.color
	return COLORS[0].color
