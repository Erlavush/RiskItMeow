---
created: 2026-04-10T08:59:31.126Z
title: Add room coziness scoring system
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/world/world_time_controller.gd
---

## Problem

The player can already decorate the room, but there is no feedback loop that evaluates or celebrates the result. A simple room-scoring layer could create direction, progression, and experimentation without requiring combat, economy, or multiplayer systems.

## Solution

Add a cozy room evaluation system that scores layout quality, decoration variety, lighting mood, clutter balance, and theme consistency. The first pass should be intentionally soft and readable, producing mood labels or lightweight scores rather than punishing hard rules, so it encourages creativity instead of narrowing it.
