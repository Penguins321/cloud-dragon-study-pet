extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var rig = load("res://pet/skins/warm_jade/rig.gd").new()
	root.add_child(rig)
	rig.set_appearance("jade","jade")
	rig.set_render_mode("3d")
	var renderer = rig._view_3d
	var material: ShaderMaterial = renderer.stones[1].material_override
	var frames: Array[Image] = []
	for strength in [0.0,0.38,0.75]:
		material.set_shader_parameter("core_energy",strength)
		for frame in range(3):
			renderer.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			await process_frame
			await RenderingServer.frame_post_draw
		frames.append(renderer.viewport.get_texture().get_image())
	var center: Vector2i = Vector2i(325,375)+Vector2i(rig.parts[1].origin-Vector2(225,15))
	var sums := [0.0,0.0,0.0]
	var lit_pixels := 0
	var spill_pixels := 0
	var clipped_pixels := 0
	for y in range(center.y-75,center.y+75):
		for x in range(center.x-40,center.x+40):
			for index in range(3):
				var pixel := frames[index].get_pixel(x,y)
				sums[index] += pixel.r+pixel.g+pixel.b
			var before := frames[0].get_pixel(x,y)
			var after := frames[2].get_pixel(x,y)
			if after.r-before.r > 0.025:
				lit_pixels += 1
				if abs(x-center.x)>10: spill_pixels += 1
			if minf(after.r,minf(after.g,after.b)) > 0.98: clipped_pixels += 1
	var ok: bool = sums[0]<sums[1] and sums[1]<sums[2] and spill_pixels>80 and clipped_pixels<30
	material.set_shader_parameter("core_energy",0.38)
	material.set_shader_parameter("refraction_index",1.0)
	for frame in range(2):
		renderer.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		await RenderingServer.frame_post_draw
	var straight: Image = renderer.viewport.get_texture().get_image()
	var refraction_difference := 0.0
	for y in range(center.y-75,center.y+75):
		for x in range(center.x-40,center.x+40):
			var a := straight.get_pixel(x,y)
			var b := frames[1].get_pixel(x,y)
			refraction_difference += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
	ok = ok and refraction_difference>5.0
	# The only child mesh is the edge drawing; energy is carried by the material.
	ok = ok and renderer.stones[1].get_child_count()==1
	print("ENERGY CORE: light levels ",sums,"; lit/spill pixels ",lit_pixels,"/",spill_pixels,"; clipped white pixels ",clipped_pixels,"; refracted RGB difference ",refraction_difference,"; ","PASS" if ok else "FAIL")
	rig.free()
	await process_frame
	quit(0 if ok else 1)
