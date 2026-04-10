---
created: 2026-04-10T09:06:55.728Z
title: Add room cleaning and upkeep layer
area: general
files:
  - scenes/main.tscn
  - scripts/world/world_time_controller.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The room can be decorated, but it does not yet have any upkeep or lived-in simulation layer. A light cleanliness system could add cozy maintenance loops and visual change over time without becoming a survival mechanic.

## Solution

If the user chooses this direction later, add a soft upkeep layer with dust, tidy-state visuals, and small cleanup interactions. Keep it optional, aesthetic, and room-scale so it supports mood rather than creating chore-heavy gameplay.
