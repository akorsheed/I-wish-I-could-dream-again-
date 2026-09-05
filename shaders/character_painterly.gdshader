shader_type spatial;
render_mode diffuse_lambert, depth_draw_opaque, cull_back;

// Stylized painterly palette
uniform vec4 albedo_color : source_color = vec4(0.9, 0.85, 0.8, 1.0); // Clear bright baseline tone
uniform vec4 shadow_color : source_color = vec4(0.2, 0.22, 0.28, 1.0); // Moody cool shadow
uniform vec4 highlight_color : source_color = vec4(1.0, 0.96, 0.88, 1.0); // Warm painterly highlight

// Stepped lighting parameters
uniform int light_steps : hint_range(2, 6) = 3;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.38;
uniform float shadow_boundary_width : hint_range(0.02, 0.3) = 0.12;

// Screen-space noise along shadow edge
uniform float noise_scale : hint_range(50.0, 600.0) = 280.0;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.22;
uniform float canvas_grain : hint_range(0.0, 0.1) = 0.04;

// Procedural hash and value noise in screen space
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float screen_noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.0;
}

void light() {
	// Half-Lambert lighting calculation
	float NdotL = dot(NORMAL, LIGHT);
	float half_lambert = clamp(NdotL * 0.5 + 0.5, 0.0, 1.0);
	
	// Incorporate real-time shadow attenuation
	float raw_light = half_lambert * ATTENUATION;
	
	// Screen-space noise jitter
	vec2 screen_coord = SCREEN_UV * noise_scale;
	float n = screen_noise(screen_coord) * 2.0 - 1.0;
	
	// Focus noise specifically around the shadow boundary terminator
	float dist_to_boundary = abs(raw_light - shadow_threshold);
	float boundary_weight = exp(-pow(dist_to_boundary / shadow_boundary_width, 2.0));
	
	// Apply painterly edge jitter
	float jittered_light = raw_light + n * noise_strength * boundary_weight;
	jittered_light = clamp(jittered_light, 0.0, 1.0);
	
	// Stepped lighting (quantization into discrete painterly value bands)
	float steps_f = float(light_steps);
	float stepped = floor(jittered_light * steps_f) / (steps_f - 1.0);
	stepped = clamp(stepped, 0.0, 1.0);
	
	// Surface canvas grain
	float grain = (hash21(SCREEN_UV * noise_scale * 1.5) - 0.5) * canvas_grain;
	
	// Palette gradient: shadow_color -> albedo -> highlight_color
	vec3 lit_color;
	if (stepped < 0.5) {
		lit_color = mix(shadow_color.rgb, ALBEDO, stepped * 2.0);
	} else {
		lit_color = mix(ALBEDO, highlight_color.rgb, (stepped - 0.5) * 2.0);
	}
	
	// Accumulate diffuse light with ambient floor term
	DIFFUSE_LIGHT += ALBEDO * max(stepped * LIGHT_COLOR * ATTENUATION, vec3(0.25));
}
