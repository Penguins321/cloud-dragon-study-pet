shader_type canvas_item;

// RGB shimmer only: source alpha and the CPU/GPU coverage mapping remain identical.
// Explicit phase pauses with the pet; TIME would keep running while hidden.
uniform float flow_phase = 0.0;
uniform float strength = 0.0;

void fragment() {
	vec2 bind = UV * vec2(440.0, 178.86179);
	float flame = (1.0 - smoothstep(54.0, 62.0, bind.x)) * (1.0 - smoothstep(70.0, 84.0, bind.y));
	float shimmer = 0.09 * sin(flow_phase * 4.0 - bind.y * 0.08) + 0.04 * sin(flow_phase * 7.0 + bind.x * 0.11);
	COLOR.rgb *= 1.0 + flame * strength * shimmer;
}
