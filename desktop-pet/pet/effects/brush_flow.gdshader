shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
uniform float softness = 0.24;
varying vec2 brush_position;

void vertex() {
	brush_position = VERTEX;
}

void fragment() {
	vec2 p = brush_position * 0.09;
	float curl = sin(p.y * 0.73 - clock * 1.6) + sin(p.x * 0.61 + clock * 0.47);
	float fiber = sin(p.x * 1.72 + p.y * 0.46 + curl * 1.4 - clock * 0.83);
	float fleck = sin(p.y * 2.17 - p.x * 0.81 + curl - clock * 2.1);
	float wash = clamp(0.64 + fiber * 0.23 + fleck * 0.13, 0.0, 1.0);
	vec4 paint = COLOR * texture(TEXTURE, UV);
	paint.rgb *= 0.95 + wash * 0.10;
	paint.a *= mix(1.0 - softness, 1.0, wash);
	COLOR = paint;
}
