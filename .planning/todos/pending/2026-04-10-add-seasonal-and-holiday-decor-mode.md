---
created: 2026-04-10T09:06:55.728Z
title: Add seasonal and holiday decor mode
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/world/world_time_controller.gd
  - scenes/main.tscn
---

## Problem

The prototype will benefit from themed content over time, but there is no framework for seasonal decor sets or temporary room moods. That limits how much variety can be layered onto the same room shell and placement systems.

## Solution

Add a seasonal presentation layer with optional decor collections, ambient tweaks, and calendar-independent theme switching. The first pass should focus on curated content packs rather than real-world date enforcement.
