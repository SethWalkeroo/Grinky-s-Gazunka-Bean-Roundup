shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform sampler2D noise;
uniform float noiseScale = 20.0;

// --- Wind Uniforms ---
uniform sampler2D wind_noise;      // Separate noise texture for wind patterns
uniform vec2 wind_direction = vec2(1.0, 0.5); // Direction the wind blows
uniform float wind_speed = 1.0;    // How fast the wind moves
uniform float wind_strength = 0.2; // How far the grass bends

// --- NEW: Distance Fade Uniforms ---
uniform float fade_min_distance = 30.0; // Distance where grass starts to dissolve
uniform float fade_max_distance = 40.0; // Distance where grass is completely gone

varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// 1. Calculate a moving offset based on world position and time
	vec2 wind_uv = (worldPos.xz / noiseScale) + (wind_direction * TIME * wind_speed);
	
	// 2. Sample the wind noise (using just the Red channel for a 0.0 to 1.0 value)
	float wind_sample = texture(wind_noise, wind_uv).r;
	
	// 3. Remap noise from [0, 1] to [-1, 1] for back-and-forth movement
	float wind_wave = (wind_sample * 2.0) - 1.0;
	
	// 4. Apply displacement. 
	// (1.0 - UV.y) assumes UV.y is 0.0 at the tip and 1.0 at the base.
	float vertex_mask = 1.0 - UV.y; 
	
	// Offset the X and Z vertex positions based on the wind strength and mask
	VERTEX.x += wind_wave * wind_strength * vertex_mask * wind_direction.x;
	VERTEX.z += wind_wave * wind_strength * vertex_mask * wind_direction.y;
}

void fragment() {
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale).rgb;
	ALBEDO = mix(color, color2, UV.y) * mix(color, color2, noiseLevel.r);
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	
	// --- NEW: Distance Fading (Dithering) Logic ---
	
	// 1. Get the distance from the camera (VERTEX inside fragment() is view-space)
	float dist = length(VERTEX);
	
	// 2. Calculate fade factor (1.0 = fully visible, 0.0 = completely invisible)
	float fade_factor = smoothstep(fade_max_distance, fade_min_distance, dist);
	
	// 3. Generate a screen-space dither pattern based on pixel coordinates
	float dither = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898,78.233))) * 43758.5453123);
	
	// 4. Delete the pixel if its fade factor drops below the randomized dither threshold
	if (fade_factor < dither) {
		discard;
	}
}