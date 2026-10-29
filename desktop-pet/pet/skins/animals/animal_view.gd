extends Node2D

signal renderer_failed(message: String)
@export var model_id := "corgi"
var phase := 0.0
var viewport := SubViewport.new()
var camera := Camera3D.new()
var pivot := Node3D.new()
var model: Node3D
var native_player: AnimationPlayer
var player := AnimationPlayer.new()
var _elapsed := 0.0
var _native_clip := ""
var _regions: Array[PackedVector2Array] = []
var _capture_clock := 0.0
var _capturing := false
var _focus := false
var _attention := Vector2.ZERO
var _base_rotation := -0.42
const ORIGIN := Vector2(60,-40)
const NATIVE_CYCLE := 29.0/24.0
const LENGTHS := {"idle":NATIVE_CYCLE*4,"walk":NATIVE_CYCLE*4,"look":NATIVE_CYCLE*3,"curious":NATIVE_CYCLE*3,"jump":NATIVE_CYCLE*2,"celebrate":NATIVE_CYCLE*3,"rest":NATIVE_CYCLE*4,"breath":NATIVE_CYCLE*4,"bow":NATIVE_CYCLE*3,"spin":NATIVE_CYCLE*4,"dance":NATIVE_CYCLE*4,"dragging":NATIVE_CYCLE*2}

func _init() -> void:
	player.name = "AnimationPlayer"
	add_child(player)
	var library := AnimationLibrary.new()
	for action: String in LENGTHS:
		var animation := Animation.new()
		animation.length = LENGTHS[action]
		animation.loop_mode = Animation.LOOP_LINEAR if action in ["idle","dragging"] else Animation.LOOP_NONE
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(".:phase"))
		animation.track_insert_key(track,0.0,0.0)
		animation.track_insert_key(track,animation.length,1.0)
		library.add_animation(action,animation)
	player.add_animation_library("",library)

func _ready() -> void:
	viewport.name = "AnimalViewport"
	viewport.size = Vector2i(320,340)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.texture = viewport.get_texture()
	sprite.position = ORIGIN + Vector2(viewport.size)*0.5
	var composite := CanvasItemMaterial.new()
	composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	sprite.material = composite
	add_child(sprite)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 4.2
	camera.position = Vector3(0,1.95,6)
	viewport.add_child(camera)
	camera.look_at(Vector3(0,0.80,0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dce7ef")
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32,-32,0)
	key.light_color = Color("fff1de")
	key.light_energy = 1.0
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10,130,0)
	fill.light_energy = 0.4
	viewport.add_child(fill)
	viewport.add_child(pivot)
	var names := {"corgi":"Corgi","duck":"Duck","jellyfish":"Jellyfish"}
	var resource = load("res://pet/skins/animals/models/"+names.get(model_id,"Corgi")+".glb")
	if not resource is PackedScene:
		renderer_failed.emit.call_deferred("无法载入动物模型："+model_id)
		return
	model = resource.instantiate()
	pivot.add_child(model)
	native_player = _find_player(model)
	if native_player:
		native_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for clip in native_player.get_animation_list():
			if clip != "RESET": native_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		_play_native("idle")
		native_player.advance(0.0)
	var bounds := _model_aabb(model)
	var longest := maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	var factor := 2.10/maxf(0.001,longest)
	model.scale *= factor
	model.position -= bounds.get_center()*factor
	pivot.rotation.y = _base_rotation
	_update_envelopes()

func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_player(child)
		if found: return found
	return null

func _model_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var initialized := false
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		var box := mesh.get_aabb()
		var transform := node.global_transform.affine_inverse()*mesh.global_transform
		for index in 8:
			var point := transform*box.get_endpoint(index)
			if not initialized:
				result = AABB(point,Vector3.ZERO)
				initialized = true
			else: result = result.expand(point)
	return result

func _play_native(requested: String) -> void:
	if not native_player or _native_clip == requested: return
	for clip in native_player.get_animation_list():
		if clip.to_lower().get_file() == requested or clip.to_lower().ends_with(requested):
			native_player.play(clip,0.22)
			_native_clip = requested
			return

func advance_pose(delta: float) -> void:
	if not is_visible_in_tree():
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_elapsed += delta
	if not is_instance_valid(model): return
	var action := String(player.current_animation)
	_play_native("walk" if action in ["walk","dance","celebrate"] else "idle")
	if native_player: native_player.advance(delta* (0.4 if _focus or action == "rest" else 1.0))
	var t := clampf(phase,0.0,1.0)
	var envelope := smoothstep(0.0,0.18,t)*(1.0-smoothstep(0.78,1.0,t))
	var rise := sin(PI*t)
	var offset := Vector3.ZERO
	var rotation := Vector3(0,_base_rotation,0)
	var breath := sin(_elapsed*2.2)*0.025
	offset.y = breath
	if model_id == "jellyfish": offset.y += sin(_elapsed*1.7)*0.08
	match action:
		"walk":
			offset.x = sin(TAU*t)*0.24*envelope
			rotation.y += sin(TAU*t)*0.16*envelope
		"look", "curious":
			rotation.y += sin(TAU*t)*0.5*envelope
			rotation.z = sin(PI*t)*0.07*envelope
		"jump":
			offset.y += -0.07*sin(PI*minf(t/0.2,1.0)) if t<0.2 else sin(PI*clampf((t-0.2)/0.65,0.0,1.0))*0.55
			rotation.x = sin(TAU*t)*0.08*envelope
		"celebrate", "dance":
			offset.y += absf(sin(TAU*t*2))*0.12*envelope
			rotation.y += sin(TAU*t*2)*0.3*envelope
			rotation.z = sin(TAU*t*2)*0.07*envelope
		"rest":
			offset.y -= 0.12*envelope
			rotation.z = 0.07*envelope
		"breath": offset.y += rise*0.10
		"bow":
			rotation.x = 0.22*envelope
			offset.y -= 0.08*envelope
		"spin": rotation.y += TAU*smoothstep(0.12,0.88,t)
		"dragging":
			offset.y += 0.15
			rotation.z = sin(_elapsed*2.0)*0.06
	rotation.y += _attention.x*0.08
	pivot.position = pivot.position.lerp(offset,1.0-exp(-delta*14.0))
	pivot.quaternion = pivot.quaternion.slerp(Quaternion.from_euler(rotation),1.0-exp(-delta*12.0))
	_capture_clock += delta
	if _capture_clock >= 0.05 and not _capturing and DisplayServer.get_name() != "headless":
		_capture_clock = 0.0
		_capture_alpha()
	if _regions.is_empty(): _update_envelopes()

func _capture_alpha() -> void:
	_capturing = true
	# The bound callable disconnects automatically if a skin is freed mid-frame.
	# A suspended method could otherwise resume after its actor was destroyed.
	RenderingServer.frame_post_draw.connect(_read_alpha, CONNECT_ONE_SHOT)

func _read_alpha() -> void:
	_capturing = false
	if not is_inside_tree() or not is_instance_valid(viewport): return
	var image := viewport.get_texture().get_image()
	if image and not image.is_empty():
		image.resize(160,170,Image.INTERPOLATE_BILINEAR)
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,0.012)
		var rect := Rect2i(0,0,160,170)
		# 12 local pixels cover antialiasing and mask latency during native limb motion.
		bitmap.grow_mask(6,rect)
		var captured: Array[PackedVector2Array] = []
		for outline in bitmap.opaque_to_polygons(rect,1.5):
			var points := PackedVector2Array()
			for point in outline: points.append(ORIGIN+point*2.0)
			captured.append(points)
		if not captured.is_empty(): _regions = captured
	_capturing = false

func _update_envelopes() -> void:
	# Before the first rendered alpha mask, a rounded body envelope permits startup.
	var polygon := PackedVector2Array()
	var center := Vector2(220,130)
	var radius := Vector2(120,125)
	for index in 24:
		var angle := TAU*float(index)/24.0
		polygon.append(center+Vector2(cos(angle),sin(angle))*radius)
	_regions = [polygon]

func render_regions() -> Array[PackedVector2Array]:
	return _regions

func region_sample_points() -> PackedVector2Array:
	var result := PackedVector2Array()
	for polygon in _regions:
		for point in polygon: result.append(point)
	if is_instance_valid(pivot) and camera.is_inside_tree():
		result.append(ORIGIN+camera.unproject_position(pivot.global_position))
	return result

func set_appearance(_style: String, _color: String) -> void:
	pass
func set_render_mode(_mode: String) -> void:
	pass
func set_growth(_value: Variant) -> void:
	pass
func set_focus_mode(value: bool) -> void:
	_focus = value
func set_desktop_attention(value: Vector2) -> void:
	_attention = value.limit_length(1.0)
