shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float strength = 0.19;
void fragment() {
 vec2 p = (UV-0.5)*2.0;
 float r = dot(p,p);
 ALBEDO = vec3(0.17,0.20,0.15);
 ALPHA = exp(-r*3.4)*(1.0-smoothstep(0.65,1.0,r))*strength;
}
