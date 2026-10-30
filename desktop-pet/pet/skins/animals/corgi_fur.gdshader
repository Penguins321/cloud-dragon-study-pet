shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D coat_palette : source_color, filter_linear_mipmap, repeat_disable;
varying float coat_height;
varying vec3 coat_point;
varying float paw_face;
void vertex() {
 coat_height = VERTEX.z;
 coat_point = VERTEX;
 paw_face = smoothstep(0.5,0.85,-NORMAL.y);
}
void fragment() {
 vec3 base = texture(coat_palette, UV).rgb;
 float lightness = max(base.r,max(base.g,base.b));
 float cream = smoothstep(0.48,0.8,min(base.r,min(base.g,base.b)));
 float gold = smoothstep(0.04,0.23,base.r-base.b)*(1.0-cream);
 vec3 warm = mix(base,base*vec3(1.04,0.87,0.70),gold*0.38);
 warm = mix(warm,base*vec3(1.0,0.97,0.90),cream*0.6);
 float lower_coat = mix(0.82,1.0,smoothstep(0.0,220.0,coat_height));
 // Two shallow toe seams stay attached to each front-facing paw surface.
 float seam = 1.0-smoothstep(1.0,3.0,abs(abs(abs(coat_point.x)-66.4)-11.0));
 float paw = (1.0-smoothstep(15.0,30.0,coat_height))*paw_face;
 ALBEDO = warm*lower_coat*(1.0-seam*paw*0.16);
 float dark_feature = 1.0-smoothstep(0.04,0.16,lightness);
 ROUGHNESS = mix(0.88,0.30,dark_feature);
 SPECULAR = mix(0.28,0.55,dark_feature);
 AO = mix(0.84,1.0,smoothstep(10.0,180.0,coat_height));
}
