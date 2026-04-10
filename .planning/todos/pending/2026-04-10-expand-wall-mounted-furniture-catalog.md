---
created: 2026-04-10T08:01:21.500Z
title: Expand wall-mounted furniture catalog
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/debug/debug_world_controller.gd
---

## Problem

The user wants more wall furniture, but the current runtime wall catalog is still very small and mostly demonstrates windows plus the wooden clock. That leaves the wall-placement system underused and limits how finished the room can feel.

## Solution

Use the existing wall-mount pipeline to add curated wall content such as mirrors, posters, frames, shelves, cabinets, curtains, wall lamps, and similar decor. Keep new items in the same data-driven catalog and Item Studio tuning flow so wall bounds, mount depth, cutaway behavior, and any wall-opening logic stay unified instead of creating one-off wrappers.
