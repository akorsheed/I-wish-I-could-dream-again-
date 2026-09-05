shader_type spatial;
render_mode diffuse_lambert, depth_draw_opaque, cull_back;

// 2.5D background oil painting texture sampled in screen space
uniform sampler2D painted_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 base_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float texture_strength : hint_range(0.0, 1.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float canvas_grain : hint_range(0.0, 0.2) = 0.02;
uniform float canvas_scale : hint_range(50.0, 1000.0) = 500.0;

// High-frequency hash for subtle canvas weave
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	// Sample the pre-rendered / painted background in screen space
	vec4 tex_color = texture(painted_texture, SCREEN_UV);
	
	// Subtle canvas texture
	float grain = (hash21(SCREEN_UV * canvas_scale) - 0.5) * canvas_grain;
	
	// Blend texture with base tint
	vec3 final_color = mix(base_tint.rgb, tex_color.rgb, texture_strength);
	final_color += grain;
	
	ALBEDO = clamp(final_color, vec3(0.0), vec3(1.0));
	ROUGHNESS = roughness;
	SPECULAR = 0.0;
}
