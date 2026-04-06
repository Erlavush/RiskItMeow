---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: manual-feature-buildout
status: paused
stopped_at: Browser preview system stabilized with cached PNG thumbnails; baseline handed off for the next clean conversation
last_updated: "2026-04-07T00:00:00+08:00"
last_activity: 2026-04-07 -- replaced unstable live browser previews with generated PNG thumbnails, fixed preview camera orientation, and updated handoff docs
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-07)

**Core value:** Keep the Godot prototype clean and easy to extend by adding one requested feature at a time.
**Current focus:** Manual feature-by-feature Godot development from the placement-enabled room-building baseline

## Current Position

Phase: none
Status: Paused - browser previews are stabilized and the project is ready for the next requested feature
Last activity: 2026-04-07 -- stabilized Shop/Inventory previews with cached PNG thumbnails, regenerated previews, and refreshed docs

## Baseline Snapshot

- Runtime scene uses one player, one `8x8` room shell with four walls and a roof, one room-view orbit camera, one placement manager, one room cutaway controller, one room sunlight controller, and one developer environment panel.
- The live build surface uses a pixelated dark-brown `32x32` linen tile repeated once per floor block with random rotation, plus a checkerboard fallback finish in the UI.
- Placement includes Build/Edit modes, gizmo drag, preview validity states, wall-mounted windows, real wall cutouts, move/duplicate/delete popup actions, local room-layout persistence, and wall cutaway support.
- Placement now uses a browser-style `Inventory / Shop` UI with category tabs, free unlimited buying, owned-stock tracking, and cached preview PNGs.
- The shop dynamically scans `assets/props/low_poly_household` and currently exposes `112` imported FBX props across `14` categories.
- `assets/ui/item_previews` now contains `120` generated PNG thumbnails used by the browser UI.
- Room layouts persist locally through `user://room_layout.json`, including placed items, transforms, owned inventory totals, and floor finish.
- The developer panel can tune lighting, fog, glow, and post-adjustment live and persists locally through `user://developer_environment_settings.cfg`.
- The editor 3D preview mirrors both of those local saved states through tool-mode preview loaders instead of baking them into the scene file.
- Window placement rebuilds the target wall into segmented geometry so the placed window leaves a real wall opening.
- Camera-facing walls and the roof switch to a render-only cutaway mode during runtime so the room interior stays visible without dropping collisions or shadows.
- Sun-facing windows add cheap interior portal lights and a soft room bounce light, and the window mesh itself no longer blocks sunlight with solid shadows.
- The developer environment panel supports persistent Morning, Noon, Sunset, and Afternoon Cozy sun presets.
- No external source project is an active reference or port target.

## Known Rough Edges

- Many imported FBX props still need per-item collision, scale, pivot, and orientation tuning.
- Browser thumbnails are now stable, but they need to be regenerated if the imported catalog changes or preview framing logic changes.
- The legacy pizzeria source assets are intentionally preserved under `temporary/` and hidden from scanning with `.gdignore` to avoid duplicate UID warnings without breaking old dependency paths.

## Rules For The Next Conversation

- Ask for one feature at a time.
- Do not assume any source-project parity or source-porting task.
- Keep the project local-only unless the user explicitly expands the scope.
- Keep direct movement and the current room camera unless the user asks to change them.
- Treat the current placement/browser system as active baseline behavior unless the user asks to replace it.
- Keep cats and backend scope inactive until they are explicitly requested again.

## Session Continuity

Last session: 2026-04-07
Stopped at: Browser preview stabilization and docs/handoff refresh
Resume command: Continue from the current build/edit placement baseline, with the Inventory/Shop browser, imported household FBX catalog, cached PNG item previews, room cutaway, window sunlight workaround, and developer sun presets active, and implement the next requested feature

## Accumulated Context

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
