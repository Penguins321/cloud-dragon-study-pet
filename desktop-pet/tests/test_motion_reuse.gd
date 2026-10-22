extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var path := "res://pet/motions/cloud_dragon_flexible_v2.tres"
	var available := ResourceLoader.exists(path)
	check.call(available, "cloud dragon motion library is archived separately from skin colors")
	if not available:
		return
	var source_skin = load("res://pet/skins/cloud_dragon/skin.tres")
	var recolored = source_skin.scene.instantiate()
	recolored.get_node("Illustration").self_modulate = Color(0.75, 0.9, 1.0, 1.0)
	var variant_scene := PackedScene.new()
	variant_scene.pack(recolored)
	recolored.free()
	var variant = source_skin.duplicate()
	variant.id = &"recolor_fixture"
	variant.scene = variant_scene
	var view = load("res://pet/pet_view.gd").new()
	tree.root.add_child(view)
	view.apply_skin(variant)
	check.call(view.player.get_animation_library(&"") == load(path), "recolored appearance reuses the same animation resource")
	view.play_action(&"celebrate")
	view.player.advance(0.45)
	check.call(view.current_action == &"celebrate" and view.actor.position.y < -1.0, "recolored appearance retains celebration movement")
	view.free()
