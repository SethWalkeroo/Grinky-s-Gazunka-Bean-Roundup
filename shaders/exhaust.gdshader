shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float vignette_strength : hint_range(0.0, 5.0) = 2.5;
uniform vec4 vignette_color : source_color = vec4(0.05, 0.0, 0.05, 1.0); 
uniform float desaturation : hint_range(0.0, 1.0) = 0.65; 
uniform float pulse_speed : hint_range(0.0, 10.0) = 4.0; 
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.15;

void fragment() {
    vec4 original_color = texture(screen_texture, SCREEN_UV);
    
    float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(luminance);
    vec3 desaturated_color = mix(original_color.rgb, gray, desaturation);
    
    vec2 uv = SCREEN_UV - 0.5;
    float dist = length(uv);
    float throb = sin(TIME * pulse_speed) * pulse_intensity;
    float v = smoothstep(0.8, 0.2 - throb, dist * vignette_strength);
    vec3 final_color = mix(vignette_color.rgb, desaturated_color, v);
    
    // THE FIX: We use COLOR.a to preserve the smooth fade from the GDScript!
    COLOR = vec4(final_color, COLOR.a);
}