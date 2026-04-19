shader_type canvas_item;

// --- ALIEN TRACKER COLORS ---
uniform vec4 background_color : source_color = vec4(0.01, 0.05, 0.02, 1.0); // Deep dark green
uniform vec4 grid_color : source_color = vec4(0.05, 0.3, 0.15, 1.0); // Medium green
uniform vec4 sweep_color : source_color = vec4(0.5, 1.0, 0.8, 1.0); // Bright cyan/green flash
uniform vec4 blip_color : source_color = vec4(0.7, 1.0, 0.7, 1.0); // Pure bright green

// --- TRACKER SETTINGS ---
uniform float sweep_progress : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_density = 100.0;

void fragment() {
	// 1. Center the UVs so we can draw circles from the middle
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	
	// 2. Draw the Concentric Grid and Crosshairs
	float grid = 0.0;
	grid += step(0.95, sin(dist * 40.0)); // The rings
	grid += step(0.995, cos(centered_uv.x * 3.14159)); // Vertical crosshair
	grid += step(0.995, cos(centered_uv.y * 3.14159)); // Horizontal crosshair
	
	// 3. The Expanding Sweep Ring
	// Draws a glowing ring exactly at the distance of our sweep_progress
	float ring_thickness = 0.08;
	float sweep_ring = smoothstep(sweep_progress - ring_thickness, sweep_progress, dist) - 
					   smoothstep(sweep_progress, sweep_progress + 0.01, dist);
	
	// 4. Read the frozen camera snapshot!
	vec4 camera_blips = texture(TEXTURE, UV);
	
	// 5. Build the final screen color
	vec3 final_color = background_color.rgb;
	
	// Add the grid to the background
	final_color = mix(final_color, grid_color.rgb, clamp(grid, 0.0, 1.0));
	
	// If the camera saw something (alpha > 0.1), color it bright green!
	if (camera_blips.a > 0.1) {
		// Make it glow extra bright if the sweep ring just passed over it
		float blip_intensity = 1.0;
		if (dist < sweep_progress && dist > sweep_progress - 0.2) {
			blip_intensity = 2.0; 
		}
		final_color = mix(final_color, blip_color.rgb * blip_intensity, camera_blips.a);
	}
	
// ... (Keep the rest of the shader above this exactly the same) ...

	// Add the glowing sweep ring
	final_color += sweep_color.rgb * sweep_ring;
	
	// 6. Old CRT Scanlines
	float scanlines = sin(UV.y * scanline_density * 3.14159) * 0.15 + 0.85;
	final_color *= scanlines;
	
	// WE DELETED THE SHADER MASK! 
	// Your circle_clip node will handle the shape now.
	COLOR = vec4(final_color, 1.0);

}