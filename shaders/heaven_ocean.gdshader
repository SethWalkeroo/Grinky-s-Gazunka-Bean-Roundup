shader_type spatial;

// --- THE COLORS & SHINE ---
uniform vec3 albedo : source_color = vec3(0.0, 0.32, 0.43);
uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;

// --- THE MASSIVE PHYSICAL WAVES ---
uniform float wave_speed = 1.0;
uniform float wave_height = 2.5; // How tall the waves get!
uniform float wave_frequency = 0.1; // How wide the waves are

// --- THE SURFACE RIPPLES (Normal Maps) ---
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0, 0.0); // Direction of ripple 1
uniform vec2 wave_direction2 = vec2(0.0, 2.0); // Direction of ripple 2
uniform float time_scale = 0.02; // How fast the ripples slide

void vertex() {
	// Calculate a physical wave using Sine and Cosine math
	float height = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * cos(VERTEX.z * wave_frequency + TIME * wave_speed);
	
	// Physically push the geometry up and down!
	VERTEX.y += height * wave_height;
}

void fragment() {
	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	// Scroll two different normal maps in different directions
	vec2 time_offset1 = TIME * wave_direction * time_scale;
	vec2 time_offset2 = TIME * wave_direction2 * time_scale;
	
	// Blend them together to create chaotic, beautiful, non-repeating water tension
	vec3 normal_blend = mix(texture(texture_normal, UV + time_offset1).rgb, texture(texture_normal2, UV + time_offset2).rgb, 0.5);
	
	NORMAL_MAP = normal_blend;
}