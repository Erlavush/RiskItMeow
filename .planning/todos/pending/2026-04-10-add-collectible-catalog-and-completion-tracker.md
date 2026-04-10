---
created: 2026-04-10T09:06:55.728Z
title: Add collectible catalog and completion tracker
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/placement_manager.gd
  - scenes/main.tscn
---

## Problem

As more items and variants are added, players may want a sense of collection progress. There is currently no tracker for discovered, owned, or fully completed decor lines.

## Solution

Add a local collection tracker that records item discovery, ownership, and completion milestones. The first pass should stay informational and cozy rather than turning collection into a grind-heavy system.
