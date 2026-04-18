shader_type spatial;

// --- COLORS & SHINE ---
uniform vec3 albedo : source_color;
uniform vec3 albedo2: source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;

// --- NORMAL MAPS (Surface Ripples) ---
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float noise_scale = 10.0;

// --- VERTEX WAVES (The Big Swells + Chop) ---
uniform sampler2D wave; 
uniform float height_scale = 0.15; // How tall the surface chop is
uniform float swell_speed = 1.0; // Speed of the massive rolling waves
uniform float swell_frequency = 0.05; // Width of the massive rolling waves
uniform float swell_height = 2.0; // How tall the massive rolling waves get

// --- DEPTH & REFRACTION (Underwater visuals) ---
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.02; // Adjusts how violently the water warps the image behind it
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- FOAM ---
uniform float edge_scale = 0.5;
uniform vec3 edge_color : source_color;

varying float height;
varying vec3 world_pos;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// 1. The Big Mathematical Swell (Beautiful rolling waves)
	float swell = sin(world_pos.x * swell_frequency + TIME * swell_speed) * cos(world_pos.z * swell_frequency + TIME * swell_speed) * swell_height;
	
	// 2. The Small Surface Chop (from your noise texture)
	float chop = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r * height_scale;
	
	// 3. Combine them! 
	height = swell + chop;
	VERTEX.y += height;
}

void fragment() {
	// 1. Setup normal maps and waves first, because we need them for refraction!
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	vec2 scaled_uv = world_pos.xz / noise_scale; 
	
	// Unpack normal maps properly (converting from 0..1 to -1..1) for accurate blending
	vec3 n1 = texture(texture_normal, scaled_uv + time).rgb * 2.0 - 1.0;
	vec3 n2 = texture(texture_normal2, scaled_uv + time2).rgb * 2.0 - 1.0;
	vec3 normal_blend = normalize(n1 + n2); 
	
	// --- UPGRADE 1: REFRACTION DISTORTION ---
	// Warp the screen UVs based on our normal map to create real water distortion
	vec2 distorted_screen_uv = SCREEN_UV + (normal_blend.xy * refraction_strength);

	// 2. Read the depth texture
	float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	
	// Convert screen UV and depth texture into view space coordinates
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_tex);
	vec4 view_space = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_space.xyz /= view_space.w;
	
	// Calculate the true distance (in meters) between the water surface and background
	float water_depth = VERTEX.z - view_space.z;
	
	// Apply Beer's Law using the corrected water depth
	float depth_blend = exp((water_depth + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	// Mix shallow and deep colors (Using our new DISTORTED UVs for the screen texture!)
	vec3 screen_color = textureLod(SCREEN_TEXTURE, distorted_screen_uv, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);
	
	// 3. Fresnel reflection
	float fresnel_val = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, fresnel_val);
	
	// --- UPGRADE 2: SOFT EDGE FOAM ---
	// Uses smoothstep for a gorgeous, soft gradient instead of a harsh pixelated line
	float foam_blend = smoothstep(0.0, edge_scale, water_depth);
	vec3 depth_color_adj = mix(edge_color, color, foam_blend);
	
	ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	// Repack normal blend for Godot's NORMAL_MAP slot (convert back to 0..1)
	NORMAL_MAP = normal_blend * 0.5 + 0.5;
}