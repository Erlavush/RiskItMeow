---
created: 2026-04-10T09:06:55.728Z
title: Add style detector and theme recommendations
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_inventory_catalog.gd
  - scenes/main.tscn
---

## Problem

As content variety grows, the game could benefit from a layer that notices emerging room style patterns. Right now there is no recommendation system that helps the player continue a coherent visual direction.

## Solution

Add a soft style detector that analyzes placed items, colors, and categories, then suggests matching themes or complementary items. Keep it advisory and readable rather than prescriptive.
