extends RefCounted

static func build(radius: float, height: float, edges := true, facets := 6) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shades := [Color("ffe0a3"),Color("dba569"),Color("f6bd7d"),Color("fff0c4")]
	for half in [-1.0,1.0]:
		for i in range(facets):
			var a := Vector3(0,half*height,0)
			var b := Vector3(cos(i*TAU/facets)*radius,0,sin(i*TAU/facets)*radius*0.60)
			var c := Vector3(cos((i+1)*TAU/facets)*radius,0,sin((i+1)*TAU/facets)*radius*0.60)
			var normal := (b-a).cross(c-a).normalized()
			if normal.dot((a+b+c)/3) < 0:
				var swap := b
				b = c
				c = swap
				normal = -normal
			# Godot front faces are clockwise; keep the independently calculated
			# outward normal while reversing the geometric cross-product order.
			for point in [a,c,b]:
				tool.set_normal(normal)
				tool.set_color(shades[i%4])
				tool.add_vertex(point)
	var model := MeshInstance3D.new()
	model.mesh = tool.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://pet/effects/crystal_prototype.gdshader")
	material.set_shader_parameter("core_radius",radius)
	material.set_shader_parameter("core_height",height)
	model.material_override = material
	if edges:
		var wire := ImmediateMesh.new()
		wire.surface_begin(Mesh.PRIMITIVE_LINES)
		for i in range(facets):
			var point := Vector3(cos(i*TAU/facets)*radius,0,sin(i*TAU/facets)*radius*0.60)
			for tip in [Vector3(0,height,0),Vector3(0,-height,0)]:
				wire.surface_add_vertex(tip)
				wire.surface_add_vertex(point)
		wire.surface_end()
		var rim := MeshInstance3D.new()
		rim.mesh = wire
		var rim_material := StandardMaterial3D.new()
		rim_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rim_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rim_material.albedo_color = Color(0.91,1,0.95,0.10)
		rim.material_override = rim_material
		model.add_child(rim)
	return model
