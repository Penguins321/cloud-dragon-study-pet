extends RefCounted

static func run(check: Callable) -> void:
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	check.call(rig.has_method("flame_particle_count"),"flame material is rendered with particles")
	if not rig.has_method("flame_particle_count"):
		rig.free()
		return
	rig.set_appearance("flame","ember")
	check.call(rig.appearance_style == "flame" and rig.appearance_color == "ember","flame and fire colors are valid selections")
	var start_count: int = rig.flame_particle_count()
	check.call(start_count >= 60,"flame has enough particles to read as continuous fire")
	var first: Vector2 = rig.flame_particle(0).position
	rig.advance_pose(0.1)
	check.call(first.distance_to(rig.flame_particle(0).position) > 1.0,"flame particles move over time")
	rig.set_growth(1.0)
	check.call(rig.flame_particle_count() > start_count,"growth enriches the flame")
	var covered := true
	var finite := true
	var regions: Array = rig.render_regions()
	for index in range(rig.flame_particle_count()):
		var particle: Dictionary = rig.flame_particle(index)
		finite = finite and particle.position.is_finite() and particle.alpha >= 0.0 and particle.alpha <= 1.0
		var found := false
		for region in regions:
			if Geometry2D.is_point_in_polygon(particle.position,region): found = true
		covered = covered and found
	check.call(finite and covered,"all flame particles remain finite and inside native rendering coverage")
	rig.set_appearance("jade","jade")
	check.call(rig.flame_particle_count() == 0,"changing away from flame stops its particles")
	rig.free()
