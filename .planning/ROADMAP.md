# Roadmap: Risk It Meow

## Milestones

- [ ] **v1.0 Manual Feature Buildout** - Continue from the minimal Godot baseline through direct feature requests.

## Overview

This repo no longer follows a source-porting roadmap. The current prototype baseline now includes a player, an 8x8 room shell with four walls and a roof, a single orbit camera, a runtime placement prototype, a camera-driven cutaway system, and a developer environment tuning panel. Future work is manual, narrow, and added only when the user explicitly asks for it.

**Execution guardrails:**
- Do not assume source-project parity work.
- Do not add backend, multiplayer, shared-room, or couple systems.
- Do not continue old bundled phase plans unless the user explicitly asks to start structured planning again.

## Current Baseline

- Active scene: player + 8x8 room shell + one orbit camera + placement prototype + developer environment panel
- The room shell now uses four walls and a roof, with runtime cutaway hiding the camera-facing shell surfaces
- Placement currently supports `Simple Wood Chair`, `Office Chair`, `Office Desk + Computer`, and `Fridge`
- The placement UI includes stock UI, Build/Edit mode switching, dotted grid overlay, brown/checker floor switching, preview validation, runtime gizmo movement, placed-item edit controls, and room-layout save/load controls
- Room layouts persist locally and restore placed furniture plus floor finish on startup
- The editor 3D preview now mirrors the last locally saved room layout and developer-environment preset
- The developer environment panel now includes Morning, Noon, and Sunset sun presets
- The inventory now includes wall-mounted windows, and the room shell rebuilds wall segments around window openings at runtime
- Wall cutaway is render-only, so room shadows and collisions stay intact while the interior is visible
- Sun-facing windows now add lightweight fake interior sunlight so rooms stay readable without real-time GI
- The default presentation floor is a pixelated dark-brown linen tile repeated once per floor block with random per-cell rotation

## Phases

There are currently no active planned phases.

If the user wants structured planning again later, create a new phase from the current baseline instead of reviving the removed porting plans.

## Next Step

Ask for the next feature directly from the updated baseline. The placement system now already supports floor props, wall windows with real wall cutouts, edit actions, and local room persistence.

---
*Last updated: 2026-04-04 after adding window sunlight workaround*
