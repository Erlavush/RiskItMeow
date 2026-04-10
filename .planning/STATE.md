---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: manual-feature-buildout
status: active
stopped_at: Quick task 260409-whv delivered placement-mode improvements; next recommended step is manual in-game QA for free placement and smooth rotation feel
last_updated: "2026-04-10T08:59:31.126Z"
last_activity: 2026-04-10 -- implemented grid/free placement plus rotation snap/smooth toggles, then fixed rotated planar-bounds validation for smooth rotation on snapped placement
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
Status: Active - Phase 11 roadmap work is still paused, but the live baseline just gained placement-mode improvements through quick task 260409-whv
Last activity: 2026-04-10 -- shipped placement movement/rotation mode toggles and audited the resulting validation path

## Baseline Snapshot

- Runtime scene uses one player, one `8x8` room shell with four walls and a roof, one room-view orbit camera, one optional first-person camera mode, one placement manager, one room cutaway controller, one room sunlight controller, one developer environment panel, and one debug Item Studio controller.
- The live build surface uses a pixelated dark-brown `32x32` linen tile repeated once per floor block with random rotation, plus a checkerboard fallback finish in the UI.
- Placement includes Build/Edit modes, gizmo drag, preview validity states, wall-mounted windows, real wall cutouts, move/duplicate/delete popup actions, local room-layout persistence, and wall cutaway support.
- Placement tools now expose `Grid Placement` and `Rotation Snap` toggles so users can switch between snapped and free movement plus snapped and smooth rotation during build/edit sessions.
- Placement now uses a browser-style `Inventory / Shop` UI with category tabs, free unlimited buying, owned-stock tracking, and cached preview PNGs.
- The live runtime catalog is a curated `9`-item runtime-placement set: `simple_wood_chair`, `office_chair`, `office_desk_computer`, `pizzeria_fridge`, `wooden_block_clock`, `ceiling_fan`, `small_shelf`, `window`, and `window_classic`.
- `assets/ui/item_previews` contains generated browser thumbnails used by the runtime inventory/shop UI.
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
- Placement-mode improvements have headless smoke coverage and code-audit coverage, but they still need a final manual gameplay pass for drag feel and save/load confidence across all mount surfaces.

## Rules For The Next Conversation

- Ask for one feature at a time.
- Do not assume any source-project parity or source-porting task.
- Keep the project local-only unless the user explicitly expands the scope.
- Keep direct movement and the current room camera unless the user asks to change them.
- Treat the current placement/browser system as active baseline behavior unless the user asks to replace it.
- Keep backend scope inactive unless the user explicitly expands it.
- Treat cat companions as backlog only until the user selects them for active implementation.

## Session Continuity

Last session: 2026-04-10
Stopped at: Placement movement/rotation mode work is implemented; the next highest-value task is a manual runtime QA pass before returning to Tanuki Decor intake
Resume command: Launch the game, manually test `Grid Placement` and `Rotation Snap` on floor, wall, ceiling, and support-surface items, verify save/load behavior, then resume Phase 11 Tanuki Decor intake starting with small_fancy_vase

## Accumulated Context

### Roadmap Evolution

- Phase 11 added: Tanuki Decor Mod Asset Intake Strategy
- Phase numbering intentionally starts at `11` by user request for this roadmap branch

### Pending Todos

- 23 pending todos in `.planning/todos/pending/`
- `2026-04-04-add-bake-feature-for-saved-state.md` - Add bake feature for saved state
- `2026-04-10-add-ambient-minecraft-style-cat-companions.md` - Add ambient Minecraft-style cat companions
- `2026-04-10-add-undo-and-redo-placement-history.md` - Add undo and redo placement history
- `2026-04-10-add-room-blueprint-and-preset-system.md` - Add room blueprint and preset system
- `2026-04-10-add-furniture-recolor-and-material-variants.md` - Add furniture recolor and material variants
- `2026-04-10-add-multi-select-and-group-transform-editing.md` - Add multi-select and group transform editing
- `2026-04-10-add-smart-placement-alignment-guides.md` - Add smart placement alignment guides
- `2026-04-10-add-symmetry-and-mirror-build-mode.md` - Add symmetry and mirror build mode
- `2026-04-10-add-photo-mode-and-showcase-camera.md` - Add photo mode and showcase camera
- `2026-04-10-add-weather-ambience-outside-the-room.md` - Add weather ambience outside the room
- `2026-04-10-add-dynamic-ambient-audio-system.md` - Add dynamic ambient audio system
- `2026-04-10-add-room-coziness-scoring-system.md` - Add room coziness scoring system
- `2026-04-10-add-placeable-aquarium-with-animated-fish.md` - Add placeable aquarium with animated fish
- `2026-04-10-add-room-shell-customization-tools.md` - Add room shell customization tools
- `2026-04-10-add-second-floor-and-rooftop-support.md` - Add second floor and rooftop support
- `2026-04-10-expand-wall-mounted-furniture-catalog.md` - Expand wall-mounted furniture catalog
- `2026-04-10-expand-surface-decor-catalog.md` - Expand surface decor catalog
- `2026-04-10-expand-ceiling-furniture-and-lighting-catalog.md` - Expand ceiling furniture and lighting catalog
- `2026-04-10-improve-player-movement-and-animation-polish.md` - Improve player movement and animation polish
- `2026-04-10-add-generic-furniture-interaction-system.md` - Add generic furniture interaction system
- `2026-04-10-add-in-world-minecraft-time-display.md` - Add in-world Minecraft time display
- `2026-04-10-add-time-of-day-atmosphere-controller.md` - Add time-of-day atmosphere controller
- `2026-04-10-add-evening-auto-lighting-system.md` - Add evening auto-lighting system

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
| 260409-whv | Add grid/free placement and rotation snap/smooth toggles with shared placement validation updates | 2026-04-10 | working-tree | [260409-whv-add-a-graceful-grid-placement-toggle-so-](./quick/260409-whv-add-a-graceful-grid-placement-toggle-so-/) |
