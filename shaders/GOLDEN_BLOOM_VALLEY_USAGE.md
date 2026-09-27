# Golden Bloom Valley usage

## Preview

Open `res://scenes/golden_bloom_valley_preview.tscn` and press **F6**.

The preview intentionally contains no debug menu or keyboard controls. Move the
mouse to verify the subtle parallax, flower glow, pollen repulsion, and bee
attraction. All tuning and integration entry points remain documented in code.

## Add to a menu

The project's main scene is already integrated: `CanvasLayer/GoldenBloomValley`
renders beneath every pre-game tab and `scripts/main.gd` hides it in
`_enter_playing()`, immediately before the arena becomes interactive.

For another scene:

1. Add a `ColorRect` as the first child of the menu root.
2. Choose **Layout > Full Rect**.
3. Set **Mouse > Filter** to **Ignore** so it never blocks buttons.
4. Assign `res://resources/golden_bloom_valley_material.tres` to **Material**.
5. Keep menu controls after the background node so they render above it.

Attach `golden_bloom_valley_controller.gd` to the menu root if pointer and lobby interaction are wanted. Its default `background_path` expects the node to be named `Background`.

## Connect lobby state

```gdscript
@onready var bloom_background: GoldenBloomValleyController = $GoldenBloomValley

func _on_player_joined(player_count: int) -> void:
    bloom_background.set_joined_players(player_count)

func _on_player_ready(player_index: int) -> void:
    bloom_background.set_player_ready(player_index, true)

func _on_match_countdown_started() -> void:
    bloom_background.play_countdown(3.0)
```

Use `set_quality(0)` on slower web/mobile devices and `set_reduced_motion(true)` when the player enables an accessibility option.

Power-up presentation is deliberately not part of this background shader. Keep
gameplay feedback in separate effects so the home/menu visual stays focused and
easy to maintain.

## Performance

The effect is texture-free and uses no screen-reading pass. Quality levels change procedural cell density and decorative bee count. The shader remains full-screen, so test exported Web builds on representative phones before choosing High as the default.
