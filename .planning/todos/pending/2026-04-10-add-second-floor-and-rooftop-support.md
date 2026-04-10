---
created: 2026-04-10T08:01:21.500Z
title: Add second floor and rooftop support
area: general
files:
  - scripts/room/room_shell.gd
  - scripts/room/room_cutaway_controller.gd
  - scripts/player.gd
  - scripts/camera/room_view_camera_controller.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The user wants a second floor and rooftop space, but the live architecture assumes one single-story shell, one floor plane, one ceiling plane, one cutaway layer, and one bounded interior play space. Adding stacked floors without a design pass would create placement, navigation, visibility, lighting, and persistence regressions.

## Solution

Treat this as a later structural expansion after basic room-shell customization exists. Define the data model first: floor stack representation, stair or ladder access, per-level cutaway behavior, per-level placement bounds, camera rules, and save-load format. Only then add multi-floor geometry and rooftop access, because this is closer to a room-system rewrite than a normal content feature.
