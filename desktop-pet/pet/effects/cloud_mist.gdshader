shader_type canvas_item;
render_mode unshaded;

uniform float mist_time = 0.0;
varying vec4 mist_tint;
varying vec2 mist_position;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float weight = 0.57;
	for (int octave = 0; octave < 3; octave++) {
		value += weight * noise(p);
		p = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6)) * p + vec2(7.3, 3.1);
		weight *= 0.5;
	}
	return value;
}

void vertex() {
	mist_tint = COLOR;
	mist_position = VERTEX;
}

void fragment() {
	float envelope = texture(TEXTURE, UV).a;
	vec2 drift = vec2(-0.18, -0.12) * mist_time;
	vec2 p = UV * 4.5 + mist_position * 0.013 + drift;
	float curl = fbm(p * 0.65 + vec2(0.0, mist_time * 0.09));
	float density = fbm(p + vec2(curl * 2.2, -curl * 1.7));
	float vapor = envelope * smoothstep(0.18, 0.73, density + envelope * 0.38);
	vec3 shade = mix(vec3(0.40, 0.60, 0.55), vec3(0.94, 0.97, 0.91), smoothstep(0.2, 0.8, density));
	COLOR = vec4(shade * mist_tint.rgb, vapor * mist_tint.a);
}
