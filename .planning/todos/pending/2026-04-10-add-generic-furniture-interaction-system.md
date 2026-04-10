---
created: 2026-04-10T08:01:21.500Z
title: Add generic furniture interaction system
area: general
files:
  - scripts/player.gd
  - scripts/MinecraftRig.gd
  - scripts/placement/simple_wood_chair.gd
  - scripts/placement/imported_scene_placeable.gd
---

## Problem

The user wants interactions like sitting and playing on a PC, but the runtime currently focuses on placement and editing, not on using placed furniture. There is no reusable interact prompt, use action flow, reserved seat or use target, or state handoff between the player and a placeable item.

## Solution

Add a generic interaction contract before implementing chair and PC specifics. The first version should define how the player detects an interactable item, shows a prompt, starts and ends an interaction, and locks or redirects movement and animation while the interaction is active. Once that exists, `sit` and `use computer` can become item-specific implementations instead of isolated hacks.
