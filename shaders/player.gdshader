shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float spread : hint_range(0.0, 0.1) = 0.02; // Controls the "softness"

void fragment() {
    vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // 4x4 Bayer Matrix
    float bayer[16] = float[](
        0.0, 8.0, 2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0, 11.0, 1.0, 9.0,
        15.0, 7.0, 13.0, 5.0
    );
    
    int x = int(FRAGCOORD.x) % 4;
    int y = int(FRAGCOORD.y) % 4;
    float tex_dither = bayer[y * 4 + x] / 16.0;
    
    // Instead of rounding the colors harshly, we just "nudge" them
    // This creates the pattern without losing the detail
    vec3 dithered = col.rgb + (tex_dither - 0.5) * spread;
    
	
		// Add this before 'COLOR = ...'
    float vignette = distance(SCREEN_UV, vec2(0.5));
    dithered *= 1.0 - (vignette * 0.5); // Darkens the corners
    
    // Add a tiny bit of animated noise (Grain)
    float noise = (fract(sin(dot(SCREEN_UV ,vec2(12.9898,78.233)*TIME)) * 43758.5453));
    dithered += noise * 0.02;
	
    COLOR = vec4(dithered, col.a);
	

}