---
created: 2026-04-10T09:06:55.728Z
title: Add guided onboarding and contextual build tips
area: general
files:
  - scenes/main.tscn
  - scripts/player.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The room-builder has accumulated placement modes, edit flows, and camera options, but new players still receive very little structured guidance. Without onboarding, useful systems may stay hidden or feel more complex than they are.

## Solution

Add soft onboarding plus context-aware tips that teach building, editing, camera switching, and later interaction systems. The first pass should be dismissible and lightweight rather than a long forced tutorial.
