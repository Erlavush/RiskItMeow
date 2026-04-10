---
created: 2026-04-10T08:01:21.500Z
title: Expand surface decor catalog
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The user wants more small surface decor and clutter items, but the current support-surface flow is only lightly exercised by the live catalog. Without more tabletop and shelf-scale props, the new free-placement and smooth-rotation work cannot deliver its full value.

## Solution

Prioritize a curated batch of small support-surface items such as mugs, books, plants, desk accessories, speakers, candles, food props, and other clutter. Route them through the existing mount-aware catalog so they inherit support-surface validation, local save-load, free placement, and smooth rotation instead of adding a separate decor system.
