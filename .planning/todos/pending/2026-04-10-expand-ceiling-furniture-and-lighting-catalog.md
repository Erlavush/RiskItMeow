---
created: 2026-04-10T08:01:21.500Z
title: Expand ceiling furniture and lighting catalog
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/placement/macaws_ceiling_fan_placeable.gd
---

## Problem

The user wants more ceiling furniture and ceiling-mounted items, but the live ceiling catalog currently proves the path with only the fan. That leaves the ceiling placement system underused and limits how much mood lighting and overhead decor the room can support.

## Solution

Add more curated ceiling-mounted items such as pendant lights, chandeliers, ceiling lamps, hanging plants, speakers, vents, smoke detectors, or projectors through the same ceiling-mount workflow. Reuse the existing fan item as a reference for ceiling anchoring and animation, then layer lighting behavior only where it adds real value.
