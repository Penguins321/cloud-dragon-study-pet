extends "res://pet/skins/animals/animal_view.gd"

var skeleton: Skeleton3D
var _native_poses: Dictionary = {}
var _face_bones: Array[int] = []
var _head_look := Vector2.ZERO
var _shadow := MeshInstance3D.new()
var _ground_y := 0.0

func _ready() -> void:
	_look_strength = 0.12
	super._ready()
	if not is_instance_valid(model): return
	skeleton = model.find_children("*","Skeleton3D",true,false)[0]
	for name in ["Head","Mouth","LeftEar","RightEar","LeftEye","RightEye","Tail"]:
		var bone := skeleton.find_bone(name)
		if bone >= 0: _face_bones.append(bone)
	_refine_coat()
	# The imported raw mesh has Z-up bounds, but skinning makes Y-up. Recenter
	# its actual forward extent so spins turn in place instead of orbiting.
	model.position.z = -20.0*model.scale.z
	camera.size = 3.65
	camera.look_at(Vector3(0,0.93,0))
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.45,1.65)
	_shadow.mesh = plane
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://pet/skins/animals/corgi_shadow.gdshader")
	paint.render_priority = -2
	_shadow.material_override = paint
	viewport.add_child(_shadow)
	_ground_y = model.to_global(Vector3(0,-6,0)).y
	_update_shadow()

func _refine_coat() -> void:
	var mesh: MeshInstance3D = model.find_children("*","MeshInstance3D",true,false)[0]
	var source: StandardMaterial3D = mesh.get_active_material(0)
	var arrays := mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var head_bind := -1
	var spine_bind := -1
	for index in mesh.skin.get_bind_count():
		if mesh.skin.get_bind_name(index) == "Head": head_bind = index
		if mesh.skin.get_bind_name(index) == "Spine": spine_bind = index
	# The source head joint has no weighted vertices. Blend the upper coat into
	# that existing joint; imported coordinates have Z up before skin binding.
	var stride := bones.size()/vertices.size()
	for vertex in vertices.size():
		var amount := smoothstep(155.0,260.0,vertices[vertex].z)
		for slot in stride:
			var index := vertex*stride+slot
			if bones[index] != spine_bind or weights[index] <= 0.0: continue
			for free_slot in stride:
				var free_index := vertex*stride+free_slot
				if weights[free_index] > 0.0: continue
				bones[free_index] = head_bind
				weights[free_index] = weights[index]*amount
				weights[index] *= 1.0-amount
				break
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	var coat := ArrayMesh.new()
	coat.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.mesh = coat
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://pet/skins/animals/corgi_fur.gdshader")
	paint.set_shader_parameter("coat_palette",source.albedo_texture)
	mesh.material_override = paint

func advance_pose(delta: float) -> void:
	if not is_instance_valid(skeleton) or not is_visible_in_tree():
		super.advance_pose(delta)
		return
	# Restore before advancing the native clips, including during a crossfade.
	for bone in _native_poses: skeleton.set_bone_pose(bone,_native_poses[bone])
	super.advance_pose(delta)
	for bone in _face_bones: _native_poses[bone] = skeleton.get_bone_pose(bone)
	var action := String(player.current_animation)
	var envelope := smoothstep(0.0,0.18,phase)*(1.0-smoothstep(0.78,1.0,phase))
	var attention := _attention if action in ["idle","look","curious"] else Vector2.ZERO
	_head_look = _head_look.lerp(attention,1.0-exp(-delta*7.0))
	var quiet := 0.4 if _focus or action == "rest" else 1.0
	var yaw := -_head_look.x*0.24
	var pitch := _head_look.y*0.12+sin(_elapsed*1.1)*0.018*quiet
	var tilt := sin(_elapsed*0.85)*0.018*quiet
	if action in ["look","curious"]:
		yaw += sin(phase*TAU)*0.27*envelope
		tilt += 0.08*envelope
	if action == "bow": pitch += 0.16*envelope
	var turn := Basis.from_euler(Vector3(pitch,yaw,tilt))
	var neck := Vector3(0,70,35)
	var head_delta := Transform3D(turn,neck-turn*neck)
	var cycle := fposmod(_elapsed,4.7)
	var blink := pow(maxf(0.0,sin(clampf((cycle-2.8)/0.22,0.0,1.0)*PI)),1.2)
	for bone in _face_bones:
		var name := skeleton.get_bone_name(bone)
		var pose: Transform3D = _native_poses[bone]
		if name == "Tail":
			var wag := (0.18 if action in ["celebrate","dance"] else 0.045)*quiet
			pose.basis *= Basis(Vector3.UP,sin(_elapsed*7.0)*wag)
		else:
			pose = head_delta*pose
			if name.ends_with("Ear"):
				var side := -1.0 if name == "LeftEar" else 1.0
				var twitch := exp(-pow((fposmod(_elapsed+side*0.23,6.1)-4.6)/0.16,2))*0.13
				pose.basis *= Basis.from_euler(Vector3(sin(_elapsed*1.7+side)*0.025,0,side*(twitch+0.035*envelope)*quiet))
			if name.ends_with("Eye"):
				pose.basis = pose.basis.scaled_local(Vector3(1,lerpf(1.0,0.08,blink),1))
		skeleton.set_bone_pose(bone,pose)
	_update_shadow()

func _update_shadow() -> void:
	var feet := model.to_global(Vector3(0,-6,0))
	_shadow.position = Vector3(feet.x,_ground_y,feet.z)
	var height := maxf(0.0,feet.y-_ground_y)
	var spread := 1.0+height*0.35
	_shadow.scale = Vector3(spread,1,spread)
	_shadow.material_override.set_shader_parameter("strength",0.19/(1.0+height*2.5))
