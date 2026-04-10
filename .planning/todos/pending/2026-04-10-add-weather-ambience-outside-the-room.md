---
created: 2026-04-10T08:59:31.126Z
title: Add weather ambience outside the room
area: general
files:
  - scripts/world/world_time_controller.gd
  - scripts/world/world_time_sun_controller.gd
  - scripts/room/room_sunlight_controller.gd
  - scenes/main.tscn
---

## Problem

The room already has sunlight, moonlight, and day progression, but there is no outdoor weather layer to deepen the mood. Without rain, clouds, storms, or other outside ambience, the window view and lighting transitions still feel visually thin.

## Solution

Add a lightweight weather state system for outside ambience rather than full environmental simulation. The first pass should target visual mood and sound support through rain, overcast light shifts, storm ambience, and window-facing presentation changes. Keep it performance-safe and room-scale, with weather affecting atmosphere rather than gameplay systems.
