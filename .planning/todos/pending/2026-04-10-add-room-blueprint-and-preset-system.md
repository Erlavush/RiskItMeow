---
created: 2026-04-10T08:59:31.126Z
title: Add room blueprint and preset system
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_room_layout_store.gd
  - scenes/main.tscn
---

## Problem

The project can currently persist one local room layout, but there is no reusable blueprint or preset workflow for saving themed builds, testing alternate designs, or starting from curated templates. As the room-building feature set grows, a single-slot local save becomes too limiting.

## Solution

Expand the layout persistence flow into named blueprints or presets. The first pass should support creating, listing, loading, and deleting multiple local room layouts with safe metadata and versioning. Later this can grow into starter templates, style packs, and import or export flows without replacing the current local-first persistence model.
