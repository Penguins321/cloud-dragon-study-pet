extends Node2D

signal geometry_changed

var skin: Resource
var current_action: StringName = &"idle"
var actor: Node2D
var player: AnimationPlayer
var _generation := 0
var _enabled := true
var _render_polygons: Array[PackedVector2Array] = []
var _region_samples := PackedVector2Array()
var _interaction_index := -1
const CLICK_ACTIONS: Array[StringName] = [&"swim", &"look", &"stretch", &"rest", &"celebrate", &"breath"]
const PRIORITY := {&"idle": 0, &"swim": 1, &"rest": 1, &"sleepy": 1, &"curious": 2, &"look": 2, &"stretch": 2, &"breath": 2, &"celebrate": 3, &"dragging": 4}

func apply_skin(candidate: Resource) -> Error:
	if candidate == null or candidate.get_script() != preload("res://pet/pet_skin.gd"):
		return ERR_INVALID_DATA
	if candidate.scene == null or candidate.visual_bounds.size.x <= 0 or candidate.visual_bounds.size.y <= 0 or candidate.hit_polygon.size() < 3:
		return ERR_INVALID_DATA
	var next_actor: Node = candidate.scene.instantiate()
	var next_player = next_actor.get_node_or_null(candidate.player_path)
	var idle_name: StringName = candidate.action_map.get(&"idle", &"")
	if not next_actor is Node2D or not next_player is AnimationPlayer or idle_name == &"" or not next_player.has_animation(idle_name):
		next_actor.free()
		return ERR_INVALID_DATA
	_generation += 1
	if is_instance_valid(actor):
		actor.free()
	skin = candidate
	actor = next_actor
	player = next_player
	# Advance first, then refresh the Windows region in the same frame.
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(actor)
	_render_polygons = _texture_coverage(candidate)
	if actor.has_method("prepare_outline"):
		for index in _render_polygons.size():
			_render_polygons[index] = actor.prepare_outline(_render_polygons[index])
	player.animation_finished.connect(_on_finished.bind(_generation))
	_activate(&"idle")
	_interaction_index = -1
	_notify_geometry_changed()
	return OK

func _process(delta: float) -> void:
	if not _enabled or not is_instance_valid(player):
		return
	player.advance(delta)
	if actor.has_method("advance_pose"):
		actor.advance_pose(delta)
	var samples := _get_region_samples()
	# Rendering remains continuous. Rebuild the expensive native region only after
	# half a screen pixel of motion; the alpha padding safely covers this small lag.
	for index in samples.size():
		if samples.size() != _region_samples.size() or samples[index].distance_squared_to(_region_samples[index]) >= 0.25:
			_notify_geometry_changed()
			break

func _scaled_actor_transform() -> Transform2D:
	return Transform2D(actor.transform.x * scale, actor.transform.y * scale, actor.transform.origin * scale)

func _notify_geometry_changed() -> void:
	if is_instance_valid(actor):
		_region_samples = _get_region_samples()
	geometry_changed.emit()

func _get_region_samples() -> PackedVector2Array:
	var points := PackedVector2Array()
	if actor.has_method("region_sample_points"):
		points = actor.region_sample_points()
	else:
		var bounds: Rect2 = skin.visual_bounds
		points = PackedVector2Array([bounds.position, bounds.end, Vector2(bounds.position.x, bounds.end.y), Vector2(bounds.end.x, bounds.position.y)])
	return _scaled_actor_transform() * points

func select_action(action: StringName) -> void:
	if skin == null or not _enabled or current_action == &"dragging":
		return
	var selected: StringName = action if skin.action_map.has(action) else &"idle"
	var index := CLICK_ACTIONS.find(selected)
	if index >= 0:
		_interaction_index = index
	_activate(selected)

func cycle_action() -> StringName:
	if skin == null or not _enabled or current_action == &"dragging":
		return current_action
	for attempt in CLICK_ACTIONS.size():
		_interaction_index = (_interaction_index + 1) % CLICK_ACTIONS.size()
		var action := CLICK_ACTIONS[_interaction_index]
		if skin.action_map.has(action):
			select_action(action)
			break
	return current_action

func play_action(action: StringName) -> void:
	if skin == null:
		return
	if action != &"idle" and PRIORITY.get(action, 1) < PRIORITY.get(current_action, 1):
		return
	var requested: StringName = action
	if not skin.action_map.has(requested) or not player.has_animation(skin.action_map[requested]):
		requested = &"idle"
	if PRIORITY.get(requested, 1) < PRIORITY.get(current_action, 1) and requested != &"idle":
		return
	if requested == current_action and player.is_playing():
		return
	_activate(requested)

func _activate(action: StringName) -> void:
	current_action = action
	player.play(skin.action_map[action], 0.25)
	if not _enabled:
		player.pause()

func _on_finished(_animation: StringName, generation: int) -> void:
	if generation == _generation and current_action != &"idle" and current_action != &"dragging":
		_activate(&"idle")

func set_active(enabled: bool) -> void:
	_enabled = enabled
	set_process(enabled)
	if player:
		if enabled:
			_activate(&"idle")
		else:
			player.pause()

func is_active() -> bool:
	return _enabled

func set_display_scale(value: float) -> void:
	scale = Vector2.ONE * clampf(value, 0.5, 2.0)
	_notify_geometry_changed()

func get_visual_geometry() -> Dictionary:
	if skin == null:
		return {}
	if actor.has_method("sync_pose"):
		actor.sync_pose()
	var polygon := PackedVector2Array()
	for point in skin.hit_polygon:
		polygon.append(map_skin_point(point))
	var render_polygons: Array[PackedVector2Array] = []
	for outline in _render_polygons:
		var transformed := PackedVector2Array()
		for point in outline:
			transformed.append(map_skin_point(point))
		render_polygons.append(transformed)
	return {
		"bounds": Rect2(skin.visual_bounds.position * scale, skin.visual_bounds.size * scale),
		"hit_polygon": polygon,
		"bubble_anchor": skin.bubble_anchor * scale,
		"render_polygons": render_polygons
	}

func map_skin_point(point: Vector2) -> Vector2:
	var deformed: Vector2 = actor.deform_point(point) if actor.has_method("deform_point") else point
	return (actor.transform * deformed) * scale

func _texture_coverage(candidate: Resource) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if candidate.render_texture == null:
		result.append(candidate.hit_polygon.duplicate())
		return result
	var target: Rect2 = candidate.render_rect
	if target.size == Vector2.ZERO:
		target = candidate.visual_bounds
	var image: Image = candidate.render_texture.get_image()
	# The mask needs screen-scale precision, not every pixel of the source artwork.
	# Lanczos retains fine whiskers; alpha coverage is checked against the full source.
	image.resize(mini(image.get_width(), ceili(target.size.x * 2.0)), mini(image.get_height(), ceili(target.size.y * 2.0)), Image.INTERPOLATE_LANCZOS)
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.001)
	# Window input regions also clip rendering on Windows. Include antialias fringes.
	var rectangle := Rect2i(Vector2i.ZERO, image.get_size())
	var factor := target.size / Vector2(image.get_size())
	# At 50% allow 3 screen pixels for native rounding and subpixel update lag.
	bitmap.grow_mask(ceili(3.0 / (0.5 * minf(factor.x, factor.y))), rectangle)
	# Simplification stays below one local pixel; dilation covers its error.
	for outline in bitmap.opaque_to_polygons(rectangle, 1.5):
		var points := PackedVector2Array()
		for point in outline:
			points.append(target.position + point * factor)
		result.append(points)
	return result
