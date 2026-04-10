---
created: 2026-04-10T09:06:55.728Z
title: Add item aging and patina variants
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/debug/debug_world_controller.gd
---

## Problem

Visual variety is currently tied mostly to distinct item identities. There is no built-in way to make furniture feel new, worn, dusty, vintage, polished, or weathered without creating separate catalog entries.

## Solution

Extend the variant concept so some items can expose age and patina states. Keep the first pass as a curated presentation feature with save-load persistence rather than a complex wear simulation.
