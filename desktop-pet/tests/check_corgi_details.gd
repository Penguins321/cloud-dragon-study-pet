extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var actor = load("res://pet/skins/animals/corgi.tscn").instantiate()
	root.add_child(actor)
	var skeleton: Skeleton3D = actor.model.find_children("*","Skeleton3D",true,false)[0]
	var head := skeleton.find_bone("Head")
	var mesh: MeshInstance3D = actor.model.find_children("*","MeshInstance3D",true,false)[0]
	var head_bind := -1
	for i in mesh.skin.get_bind_count():
		if mesh.skin.get_bind_name(i) == "Head": head_bind = i
	var arrays: Array = mesh.mesh.surface_get_arrays(0)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var head_vertices := 0
	for i in bones.size():
		if bones[i] == head_bind and weights[i] > 0.1: head_vertices += 1
	check(head_vertices > 10,"Corgi head must deform upper coat along with its face")
	actor.player.play("idle")
	var smallest_eye := 1.0
	var largest_eye := 0.0
	var eye := skeleton.find_bone("LeftEye")
	for i in 240:
		actor.advance_pose(1.0/30.0)
		smallest_eye = minf(smallest_eye,skeleton.get_bone_pose_scale(eye).y)
		largest_eye = maxf(largest_eye,skeleton.get_bone_pose_scale(eye).y)
	check(smallest_eye < 0.2 and largest_eye > 0.95,"Eyes must close briefly and reopen")
	actor.set_desktop_attention(Vector2(1,-0.5))
	for i in 40: actor.advance_pose(1.0/60.0)
	var pose: Quaternion = skeleton.get_bone_pose_rotation(head)
	actor.set_desktop_attention(Vector2(-1,0.5))
	for i in 40: actor.advance_pose(1.0/60.0)
	check(pose.angle_to(skeleton.get_bone_pose_rotation(head)) > 0.15,"Head must turn locally toward attention")
	var ear := skeleton.find_bone("LeftEar")
	var ear_pose := skeleton.get_bone_pose(ear)
	for i in 100: actor.advance_pose(0.0)
	check(ear_pose.is_equal_approx(skeleton.get_bone_pose(ear)),"Zero-time pose updates must not accumulate")
	# Imported model data must remain untouched for other instances.
	var second = load("res://pet/skins/animals/corgi.tscn").instantiate()
	root.add_child(second)
	var second_skeleton: Skeleton3D = second.model.find_children("*","Skeleton3D",true,false)[0]
	check(second_skeleton.get_bone_pose_scale(eye).is_equal_approx(Vector3.ONE),"Second corgi starts with its own open eyes")
	second.free()
	if DisplayServer.get_name() != "headless": await check_gpu(actor)
	actor.hide()
	var elapsed: float = actor._elapsed
	actor.advance_pose(0.25)
	check(actor._elapsed == elapsed,"Hidden corgi must not keep animating")
	actor.free()
	print("CORGI DETAILS: ",failures," failures")
	quit(0 if failures == 0 else 1)

func check_gpu(actor: Node2D) -> void:
	var clipped := 0
	var uncovered := 0
	var empty := 0
	for action in ["idle","walk","look","curious","jump","celebrate","rest","breath","bow","spin","dance","dragging"]:
		actor.player.play(action)
		for direction in [-1.0,1.0]:
			actor.set_desktop_attention(Vector2(direction,direction*0.5))
			for phase in [0.0,0.25,0.5,0.75,0.98]:
				actor.phase = phase
				for frame in 12: actor.advance_pose(1.0/60.0)
				for frame in 3:
					await process_frame
					await RenderingServer.frame_post_draw
				var pixels: Image = actor.viewport.get_texture().get_image()
				var found := 0
				for y in range(0,pixels.get_height(),3):
					for x in range(0,pixels.get_width(),3):
						if pixels.get_pixel(x,y).a < 0.05: continue
						found += 1
						if x < 3 or y < 3 or x >= pixels.get_width()-3 or y >= pixels.get_height()-3: clipped += 1
						var inside := false
						for polygon in actor.render_regions():
							if Geometry2D.is_point_in_polygon(Vector2(x,y)+actor.ORIGIN,polygon): inside = true
						if not inside: uncovered += 1
				if found < 100: empty += 1
	check(clipped == 0,"All corgi action/direction phases must fit the 3D viewport; clipped="+str(clipped))
	check(uncovered == 0,"Corgi and shadow must stay inside native clipping contours; missed="+str(uncovered))
	check(empty == 0,"Every corgi action must produce visible pixels")
	print("CORGI GPU: 120 action/direction samples, clipped=",clipped," uncovered=",uncovered)
