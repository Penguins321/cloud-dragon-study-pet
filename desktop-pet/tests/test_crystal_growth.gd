extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var skin = load("res://pet/skins/warm_jade/skin.tres")
	var actor = skin.scene.instantiate()
	tree.root.add_child(actor)
	if not actor.has_method("set_growth"):
		check.call(false,"crystal actor accepts saved companionship growth")
		actor.free()
		return
	var base_shape: PackedVector2Array = actor.CORE.duplicate()
	actor.set_growth(0.0)
	var initial: int = actor.particle_count()
	actor.set_growth(0.5)
	var middle: int = actor.particle_count()
	actor.set_growth(1.0)
	check.call(initial < middle and middle < actor.particle_count(),"growth makes particles progressively more numerous")
	check.call(actor.particle_count() <= 72,"mature effect has a fixed performance ceiling")
	check.call(actor.CORE == base_shape,"growth preserves recognizable jade geometry")
	actor.set_growth(-100.0)
	check.call(actor.particle_count() == initial,"negative growth clamps safely")
	actor.set_growth(100.0)
	var bounds := true
	for step in range(90):
		actor.advance_pose(0.07)
		for polygon in actor.render_regions():
			for point in polygon: bounds = bounds and skin.visual_bounds.has_point(point)
	check.call(bounds,"mature particle mask fits stable full-animation bounds")
	actor.free()
