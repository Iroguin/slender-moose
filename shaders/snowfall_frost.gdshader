//Copyright 2024 Emerson Rowland
//MIT License

shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler3D noise_3D;
uniform vec3 snow_color: source_color = vec3(0.79,0.87,0.95);
uniform float frost_amount : hint_range(0.0, 2.0, 0.001) = 0.5;
uniform float frost_fade : hint_range(0.0, 2.0, 0.01) = 1.0;
// How bright frost stays in dark areas. 0 = original (frost darkens toward
// black in shadow), 1 = frost is always full snow_color regardless of lighting.
uniform float frost_brightness : hint_range(0.0, 1.0, 0.01) = 0.75;
uniform float snow_density : hint_range(0.8, 1.0, 0.001) = 0.85;
uniform vec3 snow_velocity = vec3(0.2,-0.3,0.2);
uniform float snow_near_clip : hint_range(0.90, 0.99, 0.0001) = 0.9825;
uniform float snow_far_clip : hint_range(0.991, 1.0, 0.0001) = 0.9975;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;
varying mat4 CAMERA;

//this is extremley expensive, doh! At least we get a large number of cache hits.
vec2 depth_draw_snow(vec2 screen_uv, mat4 inv_projection_matrix,float depth, float time, vec3 velocity, float particle_density,float slice_near,float slice_far,float slice_step,float noise_scale) {
	float p = 0.0;
	float slice_out = 0.0;
	for (float slice_depth = slice_near; p < particle_density && slice_depth < slice_far && slice_depth < depth; slice_depth += slice_step ) {
		//increased step value for this itteration by the difference between the last itteration and the target, dramatically reduces loops needed, provided noise used is smooth
		slice_depth = p < particle_density ? slice_depth + slice_step * (particle_density / (max(p,0.01))) : slice_depth;
		// slice_depth is in standard-Z (0 near .. 1 far); Godot uses reverse-Z,
		// so flip it back before unprojecting to world space.
		vec3 p_ndc = vec3(screen_uv * 2.0 - 1.0, 1.0 - slice_depth);
		vec4 p_world = CAMERA * inv_projection_matrix * vec4(p_ndc, 1.0);
		vec3 p_world_position = p_world.xyz / p_world.w;
		vec3 plane_a = p_world_position;
		p = texture(noise_3D, vec3(plane_a.x * noise_scale + time * velocity.x, plane_a.y * noise_scale + TIME * -velocity.y, plane_a.z * noise_scale + time * velocity.z)).r;
		slice_out = slice_depth;
	}
	return slice_out + slice_step < slice_far && slice_out + slice_step < depth ? vec2(p,slice_out) : vec2(0.0);
}

float Luminance(vec3 L) {
	return 0.299*L.r + 0.587*L.g + 0.114*L.b;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = INV_VIEW_MATRIX;
}


void fragment() {
	//init
	vec3 screen = textureLod(SCREEN_TEXTURE,SCREEN_UV,0).rgb;
	vec3 normal = texture(NORMAL_TEXTURE,SCREEN_UV).xyz * 2.0 - 1.0;
	float lumin = Luminance(screen);
	// Godot Forward+ uses reverse-Z depth (near = 1.0, far = 0.0). This shader
	// was written for standard-Z (near = 0.0, far = 1.0), so convert: keep the
	// raw value for unprojecting to world space, and a flipped value for all the
	// "how far" comparisons and the sky test below.
	float raw_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float depth = 1.0 - raw_depth;          // standard-Z for logic/comparisons
	float depth_out = raw_depth;            // what we write back to DEPTH (reverse-Z)
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	//global screenspace frosting
	float mask = 0.0;
	float snow = 0.0;
	float snow_depth = 1.0;
	if (frost_amount > 0.0){
		mat4 viewTranspose = transpose(VIEW_MATRIX);
		vec3 worldNormal = (viewTranspose * vec4(normal, 0.0)).xyz;
		mask = worldNormal.y;
		float frost_str = ((1.0 - frost_amount) * 2.2 - 1.2);
		mask = smoothstep(frost_str,frost_str + frost_fade,mask);
	}
	if (snow_density <= 0.999){
		vec2 particle = depth_draw_snow(SCREEN_UV,INV_PROJECTION_MATRIX,depth,TIME+(sin(TIME)+1.0)*0.5,snow_velocity,snow_density,snow_near_clip,snow_far_clip,0.000033,0.25);
		snow = particle.x;
		snow_depth -= clamp(particle.y * 100.0 - 99.0,0.0,1.0);
		// particle.y is in standard-Z; flip back to reverse-Z for DEPTH output.
		depth_out = particle.x < 0.5 ? depth_out : (1.0 - particle.y);
	}
	// Break up the frost edge with noise, but only where frost actually exists.
	// (smoothstep can return >0 for mask==0 when the noise edge is negative,
	//  which otherwise frosts distant geometry and reads as fog.)
	float transition_mask_a = textureLod(noise_3D,world_position.xyz*0.025,0).r;
	mask = (depth < 0.99999 && frost_amount > 0.0) ? smoothstep(transition_mask_a,1.0,mask) * mask : 0.0;
	// Frost brightness follows the surface luminance, but never drops below
	// frost_brightness, so frost in shadow/distance stays white instead of black.
	float frost_lum = max(smoothstep(0.0,1.0,lumin * 3.0) * 1.1, frost_brightness);
	vec3 snow_albedo = mix(screen, snow_color * frost_lum, mask);
	snow_albedo = snow > 0.5 ? snow_color * snow_depth : snow_albedo;

	ALBEDO = snow_albedo;
	DEPTH = depth_out;
}
