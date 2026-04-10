---
created: 2026-04-10T08:01:21.500Z
title: Add placeable aquarium with animated fish
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The user wants an aquarium with fish, but the current catalog only supports static furniture plus a few simple animated props like the ceiling fan and clock. There is no curated aquarium item, no animated fish loop, and no clear plan for how water, glass, emissive lighting, and fish motion should fit the existing placement pipeline.

## Solution

Add the aquarium as a placeable decor prop through the existing catalog and imported-item flow rather than as a separate subsystem. The first pass should support a tank mesh, water and glass materials, simple looping fish motion, optional bubbles or glow, and stable collision and preview behavior. Keep interaction optional for later so the first feature lands as a polished animated room item.
