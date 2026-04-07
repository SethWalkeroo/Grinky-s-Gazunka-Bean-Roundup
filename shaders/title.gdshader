shader_type canvas_item;

uniform float wave_speed : hint_range(0.0, 10.0) = 3.0;
uniform float wave_freq : hint_range(1.0, 100.0) = 10.0;
uniform float wave_width : hint_range(0.0, 20.0) = 2.0;
uniform float smoothing : hint_range(0.0, 1.0) = 0.1; // Adjust this for blurriness

void vertex() {
	// Vertical wave movement
	VERTEX.y += sin(TIME * wave_speed + VERTEX.x / wave_freq) * wave_width;
}

void fragment() {
	// Get the texture coordinates
	vec4 tex_color = texture(TEXTURE, UV);
	
	// --- ANTI-ALIASING LOGIC ---
	// smoothstep creates a soft transition between the letter and the background
	// This removes the "harsh" jagged edges.
	float alpha = smoothstep(0.0, smoothing, tex_color.a);
	
	// Apply the rainbow (COLOR) and the new smoothed alpha
	COLOR = vec4(tex_color.rgb * COLOR.rgb, alpha * COLOR.a);
}