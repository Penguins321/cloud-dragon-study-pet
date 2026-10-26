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
		check.call(within_bounds,"light and scroll stay inside full animation bounds at scale %s" % size)
		effect.set_frame(anchor*size,size,0.2,"实际学习项")
		check.call(not effect.goal_label.visible and not effect.contains_point(effect.goal_rect.get_center()),"preparation has no premature goal or plan hit target")
		effect.set_frame(anchor*size,size,1.4,"实际学习项")
		check.call(effect.goal_label.visible and effect.goal_label.text == "实际学习项","formed scroll displays real current goal")
		check.call(effect.contains_point(effect.goal_rect.get_center()),"formed scroll opens plan")
		effect.set_frame(anchor*size,size,5.6,"实际学习项")
		check.call(effect.get_regions().is_empty() and not effect.contains_point(effect.goal_rect.get_center()),"finished light leaves no visual or invisible click region")
	effect.free()
