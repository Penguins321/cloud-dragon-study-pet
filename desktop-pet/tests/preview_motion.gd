extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output := OS.get_environment("CLOUD_DRAGON_PREVIEW_DIR")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		printerr("Preview needs real rendering and CLOUD_DRAGON_PREVIEW_DIR")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var skin_path := OS.get_environment("CLOUD_DRAGON_PREVIEW_SKIN")
	if skin_path.is_empty():
		skin_path = "res://pet/skins/jade_dragon/skin.tres"
	var skin = load(skin_path)
	var prefix: String = String(skin.id).replace("_", "-")
	root.transparent_bg = false
	root.size = Vector2i(1200, 1080)
	RenderingServer.set_default_clear_color(Color("edf3f9"))
	var layout := Node2D.new()
	root.add_child(layout)
	var samples := [
		["游动 · A", 0.0, 1.0, 0.0, 0.0, 0.0, 0.0],
		["游动 · B", PI, 1.0, 0.0, 0.0, 0.0, 0.0],
		["抬头", 1.0, 0.45, 1.0, 0.0, 0.0, 0.0],
		["舒展", 2.0, 0.35, 0.5, 0.0, 0.0, 1.0],
		["收拢休息", 2.6, 0.25, -0.4, 1.0, 0.4, 0.0],
		["骨架连接 · 示意", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	]
	for index in samples.size():
		var entry: Array = samples[index]
		var position := Vector2(90 + (index % 2) * 600, 130 + (index / 2) * 360)
		var actor = skin.scene.instantiate()
		layout.add_child(actor)
		actor.position = position + Vector2(440,0) if actor.scale.x < 0.0 else position
		actor.phase = entry[1]
		actor.swim_strength = entry[2]
		actor.neck_lift = entry[3]
		actor.leg_fold = entry[4]
		actor.tail_curl = entry[5]
		actor.stretch = entry[6]
		actor.sync_pose()
		var label := Label.new()
		label.theme = load("res://ui/study_theme.tres")
		label.text = entry[0]
		label.position = position - Vector2(0, 68)
		layout.add_child(label)
		if index == 5:
			for joint in range(1, actor.JOINTS.size()):
				var line := Line2D.new()
				line.width = 1.6
				line.default_color = Color("e66648")
				line.points = PackedVector2Array([actor.joint_globals[actor.JOINTS[joint][1]].origin, actor.joint_globals[joint].origin])
				actor.add_child(line)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(prefix + "-poses-v1.png"))
	layout.free()
	root.size = Vector2i(600, 400)
	var actor = skin.scene.instantiate()
	root.add_child(actor)
	var facing: float = signf(actor.scale.x)
	actor.position = Vector2(530 if facing < 0.0 else 90, 130)
	actor.swim_strength = 1.0
	for frame in range(64):
		actor.phase = TAU * frame / 64.0
		actor.sync_pose()
		_sample_head(actor, frame)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("frame-%03d.png" % frame))
	var detail := output.path_join("head")
	DirAccess.make_dir_recursive_absolute(detail)
	root.size = Vector2i(640, 650)
	actor.position = Vector2(1420 if facing < 0.0 else -800, 45)
	actor.scale = Vector2(facing*3, 3)
	var label := Label.new()
	label.theme = load("res://ui/study_theme.tres")
	label.text = "双须与鬃毛 · 迎风跟随（3 倍细节）"
	label.position = Vector2(24, 12)
	root.add_child(label)
	for frame in range(64):
		actor.phase = TAU * frame / 64.0
		actor.sync_pose()
		_sample_head(actor, frame)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(detail.path_join("frame-%03d.png" % frame))
	if actor.has_method("sample_blink"):
		for state in [["open", 0.0], ["closed", 4.12]]:
			actor.phase = 0.0
			actor.head_time = state[1]
			actor.advance_pose(0.0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(prefix + "-head-" + state[0] + ".png"))
	var tail_detail := output.path_join("tail")
	DirAccess.make_dir_recursive_absolute(tail_detail)
	root.size = Vector2i(640, 600)
	actor.position = Vector2(515 if facing < 0.0 else 125, 40)
	label.text = "分段尾摆与三束尾焰 · 3 倍细节"
	for frame in range(64):
		actor.phase = TAU * frame / 64.0
		actor.sync_pose()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(tail_detail.path_join("frame-%03d.png" % frame))
	print("PREVIEW FRAMES SAVED ", output)
	quit()

func _sample_head(actor: Node2D, frame: int) -> void:
	if actor.has_method("sample_blink"):
		actor.head_time = 3.1 + frame / 30.0
		actor.advance_pose(0.0)
