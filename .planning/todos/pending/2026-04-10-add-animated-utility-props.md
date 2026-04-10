---
created: 2026-04-10T09:06:55.728Z
title: Add animated utility props
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/placement/wooden_block_clock_placeable.gd
---

## Problem

The catalog currently proves animation with only a few items such as the clock and ceiling fan. There is room for more props whose identity depends on motion or small effects like steam, flicker, blinking, or glow.

## Solution

Add curated animated utility props such as lava lamps, steaming mugs, glowing monitors, small desk fans, candles, or blinking electronics. Reuse the existing animated-item pattern instead of inventing a separate prop architecture.
