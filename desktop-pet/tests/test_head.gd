extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	view.apply_skin(load("res://pet/skins/jade_dragon/skin.tres"))
	var head = view.actor
	check.call(head.has_method("sample_blink"), "jade head has an independently timed eyelid animation")
	if not head.has_method("sample_blink"):
		view.free()
		return
	check.call(head.sample_blink(0.0) == 0.0 and head.sample_blink(4.12) > 0.99 and head.sample_blink(4.4) == 0.0, "eyelids close briefly and reopen between blinks")
	var material: ShaderMaterial = head.get_node("Illustration").material
	check.call(material.get_shader_parameter("closed_eye") != null, "closed eyelid uses dedicated jade head artwork")
	view._process(4.12)
	check.call(material.get_shader_parameter("blink") > 0.99, "visible head advances the eyelid animation")
	var before: float = head.head_time
	view.set_active(false)
	view._process(1.0)
	check.call(head.head_time == before, "hidden pet also pauses its independent eyelids")
	view.set_active(true)
	view._process(0.3)
	check.call(material.get_shader_parameter("blink") < 0.01, "eyelids reopen after a paused blink resumes")
	view.free()
