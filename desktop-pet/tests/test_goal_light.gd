extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var path := "res://pet/effects/goal_light.gd"
	if not ResourceLoader.exists(path):
		check.call(false,"jade light has its own smoke-free effect")
		return
	var effect = load(path).new()
	tree.root.add_child(effect)
	check.call(effect.material == null,"jade light uses no cloud noise shader")
	var anchor := Vector2(220,16)
	for size in [0.5,0.75,1.0,1.25]:
		var within_bounds := true
		for time in [0.0,0.2,0.4,0.7,1.05,1.4,3.2,5.1,5.4,5.6]:
			effect.set_frame(anchor*size,size,time,"设计模式 · 单例模式")
			for polygon in effect.get_regions():
				for point in polygon:
					within_bounds = within_bounds and Rect2(Vector2(-60,-210)*size,Vector2(500,530)*size).has_point(point)
		check.call(within_bounds,"subtle light stays inside animation bounds at scale %s" % size)
		effect.set_frame(anchor*size,size,0.7,"不应出现在画面里的任务文本")
		check.call(not effect.get_regions().is_empty(), "breath keeps a short light flourish")
		check.call(effect.get_child_count() == 0, "light contains no goal text or caption controls")
		check.call(not effect.contains_point(anchor*size), "light does not create a chat or plan hit target")
		var local_light := true
		for polygon in effect.get_regions():
			for point in polygon:
				local_light = local_light and point.distance_to(anchor*size) < 100*size
		check.call(local_light,"light stays near companion without a connector or remote sheet")
		effect.set_frame(anchor*size,size,3.2,"实际学习项")
		check.call(effect.get_regions().is_empty(), "short flourish ends before the full breath animation")
		effect.set_frame(anchor*size,size,5.6,"实际学习项")
		check.call(effect.get_regions().is_empty() and not effect.contains_point(anchor*size),"finished light leaves no visual or invisible click region")
	effect.free()
