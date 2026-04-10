---
created: 2026-04-10T08:01:21.500Z
title: Add room shell customization tools
area: general
files:
  - scripts/room/room_shell.gd
  - scripts/room/room_cutaway_controller.gd
  - scripts/debug/debug_world_controller.gd
---

## Problem

The user wants editable walls, editable ceiling or roof options, and dynamic increases to floor size, wall span, and wall height. The current room system is still one procedural rectangular shell with four walls and one ceiling, and multiple runtime systems assume those fixed dimensions.

## Solution

Start with a safe parameter-driven room editor instead of freeform structural editing. The first pass should expose room width, depth, wall height, and finish or style controls for walls and ceiling or roof surfaces while keeping the shell generated from validated dimensions. After that baseline exists, more complex structural edits can be layered on without breaking cutaway, placement, or save-load assumptions.
