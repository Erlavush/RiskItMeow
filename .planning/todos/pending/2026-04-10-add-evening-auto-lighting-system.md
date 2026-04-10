---
created: 2026-04-10T08:01:21.500Z
title: Add evening auto-lighting system
area: general
files:
  - scripts/world/world_time_controller.gd
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/room/room_sunlight_controller.gd
---

## Problem

The user wants lighting support for evening and night, but the current room mood depends mostly on global sun, moon, and fake window-light behavior. There is no placeable indoor light system with room-owned light sources, no dusk auto-on behavior, and no clear distinction between decorative lamp meshes and actual light-emitting props.

## Solution

Add light-emitting placeables and a simple room lighting policy that supports manual toggles plus optional automatic dusk and night activation. Keep the first pass performance-safe by using curated light items, limited `Light3D` counts, and emissive meshes, then integrate those items with world time so evening ambience improves without turning the room system into a heavy simulation.
