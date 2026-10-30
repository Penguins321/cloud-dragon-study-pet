extends SubViewportContainer

const SkinCatalog = preload("res://pet/skin_catalog.gd")
var viewport: SubViewport
var actor: Node2D
var _style := "jade"
var _color := "jade"
var _render_budget := 0.0
var _pending_delta := 0.0
var _skin_id := "warm_jade"
var _skin: Resource
var _player: AnimationPlayer
var _growth := 0.0
var render_mode := "3d"

func _ready() -> void:
	custom_minimum_size = Vector2(0,190)
	stretch = true
	# Transparent viewport textures already contain premultiplied alpha.
	# Applying it again darkens the crystal and the soft particles.
	var composite := CanvasItemMaterial.new()
	composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	material = composite
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	_replace_actor()
	resized.connect(_center_actor)
	_center_actor()

func _center_actor() -> void:
	if is_instance_valid(actor):
		if _skin_id != "warm_jade":
			var bounds: Rect2 = _skin.visual_bounds
			var zoom := minf(0.75,minf(maxf(1.0,size.x-24.0)/bounds.size.x,170.0/bounds.size.y))
			actor.scale = Vector2.ONE*zoom
			actor.position = Vector2(size.x*0.5,95)-bounds.get_center()*zoom
			return
		var zoom := 0.43 if _style in ["flame","lightning"] else (0.44 if _style == "snow" else 0.52)
		actor.scale = Vector2.ONE*zoom
		actor.position = Vector2(size.x*0.5-220.0*zoom,(116.0 if _style in ["flame","lightning"] else 100.0)-133.0*zoom)

func _process(delta: float) -> void:
	if not is_instance_valid(viewport): return
	var active := is_visible_in_tree() and get_window().visible
	if not active:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_render_budget = 0.0
		_pending_delta = 0.0
		return
	_render_budget += minf(delta,0.05)
	_pending_delta += minf(delta,0.05)
	if _render_budget >= 1.0/30.0:
		if _skin_id != "warm_jade" and is_instance_valid(_player): _player.advance(_pending_delta)
		if actor.has_method("advance_pose"): actor.advance_pose(_pending_delta)
		_pending_delta = 0.0
		_render_budget = fmod(_render_budget,1.0/30.0)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_appearance(style: String, color: String) -> void:
	_style = style
	_color = color
	if is_instance_valid(actor) and actor.has_method("set_appearance"): actor.set_appearance(style,color)
	_center_actor()
	if is_instance_valid(viewport) and is_visible_in_tree() and get_window().visible:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_render_mode(mode: String) -> void:
	render_mode = mode
	if is_instance_valid(actor) and actor.has_method("set_render_mode"): actor.set_render_mode(mode)

func set_growth(value: float) -> void:
	_growth = value
	if is_instance_valid(actor) and actor.has_method("set_growth"): actor.set_growth(value)

func set_skin(id: String) -> void:
	var selected := SkinCatalog.skin_id(id)
	if selected == _skin_id and is_instance_valid(actor): return
	_skin_id = selected
	if is_instance_valid(viewport): _replace_actor()

func _replace_actor() -> void:
	if is_instance_valid(actor): actor.free()
	_skin = SkinCatalog.load_skin(_skin_id)
	actor = _skin.scene.instantiate()
	viewport.add_child(actor)
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	_player = actor.get_node_or_null(_skin.player_path) as AnimationPlayer
	if _skin_id != "warm_jade" and is_instance_valid(_player):
		_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_player.play(_skin.action_map.get(&"idle", &"idle"))
		_player.advance(0)
	if actor.has_method("set_appearance"): actor.set_appearance(_style,_color)
	if actor.has_method("set_growth"): actor.set_growth(_growth)
	if actor.has_method("set_render_mode"): actor.set_render_mode(render_mode)
	_center_actor()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
