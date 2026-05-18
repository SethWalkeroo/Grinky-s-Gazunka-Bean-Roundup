shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// --- AESTHETIC CONTROLS ---
uniform int color_depth : hint_range(1, 255) = 48; // Slightly higher default for better visibility
uniform float spread : hint_range(0.0, 1.0) = 0.25; // Softer, more controlled pattern
uniform float aberration_amount : hint_range(0.0, 10.0) = 1.0; // RGB Lens splitting
uniform float vignette_size : hint_range(0.1, 2.0) = 1.0; // Higher means pushed further to edges
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.3; // 0.0 is pure black, 1.0 is invisible

// --- VISIBILITY & CINEMATIC GRADING ---
uniform vec4 shadow_tint : source_color = vec4(0.02, 0.05, 0.1, 1.0); // Deep cinematic blue/green
uniform float shadow_lift : hint_range(0.0, 1.0) = 0.2; // Lifts pitch-black into visible moody shadows
uniform float highlight_glow : hint_range(0.0, 1.0) = 0.8; // Keeps fire and flashlights smooth and bright

void fragment() {
    // 1. Chromatic Aberration (Subtle RGB Edge Fringing)
    vec2 offset = vec2(aberration_amount * SCREEN_PIXEL_SIZE.x, 0.0);
    float r = texture(SCREEN_TEXTURE, SCREEN_UV - offset).r;
    float g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
    float b = texture(SCREEN_TEXTURE, SCREEN_UV + offset).b;
    vec3 col = vec3(r, g, b);

    // 2. Luma (Brightness) Calculation
    // We calculate exactly how bright the current pixel is so we can apply smart effects
    float luma = dot(col, vec3(0.299, 0.587, 0.114));

    // 3. Cinematic Shadow Lift (The Visibility Fix!)
    // Blends a rich cinematic color into the darkest areas so they aren't just invisible black noise
    float shadow_mask = 1.0 - smoothstep(0.0, 0.4, luma);
    col = mix(col, col + shadow_tint.rgb * shadow_lift, shadow_mask);

    // 4. Bayer Matrix Setup
    float bayer[16] = float[](
        0.0, 8.0, 2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0, 11.0, 1.0, 9.0,
        15.0, 7.0, 13.0, 5.0
    );
    int x = int(FRAGCOORD.x) % 4;
    int y = int(FRAGCOORD.y) % 4;
    float tex_dither = (bayer[y * 4 + x] / 16.0) - 0.5;

    // 5. Smart Dithering
    // We reduce the dither spread in extreme darks and extreme brights.
    // This keeps the lighting smooth and the shadows legible, while crunching the mid-tones!
    float edge_preservation = smoothstep(0.0, 0.2, luma) * (1.0 - smoothstep(0.8, 1.0, luma));
    float current_spread = spread * edge_preservation;
    col += tex_dither * current_spread;

    // 6. Color Quantization with Highlight Protection
    // Bright lights bypass the retro crunch to look incredibly vibrant
    float glow_mask = smoothstep(0.6, 1.0, luma) * highlight_glow;
    vec3 quantized_col = floor(col * float(color_depth) + 0.5) / float(color_depth);
    
    // Mix the raw smooth color back into the bright highlights
    col = mix(quantized_col, col, glow_mask); 

    // 7. Widescreen-Corrected Vignette
    // Perfectly circular soft fade that draws the eye to the center of the screen, controllable via uniforms
    vec2 aspect_ratio = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
    float dist = distance((SCREEN_UV - 0.5) / aspect_ratio, vec2(0.0));
    float vignette = smoothstep(vignette_size + 0.1, vignette_size - 0.5, dist); 
    col *= mix(1.0 - vignette_opacity, 1.0, vignette);

    // 8. Soft Film Grain
    float noise = fract(sin(dot(SCREEN_UV, vec2(12.9898, 78.233) * TIME)) * 43758.5453);
    col += (noise - 0.5) * 0.015; // Softened grain so it doesn't muddy visibility

    COLOR = vec4(col, 1.0);
}