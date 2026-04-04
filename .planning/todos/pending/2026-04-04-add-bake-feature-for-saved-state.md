---
created: 2026-04-04T14:14:04.386Z
title: Add bake feature for saved state
area: tooling
files:
  - scenes/main.tscn
  - scripts/debug/developer_environment_panel.gd
  - scripts/placement/placement_manager.gd
---

## Problem

The project now persists the developer environment preset in `user://developer_environment_settings.cfg` and the room layout in `user://room_layout.json`. Those local saves can be restored at runtime and mirrored in the editor preview, but they are still not written into the actual scene or project resources. The user wants a later "bake" workflow so a good runtime-tuned state can become the real default instead of remaining machine-local preview data.

## Solution

Add explicit bake actions rather than silently overwriting project files. The likely split is:

- Bake environment only: write the current saved environment and light values into `main.tscn`
- Bake room layout only: turn the current saved layout into real default scene content or a project resource
- Bake both: perform both steps together

Keep the existing `user://` persistence flow for temporary iteration, but add a separate permanent write path that is safe, intentional, and easy to commit.
