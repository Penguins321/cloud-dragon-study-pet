extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Preview color check requires a renderer")
		quit(1)
		return
	root.size = Vector2i(800,190)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("f1f5eb"))
	var preview = load("res://ui/appearance_preview.gd").new()
	root.add_child(preview)
	preview.size = Vector2(400,190)
	preview.set_process(false)
	var actor = load("res://pet/skins/warm_jade/view.tscn").instantiate()
	root.add_child(actor)
	actor.scale = preview.actor.scale
	actor.position = preview.actor.position+Vector2(400,0)
	var worst := 0.0
	for style in ["jade","glass","opal","flame"]:
		preview.set_appearance(style,"violet")
		actor.set_appearance(style,"violet")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var pixels := root.get_texture().get_image()
		var difference := 0.0
		for x in range(150,250):
			for y in range(45,145):
				var left := pixels.get_pixel(x,y)
				var right := pixels.get_pixel(x+400,y)
				difference += absf(left.r-right.r)+absf(left.g-right.g)+absf(left.b-right.b)
		worst = maxf(worst,difference/30000.0)
	print("Preview versus direct rendering mean channel difference: ",worst)
	quit(0 if worst < 0.01 else 1)
