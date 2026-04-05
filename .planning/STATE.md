---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: manual-feature-buildout
status: paused
stopped_at: Developer sun presets implemented; awaiting the next requested feature
last_updated: "2026-04-04T00:00:00+08:00"
last_activity: 2026-04-04 -- added Morning/Noon/Sunset sun presets and updated docs
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-02)

**Core value:** Keep the Godot prototype clean and easy to extend by adding one requested feature at a time.
**Current focus:** Manual feature-by-feature Godot development from the placement-enabled prototype

## Current Position

Phase: none
Status: Paused - developer sun presets are now part of the baseline, awaiting the next feature
Last activity: 2026-04-04 -- added Morning/Noon/Sunset sun presets and updated docs

## Baseline Snapshot

- Runtime scene uses one player, one 8x8 room shell with four walls and a roof, one room-view orbit camera, one placement manager, one room cutaway controller, and one developer environment panel.
- The live build surface uses a pixelated dark-brown `32x32` linen tile repeated once per floor block with random rotation, plus a checkerboard fallback finish in the UI.
- Placement inventory currently includes `Simple Wood Chair`, `Office Chair`, `Office Desk + Computer`, `Fridge`, and `Window`, with runtime preview, gizmo drag, Build/Edit modes, double-click edit selection, move/duplicate/delete popup actions, local room-layout persistence, and wall-mounted placement support.
- The developer panel can tune lighting, fog, glow, and post-adjustment live and persists locally through `user://developer_environment_settings.cfg`.
- Room layouts now persist locally through `user://room_layout.json`, including placed items, transforms, and floor finish.
- The editor 3D preview now mirrors both of those local saved states through tool-mode preview loaders instead of baking them into the scene file.
- Window placement now rebuilds the target wall into segmented geometry so the placed window leaves a real wall opening.
- Camera-facing walls and the roof now switch to a render-only cutaway mode during runtime so the room interior stays visible without dropping collisions or shadows.
- Sun-facing windows now add cheap interior portal lights and a soft room bounce light, and the window mesh itself no longer blocks sunlight with solid shadows.
- The developer environment panel now supports persistent Morning, Noon, and Sunset sun presets.
- No external source project is an active reference or port target.

## Rules For The Next Conversation

- Ask for one feature at a time.
- Do not assume any source-project parity or source-porting task.
- Keep the project local-only unless the user explicitly expands the scope.
- Keep direct movement and the current room camera unless the user asks to change them.
- Treat the current placement/inventory prototype as active baseline behavior unless the user asks to replace it.
- Keep cats and backend scope inactive until they are explicitly requested again.

## Session Continuity

Last session: 2026-04-04
Stopped at: Developer sun presets implemented
Resume command: Continue from the current persisted build/edit placement baseline, with runtime cutaway, window sunlight workaround, and sun presets active, and implement the next requested feature

## Accumulated Context

### Pending Todos

- 1 pending todo in `.planning/todos/pending/`
- `2026-04-04-add-bake-feature-for-saved-state.md` - Add bake feature for saved state

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260404-nn8 | Add developer environment tuning panel for lighting and post-processing | 2026-04-04 | working-tree | [260404-nn8-add-developer-environment-tuning-panel-f](./quick/260404-nn8-add-developer-environment-tuning-panel-f/) |
