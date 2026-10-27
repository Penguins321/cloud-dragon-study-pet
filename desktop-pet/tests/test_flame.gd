extends RefCounted

static func run(check: Callable) -> void:
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	var flow = load("res://pet/flame_flow.gd")
	rig.set_appearance("flame","ember")
	var young_count: int = rig.flame_particle_count()
	check.call(young_count > 0,"fire theme has live ember particles")
	var phase: float = rig.phase
	var before: Array = flow.ember_particles(rig)
	rig.advance_pose(0.1)
	check.call(before[0].position.distance_to(flow.ember_particles(rig)[0].position)>1.0,"embers travel independently over time")
	rig.set_growth(1.0)
	check.call(rig.flame_particle_count()>young_count,"companionship growth adds actual ember particles")
	check.call(rig.phase>phase,"switching and growth preserve the running motion clock")
	rig.set_appearance("jade","jade")
	check.call(rig.flame_particle_count()==0,"leaving the fire theme disables its particles")
	rig.free()