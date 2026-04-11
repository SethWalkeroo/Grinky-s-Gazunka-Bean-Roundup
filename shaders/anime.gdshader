shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_count = 60.0;
uniform float speed = 15.0;
uniform float center_radius = 0.2;
uniform float edge_blur = 0.4;

void fragment() {
    vec2 uv = UV - 0.5;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    float noise = fract(sin(floor(angle * line_count) * 12.9898 + TIME * speed) * 43758.5453);
    float mask = smoothstep(center_radius, center_radius + edge_blur, radius);
    float is_line = step(0.85, noise);

    // 1. Save the alpha that your GDScript is smoothly fading!
    float script_fade = COLOR.a; 

    // 2. Apply your custom white color
    COLOR = line_color;
    
    // 3. Multiply your shapes by the script's smooth fade
    COLOR.a = is_line * mask * script_fade;
}