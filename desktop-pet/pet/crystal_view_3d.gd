extends Node2D

signal failed(message: String)
const Crystal = preload("res://pet/crystal_mesh.gd")
var viewport := SubViewport.new()
var stones: Array[Node3D] = []
var _validated := false
var _checking := false
var _energy_light := OmniLight3D.new()
var motes := preload("res://pet/energy_motes_3d.gd").new()
var _pose_phase := -1.0
var _spatial_active := false
var _space_offsets: Array[Vector3] = []
var _space_rotations: Array[Quaternion] = []

func _init() -> void:
	show_behind_parent = true
	viewport.size = Vector2i(650,750)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.texture = viewport.get_texture()
	sprite.position = Vector2(225,15)
	var composite := CanvasItemMaterial.new()
	composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	sprite.material = composite
	add_child(sprite)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 7.5
	camera.position.z = 8
	viewport.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dcece8")
	environment.environment.ambient_light_energy = 0.40
	viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28,-35,0)
	key.light_color = Color("fff2d6")
	key.light_energy = 0.80
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(35,65,0)
	fill.light_color = Color("b5d9ed")
	fill.light_energy = 0.30
	viewport.add_child(fill)
	for index in range(3):
		var stone := Crystal.build(0.58 if index == 1 else 0.20,1.17 if index == 1 else 0.43,true,6 if index == 1 else 4)
		stones.append(stone)
		viewport.add_child(stone)
	_energy_light.light_color = Color("ffe0a4")
	_energy_light.omni_range = 2.2
	_energy_light.light_energy = 0.35
	viewport.add_child(_energy_light)
	viewport.add_child(motes)

func sync(rig: Node2D) -> void:
	if not visible or not is_visible_in_tree() or not get_window().visible or get_window().mode == Window.MODE_MINIMIZED:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var tint: Color = rig.facet_colors()[2]
	var gain := 0.80 if rig.energy < 0 else 0.30
	var energy: float = maxf(0.12,0.55+rig.energy*gain)*(1.0+0.05*sin(rig.phase*1.31))
	# Focus is a steadier inner light, blended without changing the solid geometry.
	energy = lerpf(energy, 0.48+maxf(0.0,rig.energy)*0.15, rig.focus_blend)
	for index in range(3):
		var origin: Vector2 = rig.parts[index].origin
		stones[index].position = Vector3((origin.x-225)/100.0,-(origin.y-15)/100.0,0)
		stones[index].rotation = Vector3(0,0,-rig.parts[index].get_rotation())
		stones[index].material_override.set_shader_parameter("clock",rig.phase)
		stones[index].material_override.set_shader_parameter("core_tint",tint)
		stones[index].material_override.set_shader_parameter("shell_alpha",0.55 if rig.appearance_style == "glass" else 0.84)
		stones[index].material_override.set_shader_parameter("core_energy",energy if index == 1 else 0.0)
		stones[index].material_override.set_shader_parameter("energy_absorption",0.8 if rig.appearance_style == "glass" else 2.3)
	stones[1].rotation.y = sin(rig.phase*0.6)*0.025
	_apply_spatial_action(rig)
	_blend_spatial_pose(rig)
	_energy_light.position = stones[1].position
	_energy_light.light_energy = energy*0.8
	motes.sync(rig)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if not _validated and not _checking: _validate_output()

func _apply_spatial_action(rig: Node2D) -> void:
	var player: AnimationPlayer = rig.get_node("AnimationPlayer")
	var action := player.current_animation
	if action not in ["orbit","helix","cross_orbit","refract_turn"] or player.current_animation_length<=0: return
	var t := player.current_animation_position/player.current_animation_length
	var progress := smoothstep(0.08,0.92,t)
	var envelope := smoothstep(0.0,0.18,t)*(1.0-smoothstep(0.82,1.0,t))
	var angle := TAU*progress
	if action=="refract_turn":
		stones[1].rotation.y += sin(angle)*0.85
		stones[1].rotation.x = sin(PI*progress)*0.18
		return
	var center := stones[1].position
	for index in [0,2]:
		var side := -1.0 if index==0 else 1.0
		var base: Vector3 = stones[index].position-center
		var radius := lerpf(absf(base.x),1.45,envelope)
		var offset := Vector3(side*radius*cos(angle),base.y,side*radius*sin(angle))
		if action=="helix": offset.y += sin(PI*progress)*0.65
		if action=="cross_orbit":
			offset.z = -radius*sin(angle)
			offset.y += side*sin(angle)*0.60
		stones[index].position = center+offset
		stones[index].rotation.y = angle*side

func _blend_spatial_pose(rig: Node2D) -> void:
	var elapsed: float = clampf(rig.phase-_pose_phase,0.0,0.05) if _pose_phase>=0 else 0.0
	_pose_phase = rig.phase
	var action: String = rig.get_node("AnimationPlayer").current_animation
	var spatial := action in ["orbit","helix","cross_orbit","refract_turn"]
	if not spatial and not _spatial_active: return
	var center := stones[1].position
	if not _spatial_active:
		_space_offsets = [stones[0].position-center,stones[2].position-center]
		_space_rotations.clear()
		for stone in stones: _space_rotations.append(stone.quaternion)
		_spatial_active = true
	var settled := true
	for slot in range(2):
		var index := 0 if slot==0 else 2
		var target: Vector3 = stones[index].position-center
		var previous := _space_offsets[slot]
		var radius := move_toward(Vector2(previous.x,previous.z).length(),Vector2(target.x,target.z).length(),elapsed*3.0)
		var angle := atan2(previous.z,previous.x)
		angle += clampf(angle_difference(angle,atan2(target.z,target.x)),-elapsed*1.8,elapsed*1.8)
		_space_offsets[slot] = Vector3(cos(angle)*radius,move_toward(previous.y,target.y,elapsed*3.0),sin(angle)*radius)
		settled = settled and _space_offsets[slot].distance_to(target)<0.001
	# Interrupted opposing arcs can meet in projection. Anticipate that meeting
	# with a smooth vertical separation rather than crossing through each other.
	var left := _space_offsets[0]
	var right := _space_offsets[1]
	var planar_gap := Vector2(left.x-right.x,left.z-right.z).length()
	var clearance := 0.60*(1.0-smoothstep(0.95,2.0,planar_gap))
	var half_gap := (left.y-right.y)*0.5
	if absf(half_gap)<clearance:
		var middle := (left.y+right.y)*0.5
		var order := -1.0 if half_gap<0 else 1.0
		left.y = middle+order*clearance
		right.y = middle-order*clearance
	stones[0].position = center+left
	stones[2].position = center+right
	for index in range(3):
		var target := stones[index].quaternion
		var distance := _space_rotations[index].angle_to(target)
		_space_rotations[index] = _space_rotations[index].slerp(target,minf(1.0,elapsed*1.8/maxf(0.0001,distance)))
		stones[index].quaternion = _space_rotations[index]
		settled = settled and distance<0.001
	if not spatial and settled: _spatial_active = false

func projected_centers() -> PackedVector2Array:
	var result := PackedVector2Array()
	var camera := viewport.get_camera_3d()
	for stone in stones: result.append(camera.unproject_position(stone.global_position)-Vector2(100,360))
	return result

func _validate_output() -> void:
	_checking = true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not visible or not is_visible_in_tree():
		_checking = false
		return
	var pixels := viewport.get_texture().get_image()
	var found := false
	if pixels != null and not pixels.is_empty():
		for y in range(0,pixels.get_height(),16):
			for x in range(0,pixels.get_width(),16):
				if pixels.get_pixel(x,y).a > 0.02:
					found = true
					break
			if found: break
	_validated = found
	_checking = false
	if not found: failed.emit("3D 画面未能显示，已恢复原版 2D 晶体。")
