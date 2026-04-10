---
created: 2026-04-10T09:06:55.728Z
title: Add window backdrop biome presets
area: general
files:
  - scenes/main.tscn
  - scripts/room/room_sunlight_controller.gd
  - scripts/world/world_time_sun_controller.gd
---

## Problem

Windows already affect light, but the world outside them is still conceptually thin. There is no configurable backdrop or outside biome mood to make the room feel anchored in a larger setting.

## Solution

Add curated backdrop presets such as rainy city, snowy village, forest cabin, sunset plains, or moonlit lake. The first pass can be presentation-only and should integrate with lighting and weather ambience rather than requiring explorable outdoor spaces.
