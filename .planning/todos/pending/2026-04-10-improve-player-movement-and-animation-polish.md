---
created: 2026-04-10T08:01:21.500Z
title: Improve player movement and animation polish
area: general
files:
  - scripts/player.gd
  - scripts/MinecraftRig.gd
  - scenes/player.tscn
---

## Problem

The user wants smoother player motion and better animation, but the current controller is still a practical direct-movement baseline with limited locomotion states and simple rig posing. It works, but it does not yet sell weight, transitions, sit or use poses, or more polished first-person and room-view presentation.

## Solution

Build a clearer locomotion and pose layer on top of the existing controller rather than replacing the controls. The first pass should improve acceleration and deceleration feel, turning response, idle variation, walk and run presentation, and camera-mode transitions. After that baseline is stable, add dedicated interaction poses such as sitting or using furniture.
