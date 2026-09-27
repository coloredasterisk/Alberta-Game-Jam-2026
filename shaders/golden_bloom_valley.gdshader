// Bloom Market background for The Great Nectar Rush.
//
// This CanvasItem shader draws only the scalable environment: pixel sky,
// block clouds, sun, distant hedge, meadow, sand path, and subtle menu-safe
// shading. The companion controller places the repository's original PNG
// sprites above it so bees, birds, flowers, hives, and the shop remain exact.
//
// Approved tuner values (2026-09-27):
//   palette=day, sun_size=30 px, sun=(19%, 28%), path_width=55%,
//   menu_safe_width=46%, motion=true.
// The shop is shifted to x=82% during integration so it is not hidden by the
// existing centre button stack; the path terminates at that visible landmark.

shader_type canvas_item;
render_mode unshaded;

uniform vec2 design_resolution = vec2(640.0, 360.0);

// Bright-day palette coordinated with the existing pixel sprites.
uniform vec4 sky_color : source_color = vec4(0.12, 0.53, 0.91, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.38, 0.72, 0.91, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.84, 0.08, 1.0);
uniform vec4 hedge_dark : source_color = vec4(0.02, 0.35, 0.12, 1.0);
uniform vec4 hedge_light : source_color = vec4(0.03, 0.49, 0.13, 1.0);
uniform vec4 meadow_color : source_color = vec4(0.10, 0.72, 0.13, 1.0);
uniform vec4 meadow_shadow : source_color = vec4(0.05, 0.53, 0.12, 1.0);
uniform vec4 path_color : source_color = vec4(1.0, 0.87, 0.48, 1.0);

// The hedge was reduced after visual review. At 0.15 it remains a distant
// suggestion rather than the solid tree wall used in the first version.
uniform float hedge_visibility : hint_range(0.0, 1.0, 0.01) = 0.15;

// Final values selected in the interactive tuner. They remain uniforms so a
// developer can adjust the material without exposing controls to users.
uniform vec2 sun_position = vec2(0.19, 0.28);
uniform float sun_size_pixels : hint_range(12.0, 64.0, 1.0) = 30.0;
uniform float path_width : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float menu_safe_width : hint_range(0.20, 0.75, 0.01) = 0.46;
uniform float motion_amount : hint_range(0.0, 1.0, 0.01) = 1.0;

// Updated by the controller for restrained pointer/touch parallax.
uniform vec2 pointer_offset = vec2(0.0);

float hash11(float value) {
	return fract(sin(value * 91.3458) * 47453.5453);
}

float pixel_circle(vec2 pixel, vec2 center, float radius) {
	return 1.0 - step(radius, length(pixel - center));
}

float block_cloud(vec2 pixel, vec2 center, float scale) {
	vec2 p = (pixel - center) / scale;
	float base = step(abs(p.x), 25.0) * step(abs(p.y - 4.0), 6.0);
	float left = step(abs(p.x + 12.0), 12.0) * step(abs(p.y + 2.0), 9.0);
	float middle = step(abs(p.x), 11.0) * step(abs(p.y + 8.0), 12.0);
	float right = step(abs(p.x - 15.0), 11.0) * step(abs(p.y), 9.0);
	return max(max(base, left), max(middle, right));
}

void fragment() {
	// Quantize all procedural marks to the game's 640x360 pixel grid.
	vec2 pixel = floor(UV * design_resolution);
	vec2 uv = (pixel + vec2(0.5)) / design_resolution;
	float time_value = TIME * motion_amount;
	vec2 world_pixel = pixel + pointer_offset * vec2(7.0, 4.0);
	vec2 world_uv = world_pixel / design_resolution;

	// Flat sky bands match the limited-color sprite art.
	vec3 color = sky_color.rgb;
	color = mix(color, horizon_color.rgb, step(0.30, world_uv.y));

	// Pixel sun: quantized to 4x4 blocks instead of anti-aliased.
	vec2 sun_center = sun_position * design_resolution;
	vec2 sun_pixel = floor(world_pixel / 4.0) * 4.0;
	float sun = pixel_circle(sun_pixel, sun_center, sun_size_pixels);
	color = mix(color, sun_color.rgb, sun);

	// Sparse block clouds drift by whole pixels and avoid the menu centre.
	float cloud_shift = floor(mod(time_value * 3.0, 700.0));
	float cloud_a = block_cloud(world_pixel, vec2(mod(78.0 + cloud_shift, 700.0) - 30.0, 66.0), 1.0);
	float cloud_b = block_cloud(world_pixel, vec2(mod(495.0 + cloud_shift * 0.7, 700.0) - 30.0, 58.0), 1.2);
	color = mix(color, vec3(0.90, 0.96, 1.0), max(cloud_a, cloud_b) * 0.88);

	// Deterministic square hedge clusters form the horizon.
	float hedge_line = 0.49;
	float hedge_cell = floor(world_pixel.x / 24.0);
	float hedge_height = mix(12.0, 34.0, hash11(hedge_cell + 4.0));
	float hedge = step(hedge_line * design_resolution.y - hedge_height, world_pixel.y);
	color = mix(color, hedge_dark.rgb, hedge * hedge_visibility);
	float hedge_highlight = step(hedge_line * design_resolution.y - hedge_height, world_pixel.y)
		* (1.0 - step(hedge_line * design_resolution.y - hedge_height + 7.0, world_pixel.y));
	color = mix(color, hedge_light.rgb, hedge_highlight * hedge_visibility);

	// Meadow begins below the hedge. Sparse eight-pixel marks echo grass.png.
	float meadow = step(0.50, world_uv.y);
	color = mix(color, meadow_color.rgb, meadow);
	float grass_cell = hash11(floor(world_pixel.x / 8.0) + floor(world_pixel.y / 8.0) * 37.0);
	float grass_mark = meadow * step(0.88, grass_cell) * (1.0 - step(0.78, world_uv.y));
	color = mix(color, meadow_shadow.rgb, grass_mark * 0.42);

	// Curved market path narrows toward the approved shop position.
	float path_y = clamp((world_uv.y - 0.47) / 0.53, 0.0, 1.0);
	float path_center = mix(0.82, 0.50, path_y) + sin(path_y * 7.0) * 0.025 * path_y;
	float half_width = mix(0.018, path_width * 0.18, path_y * path_y);
	float path = meadow * (1.0 - step(half_width, abs(world_uv.x - path_center)));
	color = mix(color, path_color.rgb, path);

	// Quietly shade the 46% central menu-safe column—no visible box or border.
	float safe_half = menu_safe_width * 0.5;
	float safe_x = 1.0 - smoothstep(safe_half - 0.04, safe_half, abs(uv.x - 0.5));
	float safe_y = smoothstep(0.20, 0.29, uv.y) * (1.0 - smoothstep(0.70, 0.78, uv.y));
	color *= 1.0 - safe_x * safe_y * 0.10;

	COLOR = vec4(color, 1.0) * COLOR;
}
