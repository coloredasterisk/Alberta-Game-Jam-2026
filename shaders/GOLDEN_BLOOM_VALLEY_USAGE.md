# Bloom Market background usage

## Preview

Open `res://scenes/golden_bloom_valley_preview.tscn` and press **F6**.

The preview intentionally contains no debug menu or keyboard controls. Move the
mouse to verify restrained environment and sprite parallax. Bees use gentle
motion; the original repository PNGs remain nearest-neighbour pixel art.

## Add to a menu

The project's main scene is already integrated: `CanvasLayer/GoldenBloomValley`
renders beneath the title, local/online selection, player-count selection,
session creation/join, player setup, and tutorial/readiness tabs. Their panels
use transparent or semi-transparent overlays so the background remains visible.
`scripts/main.gd` restores this complete layer in `_show_lobby()` and hides it
only in `_enter_playing()`, immediately before the arena becomes interactive.

For readability, `_apply_pregame_text_contrast()` gives every free-standing
`RichTextLabel` under `CanvasLayer/Screens` a localized translucent dark
backplate. It does not touch buttons, the gameplay HUD, or the scenery outside
each text label's bounds. The backplate expands outward, so it never changes the
label's internal text rectangle. Page headings, player statuses, and session
codes are centred; multi-line tutorial body copy remains left-aligned.
Single-line labels are vertically centred, major heading rectangles are sized
to their copy rather than the full viewport, and the tutorial body backplate
uses its content height instead of leaving a large empty dark area.

Pre-game UI frames are generated separately in `scripts/main.gd`; they do not
alter or depend on this shader. The main `HONEY & MONEY` title uses the ornate
Royal Hive frame, while all other pre-game labels and buttons use the simpler
Honey Frame. Buttons receive matching hover, focus, and pressed states.
Player lobby/readiness text uses brighter team colours on neutral frames so the
blue, red, and green states remain readable without tinting their backplates.
Those repeated status rows use a compact version of the same Honey Frame so all
six players and the `Players` heading fit without overlap at 640×360.

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

```

Use `set_reduced_motion(true)` when the player enables an accessibility option.

Power-up presentation is deliberately not part of this background shader. Keep
gameplay feedback in separate effects so the home/menu visual stays focused and
easy to maintain.

## Approved settings

The values selected in the in-chat tuner are documented beside their implementation:

- Bright-day palette
- Sun: 30 design pixels at `(19%, 28%)`
- Shop: scale `3`, vertical position `47%`; shifted to `82%` horizontal in the
  real menu so the existing centre button stack does not hide it
- Path width: `55%` tuner value
- Flowers: `8`, positioned clear of both hives and flags
- Bees: `5`
- Bird flocks: removed after visual review
- Hives: scale `2`
- Hive teams: exact red hive on the left and exact blue hive on the right
- Menu-safe width: `46%`
- Gentle motion: enabled
- Hedge visibility: `15%` of the original solid silhouette
- Bee motion: five independent seeded horizontal paths with unique speed,
  direction, altitude, wave amplitude, and wave frequencies

## Rendering approach

The CanvasItem shader draws the scalable sky, sun, hedge, meadow, path, and
safe-area shading. `golden_bloom_valley_controller.gd` layers the repository's
actual Shop, Bee, Beehive, and Flower textures above it. This hybrid
approach preserves the supplied sprite designs exactly while keeping the full-
screen terrain responsive and inexpensive.
