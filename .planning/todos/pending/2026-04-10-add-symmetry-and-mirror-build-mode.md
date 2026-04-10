---
created: 2026-04-10T08:59:31.126Z
title: Add symmetry and mirror build mode
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/room/room_shell.gd
  - scripts/placement/placement_room_layout_store.gd
---

## Problem

Players will eventually want balanced room layouts, but the current placement flow has no symmetry helper. Building mirrored wall decor, paired furniture, or centered room compositions still requires manual duplication and careful repositioning.

## Solution

Add an optional mirror-build mode that can reflect placements across the room center or another chosen axis. The first pass should support mirrored placement and duplication for safe symmetric layouts, while explicitly excluding cases that would break mount rules or wall-surface compatibility until those edge cases are defined.
