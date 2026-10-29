extends RefCounted

static func run(check: Callable) -> void:
	var appearance = load("res://pet/appearance.gd")
	check.call(appearance.selection("flame","ember") == ["jade","jade"],"retired fire preferences restore the original jade crystal")
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	rig.set_appearance("flame","ember")
	check.call(rig.appearance_style == "jade" and rig.flame_particle_count() == 0,"retired fire has no flame or ember renderer")
	rig.free()
