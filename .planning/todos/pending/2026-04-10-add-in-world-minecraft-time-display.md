---
created: 2026-04-10T08:01:21.500Z
title: Add in-world Minecraft time display
area: general
files:
  - scripts/world/world_time_controller.gd
  - scripts/placement/wooden_block_clock_placeable.gd
  - scenes/main.tscn
---

## Problem

The user wants a Minecraft-like real-time display or GUI for time, but the project currently only exposes that timing indirectly through the animated clock and sun cycle. The underlying system already tracks Minecraft-style ticks and day progression, but there is no readable in-game presentation layer for it.

## Solution

Expose the existing `WorldTimeController` state through a clear UI or in-world display instead of creating a second time source. Decide whether the first pass is HUD-only, furniture-only, or both, then keep the display aligned with the current tick/day math so it stays consistent with the animated wooden clock and future atmosphere changes.
