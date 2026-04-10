---
created: 2026-04-10T08:59:31.126Z
title: Add photo mode and showcase camera
area: general
files:
  - scripts/player.gd
  - scripts/camera/room_view_camera_controller.gd
  - scenes/main.tscn
---

## Problem

The prototype is becoming more presentation-driven, but there is no dedicated way to stage and capture a finished room. The normal build and movement cameras are functional, yet they are not designed for clean screenshots, cinematic framing, or showcasing cozy layouts.

## Solution

Add a photo mode with controlled camera movement, UI hiding, and clean framing, with later room for depth-of-field or pose controls if needed. The first pass should prioritize stable camera controls and a polished presentation workflow over heavy rendering effects, so the feature remains useful during normal iteration.
