extends Node2D

const Elements = preload("res://pet/element_effects.gd")
var foreground := true

func _init() -> void:
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://pet/effects/brush_flow.gdshader")
	material = paint

func refresh() -> void:
	var rig := get_parent()
	if rig == null: return
	visible = rig.appearance_style in ["lightning","snow"]
	if not visible: return
	material.set_shader_parameter("clock",rig.phase)
	material.set_shader_parameter("softness",0.34 if rig.appearance_style == "snow" else 0.24)
	queue_redraw()

func _draw() -> void:
	var rig := get_parent()
	if rig == null: return
	match rig.appearance_style:
		"lightning": Elements.draw_lightning(rig,foreground,self)
		"snow": Elements.draw_snow(rig,foreground,self)
