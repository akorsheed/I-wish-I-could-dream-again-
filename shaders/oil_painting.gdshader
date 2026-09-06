shader_type canvas_item;
render_mode unshaded;

// Screen texture sampler for post-processing in Godot 4
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

// Kuwahara filter radius (radius 2 provides a refined, fine-tuned painterly impasto finish)
uniform int radius : hint_range(1, 5) = 2;

// Color saturation & vibrancy boost for painterly oil pigments
uniform float color_boost : hint_range(1.0, 1.3) = 1.05;

// Corner darkening for moody chiaroscuro contrast
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;

// Optional canvas / linen grain texture
uniform sampler2D canvas_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float canvas_strength : hint_range(0.0, 0.5) = 0.12;
uniform float canvas_scale : hint_range(1.0, 50.0) = 8.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Quadrant accumulators:
	// m = sum of colors, s = sum of squared colors
	vec3 m0 = vec3(0.0), m1 = vec3(0.0), m2 = vec3(0.0), m3 = vec3(0.0);
	vec3 s0 = vec3(0.0), s1 = vec3(0.0), s2 = vec3(0.0), s3 = vec3(0.0);
	
	// Single pass through window collecting into overlapping quadrants
	for (int y = -radius; y <= radius; y++) {
		for (int x = -radius; x <= radius; x++) {
			vec2 offset = vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE;
			vec3 c = texture(screen_texture, uv + offset).rgb;
			vec3 c2 = c * c;
			
			// Top-Left quadrant
			if (x <= 0 && y <= 0) { m0 += c; s0 += c2; }
			// Top-Right quadrant
			if (x >= 0 && y <= 0) { m1 += c; s1 += c2; }
			// Bottom-Left quadrant
			if (x <= 0 && y >= 0) { m2 += c; s2 += c2; }
			// Bottom-Right quadrant
			if (x >= 0 && y >= 0) { m3 += c; s3 += c2; }
		}
	}
	
	float n = float((radius + 1) * (radius + 1));
	
	// Variance per quadrant: Var(X) = E[X^2] - (E[X])^2
	m0 /= n; s0 = abs(s0 / n - m0 * m0); float v0 = s0.r + s0.g + s0.b;
	m1 /= n; s1 = abs(s1 / n - m1 * m1); float v1 = s1.r + s1.g + s1.b;
	m2 /= n; s2 = abs(s2 / n - m2 * m2); float v2 = s2.r + s2.g + s2.b;
	m3 /= n; s3 = abs(s3 / n - m3 * m3); float v3 = s3.r + s3.g + s3.b;
	
	// Select quadrant with minimum variance (sharpest edge / most homogeneous patch)
	float min_v = v0;
	vec3 painterly_col = m0;
	
	if (v1 < min_v) { min_v = v1; painterly_col = m1; }
	if (v2 < min_v) { min_v = v2; painterly_col = m2; }
	if (v3 < min_v) { min_v = v3; painterly_col = m3; }
	
	// 1. Color / Saturation Boost
	float luma = dot(painterly_col, vec3(0.299, 0.587, 0.114));
	vec3 boosted = mix(vec3(luma), painterly_col, color_boost);
	painterly_col = clamp(boosted, vec3(0.0), vec3(1.0));
	
	// 2. Canvas Texture / Linen Weave Overlay
	vec4 canvas_sample = texture(canvas_texture, uv * canvas_scale);
	float grain;
	if (canvas_sample.r > 0.99 && canvas_sample.g > 0.99 && canvas_sample.b > 0.99) {
		float aspect = (SCREEN_PIXEL_SIZE.x > 0.0 && SCREEN_PIXEL_SIZE.y > 0.0) ? (SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x) : 1.0;
		float weave_x = sin(uv.x * 650.0 * aspect);
		float weave_y = cos(uv.y * 650.0);
		grain = weave_x * weave_y;
	} else {
		grain = (canvas_sample.r - 0.5) * 2.0;
	}
	painterly_col = clamp(painterly_col * (1.0 + grain * canvas_strength), vec3(0.0), vec3(1.0));
	
	// 3. Moody Chiaroscuro Vignette
	vec2 centered_coord = (uv - vec2(0.5)) * 2.0;
	float dist_sq = dot(centered_coord, centered_coord) * 0.5;
	float vignette = clamp(1.0 - pow(dist_sq, 1.2) * vignette_intensity, 0.0, 1.0);
	painterly_col *= vignette;
	
	COLOR = vec4(painterly_col, 1.0);
}
