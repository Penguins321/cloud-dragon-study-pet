extends RefCounted

static func run(check: Callable) -> void:
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	check.call(rig.has_method("set_appearance"), "rig supports appearance without replacing motion state")
	if not rig.has_method("set_appearance"):
		rig.free()
		return
	var catalog = load("res://pet/appearance.gd")
	check.call(catalog.style_id("unknown") == "jade" and catalog.color_id(null) == "jade", "invalid saved appearance falls back to jade")
	rig.phase = 2.3
	rig.lift = -50.0
	rig.set_growth(0.7)
	var count: int = rig.particle_count()
	var shades: Array[Color] = []
	for entry in catalog.COLORS:
		rig.set_appearance("glass",entry.id)
		shades.append(rig.facet_colors()[1])
	check.call(absf(shades[0].r-shades[1].r)+absf(shades[0].b-shades[1].b) > 0.1, "colors produce distinct rendered facets")
	var clear: Color = rig.facet_colors()[1]
	rig.set_appearance("jade","moon")
	check.call(clear.a < rig.facet_colors()[1].a, "glass has more transparent facets than jade")
	rig.set_appearance("opal","violet")
	var before: Color = rig.facet_colors()[0]
	rig.phase += 2.0
	check.call(before != rig.facet_colors()[0], "opal refraction changes over time")
	check.call(is_equal_approx(rig.lift,-50.0) and rig.particle_count() == count, "appearance preserves pose and growth")
	rig.set_appearance("invalid","invalid")
	check.call(rig.appearance_style == "jade" and rig.appearance_color == "jade", "rig sanitizes unknown choices")
	rig.free()
