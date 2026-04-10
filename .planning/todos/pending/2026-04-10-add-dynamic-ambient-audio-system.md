---
created: 2026-04-10T08:59:31.126Z
title: Add dynamic ambient audio system
area: general
files:
  - scenes/main.tscn
  - scripts/world/world_time_controller.gd
  - scripts/player.gd
---

## Problem

The visual side of the prototype is improving, but the room still lacks a coherent ambient audio layer. Without room tone, weather loops, item hums, clock ticks, fan sounds, or time-of-day ambience, the space cannot feel fully alive even when the visuals are working.

## Solution

Add a layered ambient audio system that can blend room tone, day and night ambience, item-based loops, and later weather soundscapes. The first pass should focus on a few high-value loops and subtle transitions rather than dense audio complexity, so the room gains presence without becoming noisy or hard to tune.
