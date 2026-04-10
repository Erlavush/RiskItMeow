---
created: 2026-04-10T08:01:21.500Z
title: Add time-of-day atmosphere controller
area: general
files:
  - scripts/world/world_time_controller.gd
  - scripts/world/world_time_sun_controller.gd
  - scripts/room/room_sunlight_controller.gd
  - scripts/debug/developer_environment_panel.gd
---

## Problem

The user wants stronger sunrise, afternoon, sunset, night, and moonlit room mood changes that feel closer to Minecraft day-night logic. The project already has a working world-time controller plus sun and moon direction handling, but most atmosphere styling is still driven by manual developer presets instead of automatic phase-based transitions.

## Solution

Add a data-driven time-of-day atmosphere controller that maps day progress to light color and energy, ambient balance, fog, sky tint, portal-light warmth, and any later shader parameters. Start by extending the existing time and lighting systems instead of jumping straight into a heavy fullscreen shader solution, so the baseline remains stable and tunable.
