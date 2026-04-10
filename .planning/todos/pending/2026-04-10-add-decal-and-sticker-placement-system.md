---
created: 2026-04-10T09:06:55.728Z
title: Add decal and sticker placement system
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/room/room_shell.gd
  - scripts/placement/placement_surface_queries.gd
---

## Problem

The room supports furniture-scale placement, but it lacks an ultra-small decoration layer for decals, stickers, and flat accents. Without that, some personal details still require oversized props.

## Solution

Add a specialized decal and sticker system for walls, floors, and selected furniture surfaces. The first pass should focus on reliable surface attachment and layering rather than full material editing.
