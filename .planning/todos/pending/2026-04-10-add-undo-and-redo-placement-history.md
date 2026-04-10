---
created: 2026-04-10T08:59:31.126Z
title: Add undo and redo placement history
area: general
files:
  - scripts/placement/placement_manager.gd
  - scripts/placement/placement_room_layout_store.gd
  - scenes/main.tscn
---

## Problem

The builder workflow now supports richer placement, editing, duplication, and deletion, but there is still no undo or redo safety net. That makes experimentation riskier than it should be and slows down layout iteration, especially as the catalog and placement precision keep expanding.

## Solution

Add an action-history layer that records user-facing placement operations such as place, move, rotate, duplicate, delete, purchase, and floor-style changes. Keep it command-based instead of save-file-based so it remains fast, reversible, and local to the current editing session, then integrate it into the placement UI with clear shortcuts and status feedback.
