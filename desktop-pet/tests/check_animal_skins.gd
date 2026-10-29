extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists("res://pet/skin_catalog.gd"), "Skin catalog must exist")
	if not ResourceLoader.exists("res://pet/skin_catalog.gd"):
		quit(1)
		return
	var catalog = load("res://pet/skin_catalog.gd")
	check(catalog.entries().size() == 4, "Four selectable skins")
	check(catalog.skin_id("unknown") == "warm_jade", "Unknown saved skin falls back to jade")
	for id in ["corgi", "duck", "jellyfish"]:
		var skin = catalog.load_skin(id)
		check(skin != null, id + " resource")
		var view = load("res://pet/pet_view.gd").new()
		root.add_child(view)
		check(view.apply_skin(skin) == OK, id + " applies with semantic idle player")
		check(view.actor.has_method("advance_pose"), id + " native skeletal advance")
		check(view.actor.has_method("render_regions"), id + " projected input shape")
		check(view.actor.native_player != null, id + " imported animation player")
		check(view.actor.native_player.has_animation("idle") and view.actor.native_player.has_animation("walk"), id + " native clips")
		var skeletons: Array = view.actor.model.find_children("*", "Skeleton3D", true, false)
		check(not skeletons.is_empty(), id + " real skeleton")
		view.select_action(&"walk")
		view._process(0.11)
		var bone_poses := []
		var skeleton: Skeleton3D = skeletons[0]
		for bone in skeleton.get_bone_count(): bone_poses.append(skeleton.get_bone_pose(bone))
		view._process(0.37)
		var moving_bones := 0
		for bone in skeleton.get_bone_count():
			if not skeleton.get_bone_pose(bone).is_equal_approx(bone_poses[bone]): moving_bones += 1
		check(moving_bones >= 2, id + " walk animates real joints")
		for action in catalog.actions(id):
			view.select_action(action[1])
			var length: float = view.player.current_animation_length
			check(length > 1.0, id + " action has authored timing " + str(action[1]))
			for frame in 24:
				view._process(1.0/30.0)
			check(not view.actor.region_sample_points().is_empty(), id + " samples pose")
			if action[1] != &"idle":
				for frame in int(length*30.0)+15: view._process(1.0/30.0)
				check(view.current_action == &"idle", id + " settles back to idle " + str(action[1]))
		view.actor.hide()
		view.actor.advance_pose(0.1)
		check(view.actor.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, id + " hidden viewport sleeps")
		view.free()
	print("ANIMAL_SKINS: ", failures, " failures")
	quit(1 if failures else 0)
