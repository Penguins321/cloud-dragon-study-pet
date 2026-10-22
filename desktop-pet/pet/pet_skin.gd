extends Resource

@export var id: StringName = &""
@export var scene: PackedScene
@export var action_map: Dictionary = {}
@export var visual_bounds := Rect2(0, 0, 440, 180)
@export var hit_polygon := PackedVector2Array()
@export var bubble_anchor := Vector2(360, 0)
@export var player_path: NodePath = ^"AnimationPlayer"
@export var render_texture: Texture2D
@export var render_rect := Rect2()
