# Risk It Meow - Working Roadmap

## Project Overview

Risk It Meow is a manual-feature Godot room-building prototype. The live baseline is no longer the old minimal floor-only scene. It now includes a player, an `8x8` room shell with four walls and a roof, an orbit room camera, runtime furniture placement, cutaway walls, persistent local layout save/load, and a developer lighting panel.

The repo is still feature-driven one request at a time. There is no active source-porting roadmap.

## Current Baseline

- One player controller with direct movement
- One room-view orbit camera
- One `8x8` room shell with four walls and a roof
- Camera-driven wall/roof cutaway for interior visibility
- Build/Edit placement workflow with gizmo drag and rotation
- Inventory/Shop browser UI with category tabs
- `112` imported FBX household props across `14` categories, plus legacy starter items
- Cached PNG item thumbnails in `assets/ui/item_previews`
- Local room persistence in `user://room_layout.json`
- Local developer lighting persistence in `user://developer_environment_settings.cfg`

## Rules For New Sessions

- Read [`.planning/STATE.md`](/Z:/RiskItMeow/risk-it-meow/.planning/STATE.md) and [`.planning/PROJECT.md`](/Z:/RiskItMeow/risk-it-meow/.planning/PROJECT.md) first.
- Treat the current placement/browser system as the active baseline, not a prototype to remove by default.
- Do not assume any source-porting or parity work.
- Add one requested feature at a time from the current Godot baseline.
- Do not add backend, Firebase, multiplayer, shared-room, couple, or online systems unless explicitly requested.
- Do not remove the current room shell, cutaway system, or developer panel unless explicitly requested.

## Current Reality Check

- Browser item previews no longer use live 3D preview scenes at runtime.
- Shop/Inventory cards now rely on generated PNG thumbnails for stability.
- Imported FBX props are available, but many still use generic collision/scale heuristics and will need per-item tuning over time.
- The `temporary/` pizzeria source folder is intentionally hidden from Godot scanning with `.gdignore` to avoid duplicate UID spam while preserving old dependency paths.

## Next Step

Either:
- continue the next requested gameplay/building feature from the current baseline, or
- do a focused imported-prop tuning pass if the user wants the new furniture pack polished before more features.
