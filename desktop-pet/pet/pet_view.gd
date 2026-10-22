extends Node2D

signal geometry_changed

var skin: Resource
var current_action: StringName = &"idle"
var actor: Node2D
var player: AnimationPlayer
var _generation := 0
var _enabled := true
const PRIORITY := {&"idle": 0, &"sleepy": 1, &"curious": 2, &"celebrate": 3, &"dragging": 4}

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
	add_child(actor)
	player.animation_finished.connect(_on_finished.bind(_generation))
	_activate(&"idle")
	geometry_changed.emit()
	return OK

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
	player.play(skin.action_map[action])
	if not _enabled:
		player.pause()

func _on_finished(_animation: StringName, generation: int) -> void:
	if generation == _generation and current_action != &"idle" and current_action != &"dragging":
		_activate(&"idle")

func set_active(enabled: bool) -> void:
	_enabled = enabled
	if player:
		if enabled:
			_activate(&"idle")
		else:
			player.pause()

func set_display_scale(value: float) -> void:
	scale = Vector2.ONE * clampf(value, 0.5, 2.0)
	geometry_changed.emit()

func get_visual_geometry() -> Dictionary:
	if skin == null:
		return {}
	var polygon := PackedVector2Array()
	for point in skin.hit_polygon:
		polygon.append(point * scale)
	return {
		"bounds": Rect2(skin.visual_bounds.position * scale, skin.visual_bounds.size * scale),
		"hit_polygon": polygon,
		"bubble_anchor": skin.bubble_anchor * scale
	}
