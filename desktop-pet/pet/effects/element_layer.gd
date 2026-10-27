extends Node2D

const Flame = preload("res://pet/flame_flow.gd")
const Elements = preload("res://pet/element_effects.gd")
var foreground := true
var _painted_phase := -INF
var _painted_style := ""

func _init() -> void:
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://pet/effects/brush_flow.gdshader")
	material = paint

func refresh() -> void:
	var rig := get_parent()
	if rig == null: return
	visible = rig.appearance_style in ["flame","lightning","snow"]
	if not visible: return
	material.set_shader_parameter("clock",rig.phase)
	material.set_shader_parameter("softness",0.34 if rig.appearance_style == "snow" else 0.24)
	# Dense flame fields allow a 1/30s geometry budget at rest. Sparse snow and
	# thin currents update every frame so their native masks remain exact.
	var gesturing: bool = absf(rig.lift)>0.5 or absf(rig.drift)>0.5 or absf(rig.lean)>0.01 or absf(rig.turn)>0.01
	if rig.appearance_style != "flame" or gesturing or rig.appearance_style != _painted_style or rig.phase-_painted_phase >= 1.0/30.0 or rig.phase < _painted_phase:
		_painted_phase = rig.phase
		_painted_style = rig.appearance_style
		queue_redraw()

func _draw() -> void:
	var rig := get_parent()
	if rig == null: return
	match rig.appearance_style:
		"flame": Flame.draw(rig,foreground,self)
		"lightning": Elements.draw_lightning(rig,foreground,self)
		"snow": Elements.draw_snow(rig,foreground,self)
