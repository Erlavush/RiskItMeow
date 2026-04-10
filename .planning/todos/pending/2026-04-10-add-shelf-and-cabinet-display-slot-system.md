---
created: 2026-04-10T09:06:55.728Z
title: Add shelf and cabinet display slot system
area: general
files:
  - scripts/placement/imported_scene_placeable.gd
  - scripts/placement/placement_manager.gd
  - scripts/placement/simple_wood_chair.gd
---

## Problem

Support-surface placement already exists, but furniture that should visually host smaller collectibles still relies on general free placement only. There is no slot-based display system for bookshelves, cabinets, or curated showcase furniture.

## Solution

Add optional display slots for furniture that should present items in organized positions. The first pass should coexist with existing support-surface placement, giving some furniture curated slot behavior without replacing the general free-placement system.
