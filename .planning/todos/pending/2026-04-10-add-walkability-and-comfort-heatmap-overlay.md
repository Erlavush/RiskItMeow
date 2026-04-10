---
created: 2026-04-10T09:06:55.728Z
title: Add walkability and comfort heatmap overlay
area: general
files:
  - scripts/player.gd
  - scripts/room/room_shell.gd
  - scripts/placement/placement_manager.gd
---

## Problem

As rooms become denser, it will get harder to judge whether a layout feels open, cramped, or awkward to traverse. Current placement validation prevents collisions, but it does not communicate room flow quality.

## Solution

Add an optional overlay that estimates walkability, clearance, and comfort zones inside the room. The first pass should be an advisory visualization for layout tuning, not a strict blocker.
