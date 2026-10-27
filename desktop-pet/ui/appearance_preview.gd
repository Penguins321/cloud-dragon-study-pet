extends SubViewportContainer

const SKIN = preload("res://pet/skins/warm_jade/view.tscn")
var viewport: SubViewport
var actor: Node2D
var _style := "jade"
var _color := "jade"

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
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
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
		actor.position = Vector2(size.x * 0.5 - 220.0 * 0.52, 100.0 - 133.0 * 0.52)

func _process(delta: float) -> void:
	if not is_instance_valid(viewport): return
	var active := is_visible_in_tree() and get_window().visible
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if active else SubViewport.UPDATE_DISABLED
	if active:
		actor.advance_pose(minf(delta,0.05))

func set_appearance(style: String, color: String) -> void:
	_style = style
	_color = color
	if is_instance_valid(actor): actor.set_appearance(style,color)

func set_growth(value: float) -> void:
	if is_instance_valid(actor): actor.set_growth(value)
