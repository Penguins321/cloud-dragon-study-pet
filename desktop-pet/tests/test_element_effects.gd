extends RefCounted

const Effects = preload("res://pet/element_effects.gd")

static func _covered(point: Vector2, regions: Array) -> bool:
	for polygon in regions:
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	return false

static func run(check: Callable) -> void:
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	var effects := Effects.new()
	var has_mist: bool = effects.has_method("mist_paths") and effects.has_method("frost_paths")
	check.call(has_mist,"snow has flowing mist and selective edge frost geometry")
	var no_badge := true
	var currents := Effects.lightning_paths(rig)
	for path_index in range(currents.size()):
		var path: PackedVector2Array = currents[path_index]
		var reaches_edge := false
		for point in path: reaches_edge = reaches_edge or point.distance_to(rig.parts[1].origin)>70.0
		for other_index in range(currents.size()):
			if other_index==path_index: continue
			for point in currents[other_index]: reaches_edge = reaches_edge or point.distance_to(path[0])<0.01
		no_badge = no_badge and reaches_edge
	check.call(no_badge,"lightning travels around the stones instead of stamping a central badge")
	var continuous := true
	var evolving := false
	for sample in range(60):
		rig.phase = sample*0.19
		var before := Effects.lightning_paths(rig)
		rig.phase += 1.0/240.0
		var after := Effects.lightning_paths(rig)
		continuous = continuous and before.size()==after.size()
		for index in range(mini(before.size(),after.size())):
			continuous = continuous and before[index].size()==after[index].size()
			for vertex in range(mini(before[index].size(),after[index].size())):
				continuous = continuous and before[index][vertex].distance_to(after[index][vertex])<1.0
		rig.phase += 1.0
		var later := Effects.lightning_paths(rig)
		for index in range(mini(before.size(),later.size())):
			for vertex in range(mini(before[index].size(),later[index].size())):
				evolving = evolving or before[index][vertex].distance_to(later[index][vertex])>10.0
	check.call(continuous,"electric current moves continuously at 240 Hz without topology jumps")
	check.call(evolving,"electric current meaningfully evolves within one second with a fixed stone pose")
	var mist_continuous := true
	var mist_evolving := false
	for sample in range(30):
		rig.phase = sample*0.37
		var before := Effects.mist_paths(rig)
		rig.phase += 1.0/240.0
		var after := Effects.mist_paths(rig)
		for index in range(before.size()):
			for vertex in range(before[index].size()): mist_continuous = mist_continuous and before[index][vertex].distance_to(after[index][vertex])<1.0
		rig.phase += 1.0
		var later := Effects.mist_paths(rig)
		for index in range(before.size()):
			for vertex in range(before[index].size()): mist_evolving = mist_evolving or before[index][vertex].distance_to(later[index][vertex])>4.0
	check.call(mist_continuous and mist_evolving,"mist flows continuously and visibly with a fixed stone pose")
	rig.phase = 0.0
	check.call(Effects.snow_particle(rig,0).alpha<0.001,"snow fades to zero at birth")
	var gap: Vector2 = rig.parts[1].origin+Vector2(181,-160)
	check.call(not _covered(gap,Effects.regions(rig,"snow")),"empty snow emitter corner remains click-through")
	var covered := true
	var finite := true
	var envelope := Rect2(-100,-360,650,750)
	var within_window := true
	var player: AnimationPlayer = rig.get_node("AnimationPlayer")
	for action in ["float","jump","roll","dance","sway","stretch","walk"]:
		player.play(action)
		for sample in range(33):
			player.seek(player.get_animation(action).length*sample/32.0,true)
			rig.advance_pose(0.19)
			for style in ["lightning","snow"]:
				var regions := Effects.regions(rig,style)
				var points := PackedVector2Array()
				if style == "lightning":
					var paths := Effects.lightning_paths(rig)
					for path_index in range(paths.size()):
						var path: PackedVector2Array = paths[path_index]
						if path_index<3: points.append_array(Effects._ribbon(path,7.0 if path_index%3==1 else 11.0,rig.phase*1.7+path_index*1.3))
						for point in path:
							var radius := 2.5 if path_index<3 else 1.3
							for offset in [Vector2(radius,0),Vector2(-radius,0),Vector2(0,radius),Vector2(0,-radius)]: points.append(point+offset)
				else:
					if has_mist:
						var mist: Array = effects.call("mist_paths",rig)
						for path_index in range(mist.size()): points.append_array(Effects._ribbon(mist[path_index],8.0 if path_index==1 else 12.0,rig.phase*0.9+path_index*1.7))
						for path in effects.call("frost_paths",rig):
							for point in path:
								for offset in [Vector2(1.5,0),Vector2(-1.5,0),Vector2(0,1.5),Vector2(0,-1.5)]: points.append(point+offset)
					for patch in Effects.frost_polygons(rig): points.append_array(patch)
					for index in range(Effects.FLAKE_COUNT):
						var flake := Effects.snow_particle(rig,index)
						finite = finite and flake.alpha >= 0.0 and flake.alpha <= 1.0
						if flake.alpha>0.0001:
							points.append_array(Effects.snowflake_lines(flake.position,flake.radius+0.6,flake.angle,index%4==0))
							if flake.get("shard",false): points.append_array(Effects.snow_shard(flake))
				for point in points:
					finite = finite and point.is_finite()
					covered = covered and _covered(point,regions)
					within_window = within_window and envelope.has_point(point)
	check.call(finite,"element geometry remains finite across choreography")
	check.call(covered,"native regions cover both layers of current, mist, edge frost and drifting flake strokes")
	check.call(within_window,"element strokes fit the fixed native rendering envelope")
	check.call(Effects.FLAKE_COUNT <= 40,"snow uses a bounded sparse particle field")
	var start: Vector2 = Effects.snow_particle(rig,7).position
	rig.advance_pose(0.2)
	check.call(start.distance_to(Effects.snow_particle(rig,7).position)>0.5,"snow drifts over time")
	if Effects.snow_particle(rig,0).has("lifetime"):
		rig.phase = Effects.snow_particle(rig,0).lifetime-0.00001
		check.call(Effects.snow_particle(rig,0).alpha<0.001,"snow fades to zero before recycling")
	rig.free()
