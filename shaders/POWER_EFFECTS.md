# Honey & Money power effects

These are five standalone, locally authored Godot `canvas_item` shaders using
the directions selected and tuned in the visualization:

- `stinger_strike.gdshader` — Stinger Strike / **Rainbow Lance**: 80% glow,
  100% trail, rainbow width 20,
  2.5× pulse.
- `rain_cloud.gdshader` — Rain Cloud / **Pocket Storm**: 75% darkness, 130% scale,
  20 drops, 0.8× fall speed.
- `swarm_raid.gdshader` — Swarm Raid / **Honey Heist**: 90% glow, 140% spread, 14 bees,
  2.0× flight speed.
- `speedy_bee.gdshader` — Speedy Bee / **Wing Streak**: 80% brightness, 140% trail, 18 lines,
  1.8× burst speed.
- `confusion_cover.gdshader` — Confusion Cover / **Chaos Halo**: 90% brightness, 130% radius, five icons,
  1.1× rotation speed.

## Integration notes

The shaders are wired to their matching power-ups through
`scripts/power_effect_2d.gd`. Each purchase creates an independent material on
the affected bee or hive, follows it for the gameplay duration, animates the
`progress` fade envelope, and then cleans itself up. Stinger Strike and Speedy
Bee also follow the player's horizontal facing. The selected tuning values are
the shader defaults.

## Sources and credits

The procedural shader code was created specifically for this repository and
uses no external textures or third-party code. Its shapes and palette reference
the existing original bee, hive, rain, honey, and power-up art in `art/`.

The pre-game background shader (`golden_bloom_valley.gdshader`) is independent
and remains unchanged.
