shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// THE MASTER DIAL: 0.0 is normal, 1.0 is maximum panic
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

// Chromatic Aberration (Color Split)
uniform float max_color_offset : hint_range(0.0, 0.05) = 0.02;

// Wavy Distortion
uniform float wave_speed : hint_range(0.0, 20.0) = 15.0;
uniform float wave_frequency : hint_range(0.0, 50.0) = 25.0;
uniform float max_wave_amplitude : hint_range(0.0, 0.05) = 0.02;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Create a mask so the center stays relatively clear, 
    // but the edges get heavily distorted (tunnel vision)
    float center_dist = distance(uv, vec2(0.5));
    float edge_mask = smoothstep(0.2, 0.8, center_dist);
    
    // 1. Calculate the wavy distortion
    float time_wave = sin(uv.y * wave_frequency + TIME * wave_speed);
    // Apply the wave, scaled by our master intensity dial and the edge mask
    vec2 distorted_uv = uv + vec2(time_wave * max_wave_amplitude * intensity * edge_mask, 0.0);
    
    // 2. Calculate Chromatic Aberration (RGB split)
    float current_offset = max_color_offset * intensity * edge_mask;
    
    // Sample the red channel slightly shifted left, blue slightly shifted right
    float r = texture(screen_texture, distorted_uv + vec2(current_offset, 0.0)).r;
    float g = texture(screen_texture, distorted_uv).g;
    float b = texture(screen_texture, distorted_uv - vec2(current_offset, 0.0)).b;
    
    // Output the corrupted image
    COLOR = vec4(r, g, b, 1.0);
}