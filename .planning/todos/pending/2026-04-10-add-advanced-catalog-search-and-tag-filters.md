---
created: 2026-04-10T09:06:55.728Z
title: Add advanced catalog search and tag filters
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/placement_browser_card.gd
---

## Problem

The catalog can already be browsed by category, but it lacks richer search and filter tools. As more items, variants, and decor themes are added, category-only browsing will become increasingly slow and noisy.

## Solution

Extend the catalog schema with searchable tags such as style, room type, size, color family, and function. Then expose those through the placement browser so players can narrow the item list without replacing the current category layout.
