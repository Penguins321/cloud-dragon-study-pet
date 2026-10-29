shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying vec4 state;
void vertex() { state = INSTANCE_CUSTOM; }
void fragment() {
 vec2 p = (UV-0.5)*2.0;
 float radius = length(p);
 float halo = exp(-radius*radius*5.5)*0.12;
 float dot_light = exp(-radius*radius*95.0);
 float star = exp(-abs(p.x)*70.0-abs(p.y)*9.0)+exp(-abs(p.y)*70.0-abs(p.x)*12.0);
 ALBEDO = mix(vec3(0.65,0.91,0.84),vec3(1.0,0.91,0.67),state.b);
 ALPHA = (halo+dot_light*0.8+star*state.g*0.18)*state.r*(1.0-smoothstep(0.65,1.0,radius));
}
