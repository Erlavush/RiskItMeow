---
created: 2026-04-10T09:06:55.728Z
title: Add favorites and recent items bar
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/placement_browser_card.gd
---

## Problem

The catalog is growing, but the placement UI still makes the player browse through categories each time they want a commonly used item. There is no fast path for favorite furniture or recently placed items, which slows down repeated decorating patterns.

## Solution

Add a compact favorites and recents strip to the placement browser. The first pass should support starring items, tracking recently placed props, and reusing those shortcuts without changing the existing inventory and shop structure.
