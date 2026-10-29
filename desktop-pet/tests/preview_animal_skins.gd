extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1100,760)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e9e5dc"))
	var catalog = load("res://pet/skin_catalog.gd")
	var views := []
	var ids := ["corgi","duck","jellyfish"]
	var actions := [&"idle",&"walk",&"jump",&"bow",&"spin",&"dance"]
	for row in 3:
		for column in 6:
			var view = load("res://pet/pet_view.gd").new()
			root.add_child(view)
			view.apply_skin(catalog.load_skin(ids[row]))
			view.set_process(false)
			view.scale = Vector2.ONE*0.52
			view.position = Vector2(column*182-25,row*245+30)
			view.select_action(actions[column])
			var offset: float = [0.7,0.7,1.15,1.5,2.1,1.7][column]
			for frame in int(offset*60): view._process(1.0/60.0)
			views.append(view)
			var label := Label.new()
			label.text = ids[row]+" · "+str(actions[column])
			label.position = Vector2(column*182+16,row*245+210)
			label.add_theme_font_size_override("font_size",17)
			label.add_theme_color_override("font_color",Color("536453"))
			root.add_child(label)
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/v0.17")
	var failures := 0
	for view in views:
		var pixels: Image = view.actor.viewport.get_texture().get_image()
		var found := 0
		var clipped := 0
		var missed := 0
		var polygons: Array = view.actor.render_regions()
		for y in range(0,pixels.get_height(),3):
			for x in range(0,pixels.get_width(),3):
				if pixels.get_pixel(x,y).a < 0.1: continue
				found += 1
				if x<3 or y<3 or x>pixels.get_width()-4 or y>pixels.get_height()-4: clipped += 1
				var covered := false
				for polygon in polygons:
					if Geometry2D.is_point_in_polygon(Vector2(x,y)+view.actor.ORIGIN,polygon): covered = true
				if not covered: missed += 1
		if found < 100 or clipped > 0 or missed > 0:
			push_error("Animal GPU alpha/region check " + String(view.skin.id) + " " + String(view.current_action) + ": found=" + str(found) + " clipped=" + str(clipped) + " uncovered=" + str(missed))
			failures += 1
	print("ANIMAL_GPU_ALPHA: ",failures," failures")
	var path := "res://docs/screenshots/v0.17/animal-animation-atlas.png"
	var result := root.get_texture().get_image().save_png(path)
	print("ANIMAL_ATLAS: ",result," ",path)
	# Swap before post_draw to exercise freeing a pending GPU alpha capture.
	var swap_view = load("res://pet/pet_view.gd").new()
	root.add_child(swap_view)
	swap_view.set_process(false)
	for iteration in 9:
		swap_view.apply_skin(catalog.load_skin(ids[iteration%3]))
		swap_view._process(0.1)
	swap_view.free()
	for frame in 3: await process_frame
	print("ANIMAL_GPU_SWITCH: 9 rapid switches drained")
	quit(1 if failures else result)
