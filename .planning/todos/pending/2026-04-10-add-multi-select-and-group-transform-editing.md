---
created: 2026-04-10T08:59:31.126Z
title: Add multi-select and group transform editing
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_gizmo_factory.gd
  - scripts/placement/placement_room_layout_store.gd
---

## Problem

The current edit flow works one item at a time, which becomes inefficient once the player starts building full desk setups, dining arrangements, shelves, or repeated decor clusters. There is no way to select and manipulate a group as one design unit.

## Solution

Add multi-selection plus grouped move, rotate, duplicate, and delete operations. The first version should define how group bounds, pivot choice, selection toggles, and save-load behavior work without breaking the existing single-item editing flow. Keep group actions optional and explicit so they do not interfere with normal precise decoration.
