---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: manual-feature-buildout
status: paused
stopped_at: Docs-first Phase 11 execution completed; Tanuki Decor intake is ready to begin one asset at a time starting with small_fancy_vase
last_updated: "2026-04-09T00:00:00+08:00"
last_activity: 2026-04-09 -- executed the docs-first Phase 11 workflow by adding a Tanuki Decor intake manifest, content inventory, and a one-by-one Blockbench guide
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 1
  completed_plans: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-09)

**Core value:** Keep the Godot prototype clean and easy to extend by adding one requested feature at a time.
**Current focus:** Manual feature-by-feature Godot development from the placement-enabled room-building baseline

## Current Position

Phase: 11 - Tanuki Decor Mod Asset Intake Strategy
Status: Paused - Phase 11 docs are executed and the project is ready to start the first Tanuki Decor asset one by one
Last activity: 2026-04-09 -- created the Tanuki Decor manifest, inventory, and Blockbench workflow guide

## Baseline Snapshot

- Runtime scene uses one player, one `8x8` room shell with four walls and a roof, one room-view orbit camera, one optional first-person camera mode, one placement manager, one room cutaway controller, one room sunlight controller, one developer environment panel, and one debug Item Studio controller.
- The live build surface uses a pixelated dark-brown `32x32` linen tile repeated once per floor block with random rotation, plus a checkerboard fallback finish in the UI.
- Placement includes Build/Edit modes, gizmo drag, preview validity states, wall-mounted windows, real wall cutouts, move/duplicate/delete popup actions, local room-layout persistence, and wall cutaway support.
- Placement now uses a browser-style `Inventory / Shop` UI with category tabs, free unlimited buying, owned-stock tracking, and cached preview PNGs.
- The live runtime catalog is a curated `7`-item imported-item set: `simple_wood_chair`, `office_chair`, `office_desk_computer`, `pizzeria_fridge`, `small_shelf`, `window`, and `window_classic`.
- `assets/ui/item_previews` now contains `7` generated PNG thumbnails used by the browser UI.
- Room layouts persist locally through `user://room_layout.json`, including placed items, transforms, owned inventory totals, and floor finish.
- The developer panel can tune lighting, fog, glow, and post-adjustment live and persists locally through `user://developer_environment_settings.cfg`.
- The debug Item Studio can tune curated item data locally through `user://placement_item_profile_overrides.cfg`.
- The editor 3D preview mirrors both of those local saved states through tool-mode preview loaders instead of baking them into the scene file.
- Window placement rebuilds the target wall into segmented geometry so the placed window leaves a real wall opening.
- Camera-facing walls and the roof switch to a render-only cutaway mode during runtime so the room interior stays visible without dropping collisions or shadows.
- Sun-facing windows add cheap interior portal lights and a soft room bounce light, and the window mesh itself no longer blocks sunlight with solid shadows.
- The developer environment panel supports persistent Morning, Noon, Sunset, and Afternoon Cozy sun presets.
- No external source project is an active reference or port target.

## Known Rough Edges

- Some curated items still need per-item collision, scale, pivot, and orientation tuning.
- Browser thumbnails are stable, but they need to be regenerated if the curated catalog changes or preview framing logic changes.
- The legacy pizzeria source assets are intentionally preserved under `temporary/` and hidden from scanning with `.gdignore` to avoid duplicate UID warnings without breaking old dependency paths.
- The Tanuki Decor intake manifest and one-by-one Blockbench guide now exist, but the workflow is still only proven at the documentation stage and has not been generalized across multiple mods yet.

## Rules For The Next Conversation

- Ask for one feature at a time.
- Do not assume any source-project parity or source-porting task.
- Keep the project local-only unless the user explicitly expands the scope.
- Keep direct movement and the current room camera unless the user asks to change them.
- Treat the current placement/browser system as active baseline behavior unless the user asks to replace it.
- Keep cats and backend scope inactive until they are explicitly requested again.

## Session Continuity

Last session: 2026-04-09
Stopped at: Docs-first Phase 11 execution after documenting the Tanuki Decor one-by-one intake workflow and starter assets
Resume command: Continue from the current build/edit placement baseline, read the Phase 11 Tanuki Decor inventory and Blockbench guide, start with small_fancy_vase, and help the user export one asset at a time before any Godot-side import work

## Accumulated Context

### Roadmap Evolution

- Phase 11 added: Tanuki Decor Mod Asset Intake Strategy
- Phase numbering intentionally starts at `11` by user request for this roadmap branch

### Pending Todos

- 1 pending todo in `.planning/todos/pending/`
- `2026-04-04-add-bake-feature-for-saved-state.md` - Add bake feature for saved state

### Useful Commands

- Regenerate browser item previews:
  - `Godot_v4.6.1-stable_win64_console.exe --path Z:\RiskItMeow\risk-it-meow --script res://scripts/tools/generate_item_previews.gd`
- Headless project boot:
  - `Godot_v4.6.1-stable_win64_console.exe --headless --path Z:\RiskItMeow\risk-it-meow --quit-after 1`
- Headless editor scan:
  - `Godot_v4.6.1-stable_win64_console.exe --headless --editor --path Z:\RiskItMeow\risk-it-meow --quit-after 1`

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260404-nn8 | Add developer environment tuning panel for lighting and post-processing | 2026-04-04 | working-tree | [260404-nn8-add-developer-environment-tuning-panel-f](./quick/260404-nn8-add-developer-environment-tuning-panel-f/) |
