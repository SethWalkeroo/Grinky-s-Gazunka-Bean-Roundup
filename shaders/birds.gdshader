shader_type spatial;
// --- ADDED depth_draw_opaque FOR CRISP TRANSPARENCY ---
render_mode cull_disabled, unshaded, depth_draw_opaque; 

uniform sampler2D bird_texture : source_color, filter_nearest;
uniform vec4 bird_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Defaults to pure white!

uniform float flap_speed = 15.0;
uniform float flap_strength = 0.5;

void vertex() {
	float random_offset = float(INSTANCE_ID);
	float timing = (TIME * flap_speed) + random_offset;
	float flap = sin(timing) * flap_strength;
	VERTEX.y += abs(VERTEX.x) * flap;
}

void fragment() {
	vec4 tex = texture(bird_texture, UV);
	
	// Multiply the texture by your custom color
	ALBEDO = tex.rgb * bird_color.rgb;
	
	// --- THE ALPHA SCISSOR ---
	// If a pixel is mostly transparent, delete it entirely. Otherwise, draw it solid!
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5; 
}