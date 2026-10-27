extends SubViewportContainer

const SKIN = preload("res://pet/skins/warm_jade/view.tscn")
var viewport: SubViewport
var actor: Node2D
var _style := "jade"
var _color := "jade"
var _render_budget := 0.0
var _pending_delta := 0.0

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
	actor = SKIN.instantiate()
	viewport.add_child(actor)
	actor.scale = Vector2.ONE * 0.52
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.set_appearance(_style,_color)
	resized.connect(_center_actor)
	_center_actor()

func _center_actor() -> void:
	if is_instance_valid(actor):
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
		actor.advance_pose(_pending_delta)
		_pending_delta = 0.0
		_render_budget = fmod(_render_budget,1.0/30.0)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_appearance(style: String, color: String) -> void:
	_style = style
	_color = color
	if is_instance_valid(actor): actor.set_appearance(style,color)
	_center_actor()
	if is_instance_valid(viewport) and is_visible_in_tree() and get_window().visible:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_growth(value: float) -> void:
	if is_instance_valid(actor): actor.set_growth(value)
