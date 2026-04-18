shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 underwater_color : source_color = vec4(0.0, 0.3, 0.5, 0.5); // Deep blue tint
uniform float distortion_speed = 1.5;
uniform float distortion_strength = 0.015;

void fragment() {
	// 1. Calculate a wobbling offset using Sine and the screen's UV coordinates
	vec2 offset = vec2(
		sin(TIME * distortion_speed + UV.y * 10.0) * distortion_strength,
		cos(TIME * distortion_speed + UV.x * 10.0) * distortion_strength
	);
	
	// 2. Read the screen pixels behind the ColorRect, but offset them to warp the image!
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + offset).rgb;
	
	// 3. Mix the warped screen with our deep blue underwater tint
	COLOR.rgb = mix(screen_color, underwater_color.rgb, underwater_color.a);
}