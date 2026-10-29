extends Node3D

var fields: Array[MultiMeshInstance3D] = []

func _init() -> void:
	for foreground in [false,true]:
		var field := MultiMeshInstance3D.new()
		field.multimesh = MultiMesh.new()
		field.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		field.multimesh.use_custom_data = true
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		field.multimesh.mesh = quad
		field.multimesh.instance_count = 72
		field.multimesh.visible_instance_count = 0
		var paint := ShaderMaterial.new()
		paint.shader = preload("res://pet/effects/energy_mote.gdshader")
		paint.render_priority = 1 if foreground else -1
		field.material_override = paint
		field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		field.custom_aabb = AABB(Vector3(-4,-4,-2),Vector3(8,8,4))
		fields.append(field)
		add_child(field)

func sync(rig: Node2D) -> void:
	var counts := [0,0]
	var count: float = 28.0+44.0*rig._growth
	for index in range(ceili(count)):
		var age: float = fposmod(rig.phase*0.16+index*0.417219,1.0)
		var angle: float = index*2.39996+rig.phase*0.12
		var point: Vector2 = rig._particle_position(index)
		var depth := cos(angle)*0.50
		var front := 1 if depth>=0 else 0
		var opacity: float = pow(sin(age*PI),2)*clampf(count-index,0,1)*(0.50+rig._growth*0.15)
		# Close glints stay restrained so the energy in the main core leads.
		if front == 1 and absf(point.x-rig.parts[1].origin.x)<55: opacity *= 0.25
		var position := Vector3((point.x-225)/100.0,-(point.y-15)/100.0,depth)
		var size: float = 0.14+0.02*rig._growth
		var transform := Transform3D(Basis.IDENTITY.scaled(Vector3(size,size,1)),position)
		fields[front].multimesh.set_instance_transform(counts[front],transform)
		fields[front].multimesh.set_instance_custom_data(counts[front],Color(opacity,1.0 if index%9==0 else 0.0,float(index%3)/2,1))
		counts[front] += 1
	for index in range(2): fields[index].multimesh.visible_instance_count = counts[index]
