---
created: 2026-04-10T09:06:55.728Z
title: Add room journal and snapshot captions
area: general
files:
  - scenes/main.tscn
  - scripts/placement/placement_room_layout_store.gd
  - scripts/player.gd
---

## Problem

As rooms evolve, the player may want to preserve specific looks and attach small notes or stories to them. There is currently no journaling or caption system around saved room states or photos.

## Solution

Add a lightweight journal tied to snapshots, room states, or photo-mode captures. The first pass should support local notes, labels, and timestamps without requiring a full narrative or social system.
