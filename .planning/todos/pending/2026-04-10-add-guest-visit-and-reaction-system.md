---
created: 2026-04-10T09:06:55.728Z
title: Add guest visit and reaction system
area: general
files:
  - scenes/main.tscn
  - scripts/player.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The room can already be decorated for the player, but there is no visitor loop that acknowledges the result. Guest reactions could make completed rooms feel more meaningful without forcing multiplayer or online sharing.

## Solution

Add simple NPC or visitor appearances that enter, look around, and comment or react to the room mood. The first pass should be lightweight and local, focused on presentation and feedback rather than complex character systems.
