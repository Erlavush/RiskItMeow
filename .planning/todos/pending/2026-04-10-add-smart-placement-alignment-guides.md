---
created: 2026-04-10T08:59:31.126Z
title: Add smart placement alignment guides
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_surface_queries.gd
  - scripts/placement/placement_ui_styles.gd
---

## Problem

Free placement and smooth rotation make decoration more expressive, but they also increase the need for subtle helper feedback. Right now the system validates bounds and collisions, yet it does not assist with centering, equal spacing, edge alignment, or matching rotations between nearby items.

## Solution

Add lightweight visual alignment guides that appear only when useful. The first pass should support centering on walls or room axes, matching edges against nearby furniture, consistent spacing hints, and optional angle matching. The guides should assist without forcing snapping, so free placement remains graceful.
