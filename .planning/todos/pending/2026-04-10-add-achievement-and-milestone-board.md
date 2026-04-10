---
created: 2026-04-10T09:06:55.728Z
title: Add achievement and milestone board
area: general
files:
  - scenes/main.tscn
  - scripts/placement/placement_manager.gd
  - scripts/world/world_time_controller.gd
---

## Problem

The prototype has decoration systems but little long-term feedback for experimentation. A lightweight milestone layer could reward progress without introducing backend, combat, or economy complexity.

## Solution

Add a local achievement and milestone board that tracks decoration actions, room completions, item discoveries, and special build goals. Keep it optional and cozy so it complements freeform play instead of overwhelming it.
