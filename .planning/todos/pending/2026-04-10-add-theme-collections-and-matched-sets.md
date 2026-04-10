---
created: 2026-04-10T09:06:55.728Z
title: Add theme collections and matched sets
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/placement_manager.gd
  - scenes/main.tscn
---

## Problem

The room-builder is gaining more decor ideas, but there is no system for surfacing curated sets that belong together. Without matched collections, the player has to mentally assemble themes instead of discovering them through the UI.

## Solution

Add a lightweight collection layer that groups compatible items into named themes such as cozy study, rainy-night bedroom, retro office, or minimalist apartment. The first pass should emphasize discovery and shopping flow, not hard restrictions on what can be mixed together.
