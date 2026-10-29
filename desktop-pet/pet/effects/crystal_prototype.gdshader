shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform float clock = 0.0;
uniform vec4 core_tint : source_color = vec4(0.7,0.85,0.77,1.0);
uniform float shell_alpha = 0.84;
uniform float core_radius = 0.58;
uniform float core_height = 1.17;
uniform float core_energy = 0.0;
uniform float energy_absorption = 2.3;
uniform float refraction_index = 1.46;
varying vec3 crystal_point;
varying vec3 local_ray;
varying vec3 crystal_normal;

void vertex() {
 crystal_point = VERTEX;
 crystal_normal = NORMAL;
 // Production uses an orthographic camera: every view ray is parallel.
 local_ray = (inverse(MODELVIEW_MATRIX)*vec4(0.0,0.0,-1.0,0.0)).xyz;
}
float grain(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float soft_noise(vec3 p) {
 vec3 cell = floor(p);
 vec3 f = fract(p);
 f = f*f*(3.0-2.0*f);
 float a = mix(grain(cell),grain(cell+vec3(1,0,0)),f.x);
 float b = mix(grain(cell+vec3(0,1,0)),grain(cell+vec3(1,1,0)),f.x);
 float c = mix(grain(cell+vec3(0,0,1)),grain(cell+vec3(1,0,1)),f.x);
 float d = mix(grain(cell+vec3(0,1,1)),grain(cell+vec3(1,1,1)),f.x);
 return mix(mix(a,b,f.y),mix(c,d,f.y),f.z);
}
// A material energy field inside the solid, not an extra glowing stone.
// Integrate through its thickness so the same energy changes with the view.
vec2 internal_energy(vec3 surface, vec3 ray) {
 float step_size = core_radius*1.3/12.0;
 vec2 amount = vec2(0.0);
 for (int i=0;i<12;i++) {
  float distance_in = (float(i)+0.5)*step_size;
  vec3 p = surface+ray*distance_in;
  float vertical = abs(p.y)/core_height;
  float radial = length(vec2(p.x/core_radius,p.z/(core_radius*0.60)));
  if (vertical+radial>1.01) continue;
  float envelope = pow(max(0.0,1.0-vertical),0.65);
  float width = core_radius*(0.065+0.22*envelope);
  float focus = exp(-2.0*pow(p.x/max(width,0.001),2.0)-2.0*pow(p.z/(core_radius*0.28),2.0));
  float heart_distance = abs(p.x)/(core_radius*0.33)+abs(p.y)/(core_height*0.25)+abs(p.z)/(core_radius*0.35);
  focus += exp(-2.0*heart_distance*heart_distance)*0.95;
  float diffuse = exp(-2.5*pow(p.x/(core_radius*0.72),2.0)-2.0*pow(p.z/(core_radius*0.50),2.0));
  float transmission = exp(-distance_in*energy_absorption);
  float current = 0.95+0.05*sin(p.y*9.0-clock*0.8);
  amount += vec2(focus,diffuse)*envelope*transmission*current*step_size*8.0;
 }
 return amount;
}
void fragment() {
 float facing = clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0);
 float rim = pow(1.0-facing,2.4);
 float plane = clamp(dot(normalize(NORMAL),normalize(vec3(-0.45,0.65,0.6)))*0.5+0.5,0.0,1.0);
 float cloud = soft_noise(crystal_point*4.0);
 float micro = soft_noise(crystal_point*55.0);
 vec3 body = mix(core_tint.rgb,vec3(0.80,0.96,0.90),0.25);
 vec3 jade = mix(body*0.80,mix(body,vec3(0.96,1.0,0.97),0.38),plane);
 ALBEDO = jade*(0.96+micro*0.04)*(0.94+cloud*0.10);
 ROUGHNESS = mix(0.30,0.43,micro);
 METALLIC = 0.0;
 SPECULAR = 0.45;
 CLEARCOAT = 0.25;
 CLEARCOAT_ROUGHNESS = 0.22;
 ALPHA = clamp(shell_alpha+plane*0.08+rim*0.04+(cloud-0.5)*0.06,0.1,0.98);
 EMISSION = core_tint.rgb*rim*0.025;
 if (core_energy>0.001) {
  vec3 transmitted_ray = refract(normalize(local_ray),normalize(crystal_normal),1.0/refraction_index);
  vec2 field = internal_energy(crystal_point,normalize(transmitted_ray));
  float core = 1.0-exp(-field.x*core_energy*2.4);
  float scatter = 1.0-exp(-field.y*core_energy*0.8);
  vec3 warm = mix(vec3(1.0,0.57,0.19),vec3(1.0,0.93,0.73),pow(core,0.8));
  ALBEDO = mix(ALBEDO,ALBEDO*vec3(1.08,0.98,0.80),scatter*0.30)*(1.0-core*0.08);
  EMISSION += warm*core*0.85+vec3(0.40,0.26,0.10)*scatter*0.55;
 }
}
