---
created: 2026-04-10T09:06:55.728Z
title: Add ambient motion accents for decor
area: general
files:
  - scripts/placement/imported_scene_placeable.gd
  - scripts/placement/placement_inventory_catalog.gd
  - scenes/main.tscn
---

## Problem

Many props are static once placed, which can make finished rooms feel visually still even when lighting and placement are polished. Subtle motion could make the room feel more alive without requiring full AI or interaction systems.

## Solution

Add lightweight secondary motion for selected decor such as curtains, hanging plants, papers, strings, or other soft objects. The first pass should use subtle looping or wind-reactive presentation, not heavy physics.
