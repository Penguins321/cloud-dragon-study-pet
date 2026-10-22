shader_type canvas_item;
uniform float flow_phase = 0.0;
uniform float strength = 0.0;
uniform float blink = 0.0;
uniform sampler2D closed_eye : source_color, filter_linear;
varying vec4 instance_tint;

void vertex() {
	instance_tint = COLOR;
}

void fragment() {
	vec2 bind = UV * vec2(440.0, 175.95562);
	// Only the visible eye changes; skull, brow, antlers and source alpha stay intact.
	vec2 eye = (UV * vec2(1983.0, 793.0) - vec2(1798.0, 249.0)) / vec2(55.0, 44.0);
	float eye_mask = 1.0 - smoothstep(0.72, 1.0, length((eye - vec2(0.5)) * 2.0));
	if (blink > 0.001 && eye_mask > 0.001) {
		vec2 lid_uv = (vec2(846.0, 580.0) + eye * vec2(156.0, 111.0)) / vec2(1254.0);
		vec4 lid = texture(closed_eye, lid_uv);
		COLOR.rgb = mix(COLOR.rgb, lid.rgb * instance_tint.rgb, blink * eye_mask * lid.a);
	}
	float flame = (1.0 - smoothstep(70.0, 112.0, bind.x)) * (1.0 - smoothstep(98.0, 126.0, bind.y));
	float shimmer = 0.09 * sin(flow_phase * 4.0 - bind.y * 0.08) + 0.04 * sin(flow_phase * 7.0 + bind.x * 0.11);
	COLOR.rgb *= 1.0 + flame * strength * shimmer;
}
