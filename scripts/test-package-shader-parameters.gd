extends SceneTree

var verifier = load("res://../scripts/verify-macos-fonts.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	create_timer(10.0).timeout.connect(func():
		printerr("Shader parameter regression timed out")
		quit(1)
	)
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Shader defaults require a real rendering backend")
		quit(1)
		return
	if not verifier.has_method("shader_parameter_above"):
		printerr("FAIL: package verifier cannot resolve shader defaults safely")
		quit(1)
		return
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = "shader_type spatial; uniform float refraction_index = 1.46; uniform vec3 tint = vec3(1.0); void fragment() { ALBEDO = tint / refraction_index; }"
	check(verifier.shader_parameter_above(material, &"refraction_index", 1.1), "Shader default must pass without a material override")
	material.set_shader_parameter("refraction_index", 1.0)
	check(not verifier.shader_parameter_above(material, &"refraction_index", 1.1), "Explicit non-refracting override must fail")
	material.set_shader_parameter("refraction_index", 1.6)
	check(verifier.shader_parameter_above(material, &"refraction_index", 1.1), "Valid explicit override must pass")
	material.set_shader_parameter("refraction_index", null)
	check(verifier.shader_parameter_above(material, &"refraction_index", 1.1), "Cleared override must restore the shader default")
	check(not verifier.shader_parameter_above(material, &"missing", 1.1), "Missing uniform must fail without a Nil comparison")
	check(not verifier.shader_parameter_above(material, &"tint", 1.1), "Non-numeric uniform must fail without a type error")
	check(not verifier.shader_parameter_above(ShaderMaterial.new(), &"refraction_index", 1.1), "Missing shader must fail")
	check(not verifier.shader_parameter_above(null, &"refraction_index", 1.1), "Missing material must fail")
	print("PACKAGE SHADER PARAMETERS: ", failures, " failures")
	quit(0 if failures == 0 else 1)
