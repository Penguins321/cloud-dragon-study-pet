extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var catalog = load("res://pet/appearance.gd")
	var ok: bool = catalog.selection("flame","ember") == ["jade","jade"]
	for color in ["gold","bluefire","ice"]: ok = ok and catalog.selection("flame",color) == ["jade","jade"]
	for entry in catalog.STYLES: ok = ok and entry.id != "flame"
	var panel = load("res://ui/settings_panel.tscn").instantiate()
	root.add_child(panel)
	ok = ok and not panel._style_buttons.has("flame")
	var rig = panel.appearance_preview.actor
	rig.set_appearance("jade","jade")
	rig.set_render_mode("3d")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		ok = ok and rig._use_3d
		if rig._use_3d:
			var mesh_count := 0
			for child in rig._view_3d.viewport.get_children():
				if child is MeshInstance3D: mesh_count += 1
			ok = ok and mesh_count == 3
			var fields = rig._view_3d.motes.fields
			ok = ok and fields[0].multimesh.visible_instance_count+fields[1].multimesh.visible_instance_count==28
			rig.set_growth(1)
			ok = ok and fields[0].multimesh.visible_instance_count+fields[1].multimesh.visible_instance_count==72
	panel.free()
	print("CRYSTAL ONLY / RETIRED FIRE: ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
