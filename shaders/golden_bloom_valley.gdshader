// Golden Bloom Valley
// Original procedural CanvasItem shader for The Great Nectar Rush.
// Intended use: full-screen ColorRect backgrounds behind home, menu, lobby,
// tutorial, and pre-match countdown UI.
//
// No external textures are required. Every visible element is generated from
// UV coordinates and uniforms, so the effect scales to any viewport.

shader_type canvas_item;
render_mode unshaded;

// -----------------------------------------------------------------------------
// Palette
// -----------------------------------------------------------------------------

uniform vec4 sky_zenith : source_color = vec4(0.24, 0.20, 0.48, 1.0);
uniform vec4 sky_horizon : source_color = vec4(1.0, 0.63, 0.22, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.91, 0.46, 1.0);
uniform vec4 far_hill_color : source_color = vec4(0.29, 0.46, 0.19, 1.0);
uniform vec4 middle_hill_color : source_color = vec4(0.15, 0.36, 0.12, 1.0);
uniform vec4 near_hill_color : source_color = vec4(0.055, 0.22, 0.075, 1.0);
uniform vec4 flower_gold : source_color = vec4(1.0, 0.76, 0.08, 1.0);
uniform vec4 pollen_color : source_color = vec4(1.0, 0.91, 0.45, 1.0);

// -----------------------------------------------------------------------------
// Art direction and accessibility
// -----------------------------------------------------------------------------

// 0 = low, 1 = medium, 2 = high. The controller can change this at runtime.
// Low reduces procedural flower, pollen, and bee counts.
uniform int quality_level : hint_enum("Low", "Medium", "High") = 2;

// Set to 0 for a static/reduced-motion presentation. Values between 0 and 1
// provide partial animation without changing the composition.
uniform float motion_amount : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float animation_speed : hint_range(0.0, 2.0, 0.01) = 0.42;

// Pixel blocks larger than 1 create a more obvious retro appearance while
// preserving the project's nearest-neighbour visual language.
uniform float pixel_block_size : hint_range(1.0, 8.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.4, 1.6, 0.01) = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.28;

// Keeps the middle of the screen quieter for titles and menu buttons.
uniform float ui_safe_zone : hint_range(0.0, 1.0, 0.01) = 0.62;

// -----------------------------------------------------------------------------
// Environment controls
// -----------------------------------------------------------------------------

uniform float sunset_progress : hint_range(0.0, 1.0, 0.01) = 0.22;
uniform float wind_strength : hint_range(0.0, 1.5, 0.01) = 0.34;
uniform float flower_density : hint_range(0.0, 1.0, 0.01) = 0.88;
uniform float bloom_progress : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float flower_glow : hint_range(0.0, 2.0, 0.01) = 0.90;
uniform float pollen_amount : hint_range(0.0, 1.0, 0.01) = 0.62;
uniform float bee_amount : hint_range(0.0, 1.0, 0.01) = 0.58;

// Pointer position is normalized: top-left = (0, 0), bottom-right = (1, 1).
// The companion script updates it from mouse or touch input.
uniform vec2 pointer_position = vec2(0.5, 0.5);
uniform float pointer_influence : hint_range(0.0, 1.0, 0.01) = 0.58;

// Camera-like offset used for pointer-driven parallax or device tilt.
uniform vec2 parallax_offset = vec2(0.0);

// -----------------------------------------------------------------------------
// Lobby and gameplay-state controls
// -----------------------------------------------------------------------------

// Four distant hive lights become active as players join.
uniform int joined_players : hint_range(0, 4, 1) = 0;

// Component order is red, blue, yellow, green. A component of 1 means ready.
uniform vec4 player_ready_state = vec4(0.0);

// Drive from 0 to 1 during 3-2-1-GO. It boosts wind, flowers, pollen, and sun.
uniform float countdown_energy : hint_range(0.0, 1.0, 0.01) = 0.0;

// Optional audio analysis value. A subtle pulse is enough; avoid setting it
// directly to raw loudness because that tends to flicker.
uniform float music_energy : hint_range(0.0, 1.0, 0.01) = 0.0;

// -----------------------------------------------------------------------------
// Small reusable math helpers
// -----------------------------------------------------------------------------

float hash11(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

mat2 rotate_2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

float soft_circle(vec2 p, float radius, float softness) {
	return 1.0 - smoothstep(radius - softness, radius + softness, length(p));
}

float ellipse_mask(vec2 p, vec2 radius, float softness) {
	float d = length(p / max(radius, vec2(0.0001))) - 1.0;
	return 1.0 - smoothstep(-softness, softness, d);
}

// Six soft petals around a dark centre. Unlike the distant flower specks,
// this reads as a flower even at menu-screen scale.
float flower_shape(vec2 p, float radius) {
	float petals = 0.0;
	for (int petal_index = 0; petal_index < 6; petal_index++) {
		float angle = float(petal_index) * 1.04719755;
		vec2 petal_position = vec2(cos(angle), sin(angle)) * radius * 0.68;
		petals = max(petals, ellipse_mask(rotate_2d(-angle) * (p - petal_position), vec2(radius * 0.62, radius * 0.34), 0.13));
	}
	return petals;
}

// Rounded stacked bands and a doorway form a readable stylised skep hive.
vec2 hive_shape(vec2 p, float scale) {
	vec2 q = p / scale;
	float dome = ellipse_mask(q - vec2(0.0, -0.05), vec2(0.80, 0.82), 0.05);
	float base = 1.0 - smoothstep(0.66, 0.70, abs(q.x));
	base *= 1.0 - smoothstep(0.70, 0.76, q.y);
	base *= smoothstep(-0.48, -0.42, q.y);
	float body = max(dome, base);
	float doorway = ellipse_mask(q - vec2(0.0, 0.34), vec2(0.22, 0.28), 0.07);
	return vec2(body, doorway);
}

// Hex-line mask used only at the outer edges, where it frames the menu
// without competing with buttons in the centre safe zone.
float honeycomb_lines(vec2 uv, float aspect) {
	vec2 grid = uv * vec2(9.0 * aspect, 9.0);
	grid.y += mod(floor(grid.x), 2.0) * 0.5;
	vec2 cell = fract(grid) - 0.5;
	cell.x *= 0.8660254;
	float hex_distance = max(abs(cell.x) * 1.1547 + abs(cell.y) * 0.5, abs(cell.y));
	return smoothstep(0.43, 0.40, abs(hex_distance - 0.39));
}

// Three rolling height functions produce inexpensive parallax scenery.
float far_hill_line(float x, float time_value) {
	return 0.59 + sin(x * 5.2 + time_value * 0.07) * 0.030
			+ sin(x * 11.0 + 1.3) * 0.014;
}

float middle_hill_line(float x, float time_value) {
	return 0.69 + sin(x * 6.1 - time_value * 0.10 + 2.1) * 0.038
			+ sin(x * 14.0) * 0.012;
}

float near_hill_line(float x, float time_value) {
	return 0.79 + sin(x * 6.8 + time_value * 0.14 + 4.0) * 0.046
			+ sin(x * 18.0 + 0.7) * 0.012;
}

// Tiny two-wing bee silhouette used for decorative flight paths.
float bee_shape(vec2 p, float size) {
	float body = ellipse_mask(p, vec2(size, size * 0.42), 0.16);
	float upper_wing = ellipse_mask(rotate_2d(-0.55) * (p - vec2(-size * 0.05, size * 0.48)), vec2(size * 0.52, size * 0.21), 0.18);
	float lower_wing = ellipse_mask(rotate_2d(0.55) * (p - vec2(-size * 0.05, -size * 0.48)), vec2(size * 0.52, size * 0.21), 0.18);
	return max(body, max(upper_wing, lower_wing) * 0.48);
}

vec3 ready_color(int index) {
	if (index == 0) {
		return vec3(1.0, 0.19, 0.10); // Red hive
	}
	if (index == 1) {
		return vec3(0.12, 0.47, 1.0); // Blue hive
	}
	if (index == 2) {
		return vec3(1.0, 0.76, 0.06); // Yellow hive
	}
	return vec3(0.20, 0.82, 0.25); // Green hive
}

float ready_value(int index) {
	if (index == 0) {
		return player_ready_state.x;
	}
	if (index == 1) {
		return player_ready_state.y;
	}
	if (index == 2) {
		return player_ready_state.z;
	}
	return player_ready_state.w;
}

void fragment() {
	// Quantize coordinates before drawing. This keeps procedural curves aligned
	// with the repository's deliberately crisp pixel-art presentation.
	vec2 pixel_step = SCREEN_PIXEL_SIZE * max(pixel_block_size, 1.0);
	vec2 uv = floor(UV / pixel_step) * pixel_step + pixel_step * 0.5;

	float aspect = SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.000001);
	float time_value = TIME * animation_speed * motion_amount;

	// Pointer parallax is deliberately subtle so buttons remain easy to target.
	vec2 pointer_delta = (pointer_position - vec2(0.5)) * pointer_influence;
	vec2 scene_uv = uv + parallax_offset * 0.025 + pointer_delta * vec2(0.010, 0.006);
	vec2 p = scene_uv - vec2(0.5);
	p.x *= aspect;

	// --- Sky, sunset, and sun -------------------------------------------------
	float sky_mix = smoothstep(0.02, 0.90, scene_uv.y);
	vec3 color = mix(sky_zenith.rgb, sky_horizon.rgb, sky_mix);

	// Darker twilight as sunset_progress increases; the horizon stays warm.
	vec3 twilight = vec3(0.055, 0.045, 0.17);
	color = mix(color, mix(twilight, sky_horizon.rgb * 0.70, sky_mix), sunset_progress * 0.52);

	vec2 sun_position = vec2(mix(-0.28, 0.30, sunset_progress) * aspect, mix(0.10, 0.28, sunset_progress));
	float sun_radius = 0.105 + countdown_energy * 0.010 + music_energy * 0.005;
	float sun = soft_circle(p - sun_position, sun_radius, 0.010);
	float sun_halo = exp(-length(p - sun_position) * 6.2);
	color += sun_color.rgb * sun_halo * (0.38 + countdown_energy * 0.18 + music_energy * 0.08);
	color = mix(color, sun_color.rgb, sun * 0.92);

	// Layered cloud banks give the sky the fullness of the approved concept.
	// The ellipses drift at different rates for gentle depth without textures.
	float clouds = 0.0;
	for (int cloud_index = 0; cloud_index < 7; cloud_index++) {
		float cloud_seed = hash11(float(cloud_index) + 44.0);
		float cloud_x = fract(cloud_seed + time_value * mix(0.002, 0.009, cloud_seed));
		float cloud_y = mix(0.13, 0.39, hash11(float(cloud_index) + 91.0));
		vec2 cloud_p = scene_uv - vec2(cloud_x, cloud_y);
		cloud_p.x *= aspect;
		float puff = ellipse_mask(cloud_p, vec2(0.085, 0.027), 0.14);
		puff = max(puff, ellipse_mask(cloud_p - vec2(-0.038, -0.018), vec2(0.050, 0.035), 0.14));
		puff = max(puff, ellipse_mask(cloud_p - vec2(0.030, -0.012), vec2(0.058, 0.041), 0.14));
		clouds = max(clouds, puff * mix(0.30, 0.65, cloud_seed));
	}
	vec3 cloud_color = vec3(1.0, 0.78, 0.49);
	color = mix(color, cloud_color, clouds * 0.58);

	// --- Three parallax hill layers -----------------------------------------
	float far_line = far_hill_line(scene_uv.x + pointer_delta.x * 0.03, time_value);
	float middle_line = middle_hill_line(scene_uv.x + pointer_delta.x * 0.055, time_value);
	float near_line = near_hill_line(scene_uv.x + pointer_delta.x * 0.085, time_value);

	float far_mask = smoothstep(far_line - 0.008, far_line + 0.008, scene_uv.y);
	float middle_mask = smoothstep(middle_line - 0.007, middle_line + 0.007, scene_uv.y);
	float near_mask = smoothstep(near_line - 0.006, near_line + 0.006, scene_uv.y);

	color = mix(color, far_hill_color.rgb, far_mask);
	color = mix(color, middle_hill_color.rgb, middle_mask);
	color = mix(color, near_hill_color.rgb, near_mask);

	// Warm atmospheric rims separate the three valley layers at a glance.
	float far_rim = exp(-abs(scene_uv.y - far_line) * 180.0);
	float middle_rim = exp(-abs(scene_uv.y - middle_line) * 210.0);
	color += sun_color.rgb * (far_rim * 0.10 + middle_rim * 0.045);

	// --- Golden Bloom flowers -----------------------------------------------
	// A larger grid is used on high quality. Fixed loop-free cell evaluation
	// keeps the shader inexpensive enough for web builds.
	float flower_columns = quality_level == 0 ? 24.0 : (quality_level == 1 ? 36.0 : 52.0);
	float flower_rows = quality_level == 0 ? 10.0 : (quality_level == 1 ? 14.0 : 18.0);
	vec2 flower_grid = vec2(scene_uv.x * flower_columns, scene_uv.y * flower_rows);
	vec2 flower_cell = floor(flower_grid);
	vec2 flower_local = fract(flower_grid) - vec2(0.5);
	float flower_seed = hash21(flower_cell + vec2(7.0, 19.0));

	float cell_world_y = (flower_cell.y + 0.5) / flower_rows;
	float on_ground = step(near_hill_line((flower_cell.x + 0.5) / flower_columns, time_value), cell_world_y);
	float flower_exists = step(1.0 - flower_density, flower_seed) * on_ground;

	// Bloom grows from zero and gently sways with wind and countdown energy.
	float individual_bloom = smoothstep(flower_seed * 0.65, flower_seed * 0.65 + 0.24, bloom_progress);
	float sway = sin(time_value * (1.1 + flower_seed) + flower_seed * 18.0) * wind_strength * 0.10;
	flower_local.x += sway * (0.4 + countdown_energy * 0.6);
	float petal_distance = length(flower_local * vec2(1.0, 1.35));
	float flower = exp(-petal_distance * 18.0) * flower_exists * individual_bloom;

	// Pointer causes a local bloom wave without affecting the actual menu UI.
	vec2 flower_world = (flower_cell + vec2(0.5)) / vec2(flower_columns, flower_rows);
	float pointer_bloom = exp(-distance(flower_world, pointer_position) * 11.0) * pointer_influence;
	float flower_energy = flower_glow * (0.55 + pointer_bloom + countdown_energy * 0.70 + music_energy * 0.22);
	color += flower_gold.rgb * flower * flower_energy;

	// Large foreground blossoms anchor both bottom corners. They are kept out
	// of the central menu-safe region and sway independently with the wind.
	for (int flower_index = 0; flower_index < 10; flower_index++) {
		float flower_side = mod(float(flower_index), 2.0);
		float flower_seed_large = hash11(float(flower_index) + 120.0);
		float flower_x = mix(0.035, 0.31, flower_seed_large);
		flower_x = mix(flower_x, 1.0 - flower_x, flower_side);
		float flower_y = mix(0.82, 1.02, hash11(float(flower_index) + 170.0));
		float flower_size = mix(0.022, 0.048, hash11(float(flower_index) + 230.0));
		vec2 large_p = scene_uv - vec2(flower_x, flower_y);
		large_p.x *= aspect;
		large_p.x += sin(time_value * 0.8 + flower_seed_large * 9.0) * wind_strength * 0.004;
		float petals = flower_shape(large_p, flower_size);
		float centre = soft_circle(large_p, flower_size * 0.28, flower_size * 0.08);
		vec3 petal_color = mix(vec3(1.0, 0.51, 0.13), vec3(1.0, 0.91, 0.30), flower_seed_large);
		color = mix(color, petal_color, petals * 0.95);
		color = mix(color, vec3(0.35, 0.16, 0.025), centre * 0.95);
	}

	// Two prominent valley hives make the background immediately communicate
	// the game's four-hive rivalry instead of relying on tiny point lights.
	for (int large_hive_index = 0; large_hive_index < 2; large_hive_index++) {
		float hive_side = float(large_hive_index);
		vec2 hive_position_large = vec2(mix(0.13, 0.87, hive_side), 0.665);
		vec2 hive_p = scene_uv - hive_position_large;
		hive_p.x *= aspect;
		vec2 hive_masks = hive_shape(hive_p, 0.068);
		vec3 hive_gold = mix(vec3(0.55, 0.25, 0.035), vec3(1.0, 0.68, 0.12), 0.72 + sun_halo * 0.18);
		// Horizontal banding echoes a woven straw skep.
		float band = 0.82 + 0.18 * step(0.5, fract((hive_p.y / 0.068 + 0.7) * 6.0));
		color = mix(color, hive_gold * band, hive_masks.x * 0.96);
		color = mix(color, vec3(0.085, 0.035, 0.012), hive_masks.y * hive_masks.x);
	}

	// --- Four lobby hive lights ---------------------------------------------
	// They sit near the horizon, away from the title and central menu buttons.
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		vec2 hive_position = vec2(mix(0.10, 0.90, fi / 3.0), 0.64 + mod(fi, 2.0) * 0.035);
		float joined = step(fi + 0.5, float(joined_players));
		float ready = ready_value(i);
		float hive_light = exp(-distance(scene_uv, hive_position) * 50.0) * joined;
		float ready_pulse = 0.72 + 0.28 * sin(time_value * 3.0 + fi * 1.7);
		color += ready_color(i) * hive_light * (0.32 + ready * ready_pulse * 0.85);
	}

	// --- Pollen field --------------------------------------------------------
	float pollen_columns = quality_level == 0 ? 16.0 : (quality_level == 1 ? 24.0 : 34.0);
	float pollen_rows = quality_level == 0 ? 9.0 : (quality_level == 1 ? 13.0 : 18.0);
	vec2 pollen_grid = vec2(scene_uv.x * pollen_columns, scene_uv.y * pollen_rows);
	vec2 pollen_cell = floor(pollen_grid);
	vec2 pollen_local = fract(pollen_grid) - vec2(0.5);
	float pollen_seed = hash21(pollen_cell + vec2(31.0, 73.0));

	float wind = wind_strength + countdown_energy * 0.85;
	pollen_local.x += sin(time_value * (0.7 + pollen_seed) + pollen_seed * 13.0) * 0.24 * wind;
	pollen_local.y = fract(pollen_local.y + 0.5 - time_value * mix(0.02, 0.10, pollen_seed)) - 0.5;

	// Cursor repels nearby pollen, creating immediate but gentle feedback.
	vec2 pollen_world = (pollen_cell + pollen_local + vec2(0.5)) / vec2(pollen_columns, pollen_rows);
	vec2 away = pollen_world - pointer_position;
	float pointer_distance = length(away);
	pollen_local += normalize(away + vec2(0.0001)) * exp(-pointer_distance * 18.0) * pointer_influence * 0.55;

	float pollen = exp(-length(pollen_local) * 24.0);
	pollen *= step(1.0 - pollen_amount, pollen_seed);
	pollen *= 1.0 - smoothstep(ui_safe_zone * 0.38, ui_safe_zone * 0.62, 1.0 - length((scene_uv - vec2(0.5)) * vec2(1.0, 1.55)));
	color += pollen_color.rgb * pollen * (0.30 + countdown_energy * 0.48 + music_energy * 0.18);

	// --- Decorative bee flight paths ---------------------------------------
	int base_bees = quality_level == 0 ? 3 : (quality_level == 1 ? 6 : 10);
	int visible_bees = int(float(base_bees) * bee_amount) + joined_players;
	for (int i = 0; i < 18; i++) {
		if (i >= visible_bees) {
			break;
		}
		float fi = float(i);
		float seed = hash11(fi + 8.0);
		float flight_speed = mix(0.05, 0.13, seed);
		float x = fract(seed + time_value * flight_speed);
		float y = mix(0.23, 0.58, hash11(fi + 27.0));
		y += sin(x * 8.0 + seed * 12.0 + time_value) * 0.025;

		vec2 bee_position = vec2(x, y);
		// A small fraction of the bees follows the pointer when it is active.
		float follow = pointer_influence * step(0.72, seed) * 0.42;
		bee_position = mix(bee_position, pointer_position, follow);

		vec2 bee_p = scene_uv - bee_position;
		bee_p.x *= aspect;
		bee_p = rotate_2d(-0.10 * cos(x * 8.0 + time_value)) * bee_p;
		float bee = bee_shape(bee_p, mix(0.0045, 0.0080, seed));
		vec3 bee_color = mix(vec3(0.035, 0.018, 0.006), flower_gold.rgb, 0.25 + 0.20 * sin(bee_p.x * 900.0));
		color = mix(color, bee_color, bee * 0.82);
	}

	// A faint honeycomb frame connects the scene to the bee theme. Its edge
	// mask deliberately fades before reaching the title and button region.
	float edge_distance = max(abs(scene_uv.x - 0.5) * 2.0, abs(scene_uv.y - 0.5) * 2.0);
	float honeycomb_edge = smoothstep(0.63, 0.94, edge_distance);
	float honeycomb = honeycomb_lines(scene_uv, aspect) * honeycomb_edge;
	color += flower_gold.rgb * honeycomb * 0.13;

	// Final countdown flash and vignette keep focus near the screen centre.
	color += sun_color.rgb * countdown_energy * countdown_energy * 0.09;
	float vignette = smoothstep(0.82, 0.27, length(p));
	color *= mix(1.0 - vignette_strength, 1.0, vignette);
	color *= brightness;

	COLOR = vec4(color, 1.0) * COLOR;
}
