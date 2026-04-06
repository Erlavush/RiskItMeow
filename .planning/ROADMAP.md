# Roadmap: Risk It Meow

## Milestones

- [ ] **v1.0 Manual Feature Buildout** - Continue from the current Godot room-building baseline through direct user-requested features.

## Overview

This repo no longer follows a source-porting roadmap. The current prototype baseline includes a player, an `8x8` room shell with four walls and a roof, an orbit camera, a placement system, a camera-driven cutaway system, a developer environment panel, and an inventory/shop browser.

**Execution guardrails:**
- Do not assume source-project parity work.
- Do not add backend, multiplayer, shared-room, or couple systems.
- Do not continue old bundled phase plans unless the user explicitly asks to start structured planning again.

## Current Baseline

- Active scene: player + `8x8` room shell + orbit camera + placement system + cutaway controller + developer environment panel
- The room shell uses four walls and a roof, with runtime cutaway hiding camera-facing shell surfaces
- Placement supports Build/Edit modes, move/duplicate/delete, save/load/clear, wall windows with real cutouts, and local persistence
- The placement UI uses Inventory/Shop browsing with category tabs, cached PNG preview cards, owned stock counts, and free unlimited buying
- The shop scans `assets/props/low_poly_household` and currently exposes `112` imported FBX props across `14` categories
- `assets/ui/item_previews` currently contains `120` cached preview PNGs used by the browser UI
- Room layouts persist locally and restore placed furniture, owned inventory stock, and floor finish on startup
- The editor 3D preview mirrors the last locally saved room layout and developer-environment preset
- The developer environment panel includes Morning, Noon, Sunset, and Afternoon Cozy presets
- The inventory includes wall-mounted windows, and the room shell rebuilds wall segments around window openings at runtime
- Wall cutaway is render-only, so room shadows and collisions stay intact while the interior is visible
- Sun-facing windows add lightweight fake interior sunlight so rooms stay readable without real-time GI

## Current Stability Notes

- Browser previews are now stabilized by pre-generated PNG thumbnails instead of runtime live 3D mini-scenes.
- Imported FBX browsing works, but individual asset tuning is still an ongoing polish area.
- The `temporary/` directory is intentionally ignored by Godot scanning to prevent duplicate UID warnings while preserving legacy import dependencies.

## Phases

There are currently no active planned phases.

If the user wants structured planning again later, create a new phase from the current baseline instead of reviving removed porting plans.

## Next Step

Ask for the next feature directly from the updated baseline, or do a targeted imported-furniture tuning pass if the user wants the new household pack polished before more gameplay features.

---
*Last updated: 2026-04-07 after stabilizing browser previews and generating cached thumbnails*
