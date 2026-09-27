# Golden Bloom Valley shader — sources and credits

## Creative credits

- **Game concept and story direction:** The Great Nectar Rush story supplied by the project owner.
- **Project palette and pixel-art direction:** Existing visual assets in `coloredasterisk/Alberta-Game-Jam-2026`. The repository does not currently identify individual artists in `art/README.md`; add contributor names here when available.
- **Concept preview render:** Generated with OpenAI image generation for selection only. The render is not embedded in or required by the game.
- **Shader, controller, material, and preview scene:** Original implementation created specifically for this project. No ShaderToy, marketplace, tutorial, or third-party shader code was copied.

## Technical references

- Godot Engine 4.7 CanvasItem shader reference: https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html
- Godot Engine shading-language reference: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html

The implementation uses documented Godot features including `shader_type canvas_item`, `UV`, `TIME`, `SCREEN_PIXEL_SIZE`, color uniforms, range hints, and runtime shader parameters.

## Files

- `shaders/golden_bloom_valley.gdshader` — fully procedural visual effect.
- `resources/golden_bloom_valley_material.tres` — reusable ShaderMaterial.
- `scripts/golden_bloom_valley_controller.gd` — optional runtime interaction bridge.
- `scenes/golden_bloom_valley_preview.tscn` — clean interactive demonstration scene with no debug overlay.

## License note

This file documents provenance, not the repository's license. The repository currently has no root license file. Before public redistribution, the project owner should add an explicit repository license and confirm permission/attribution requirements for the font, music, and contributed artwork.
