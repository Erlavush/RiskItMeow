---
created: 2026-04-10T09:06:55.728Z
title: Add dynamic soundtrack manager
area: general
files:
  - scenes/main.tscn
  - scripts/world/world_time_controller.gd
  - scripts/player.gd
---

## Problem

Ambient audio alone will not cover all of the room’s emotional pacing once the game grows. There is no system for music that responds to time of day, weather, room mood, or player activity.

## Solution

Add a soundtrack manager that can switch or blend curated music states based on world time, room presentation, and later interaction or weather states. Keep the first pass subtle and mood-first.
