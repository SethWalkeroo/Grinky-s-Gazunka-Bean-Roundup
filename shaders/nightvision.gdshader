shader_type canvas_item;

// Grabs the screen behind the ColorRect
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float noise_amount = 0.08;
uniform float brightness_multiplier = 2.5; // Cranks up the exposure
uniform vec4 nv_color : source_color = vec4(0.55, 0.15, 0.95, 1.0); // Updated to a vibrant purple

// Generates TV static
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;

    // 1. Convert the screen to greyscale (luminance)
    float lum = dot(screen_color, vec3(0.299, 0.587, 0.114));

    // 2. Artificially blow out the exposure to mimic light-gathering tubes
    lum *= brightness_multiplier;

    // 3. Tint it purple
    vec3 final_color = nv_color.rgb * lum;

    // 4. Add film grain/static that constantly shifts with TIME
    float noise = random(SCREEN_UV + vec2(TIME, -TIME)) * noise_amount;
    final_color += noise;

    // 5. Add horizontal scanlines
    float scanline = sin(SCREEN_UV.y * 800.0) * 0.04;
    final_color -= scanline;

    // 6. Add a heavy vignette (darkens the corners like viewing through goggles)
    float dist = distance(SCREEN_UV, vec2(0.5));
    final_color *= smoothstep(0.8, 0.25, dist);

    COLOR = vec4(final_color, 1.0);
}