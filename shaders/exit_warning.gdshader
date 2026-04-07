shader_type canvas_item;

uniform float wave_speed = 5.0;   // Faster for a "giddy" whimsical feel
uniform float wave_freq = 8.0;    // More ripples across the warning
uniform float wave_width = 3.0;   // Higher bounce
uniform float bounce_x = 2.0;    // Side-to-side "dancing"

void vertex() {
	// Vertical Wave
	VERTEX.y += sin(TIME * wave_speed + VERTEX.x / wave_freq) * wave_width;
	// Horizontal "Wiggle"
	VERTEX.x += cos(TIME * (wave_speed * 0.5) + VERTEX.y / wave_freq) * bounce_x;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	// Maintain the Label's color (so we can change it to Green or Red in code)
	COLOR = tex_color * COLOR;
}