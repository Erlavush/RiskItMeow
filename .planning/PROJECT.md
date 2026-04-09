# Risk It Meow

## What This Is

Risk It Meow is a manual-feature Godot prototype. The active scene includes one player, an `8x8` room shell with four walls and a roof, an orbit room camera plus a first-person camera mode, a runtime placement system for furniture, a camera-driven cutaway controller, a developer environment tuning panel, and a dedicated single-item debug Item Studio. New features are still added manually, one request at a time.

## Core Value

Keep the project easy to change by preserving a clean baseline and only adding features the user explicitly asks for.

## Requirements

### Validated

- [x] The player can move with the existing direct keyboard and mouse controller.
- [x] The game uses one room-view orbit camera as the main building view, with a toggleable first-person player camera for in-room inspection.
- [x] The main scene shows an `8x8` room with floor, four walls, and a roof.
- [x] The player stands upright on the floor without the earlier tilt and floating issue.
- [x] The active scene includes a working furniture placement system with grid snapping, runtime gizmo controls, and placement validation.
- [x] The active room uses camera-driven cutaway to reveal the interior at runtime.
- [x] The floor can switch between a checkerboard debug finish and a brown mat finish from the placement UI.
- [x] The brown mat finish uses a pixelated `32x32` linen tile repeated once per floor block with random `90` degree rotation per cell.
- [x] The placement system supports Build and Edit modes.
- [x] In Edit mode, double-clicking a placed furniture item starts a move session using the same placement gizmo and validation rules.
- [x] While editing a placed furniture item, the popup can move, duplicate, delete, or cancel that item.
- [x] The room layout persists locally, restoring placed items and floor finish automatically on startup.
- [x] The left panel includes Save, Load, and Clear Room controls, and room changes autosave after furniture or floor-finish edits.
- [x] The inventory includes wall-mounted window items and placing a window cuts a matching opening into the wall mesh.
- [x] The editor 3D preview mirrors the locally saved room layout and saved developer-environment preset without baking them into the scene file.
- [x] Runtime camera cutaway hides the camera-facing walls and roof in a render-only way while preserving shadows and collisions.
- [x] Sun-facing windows add a lightweight interior portal-light workaround so rooms do not go fully dark without real-time GI.
- [x] The developer environment panel includes persistent Morning, Noon, Sunset, and Afternoon Cozy presets.
- [x] The left placement browser has `Inventory` and `Shop` tabs, category-filtered browsing, and free unlimited buying into owned stock.
- [x] The active furniture catalog uses one data-driven imported-item pipeline for the curated live items instead of per-item wrapper scripts.
- [x] The large archived `Low Poly Household Items` FBX pack has been removed from the repo.
- [x] The live catalog is currently a curated `7`-item set: `simple_wood_chair`, `office_chair`, `office_desk_computer`, `pizzeria_fridge`, `small_shelf`, `window`, and `window_classic`.
- [x] Browser cards now use generated PNG thumbnails instead of live runtime 3D preview scenes.
- [x] Item preview thumbnails are generated into `assets/ui/item_previews` and currently total `7` cached preview PNGs for the live catalog.
- [x] A dedicated debug `Item Studio` exists for per-item tuning with preview/edit modes, gizmos, local override saving, and mount-aware guides.
- [x] The player tools panel can switch between orbit room view and first-person view at runtime.

### Active

- [ ] Add the next gameplay or presentation feature only when it is explicitly requested.

### Known Rough Edges

- [ ] Some curated items still rely on manual local tuning overrides for perfect collision, offsets, and scale fit.
- [ ] `Small Shelf` and `Window (Classic)` still need original source confirmation for the consolidated third-party asset list.

### Out of Scope

- Any broad source-porting or parity roadmap.
- Firebase, backend sync, shared-room, couple, or multiplayer systems.
- Click-to-move locomotion.
- Cats and unrelated legacy systems until they are requested again.

## Context

- The earlier source-porting direction has been intentionally removed.
- The current prototype still reuses the existing Godot player controller, Minecraft-style rig, and orbit camera, but now also supports a first-person inspection mode.
- The room shell is used as a full single-room shell with four walls and a roof, while runtime cutaway keeps the interior readable.
- Placement includes a browser-style left panel with Build/Edit switching, Inventory/Shop tabs, category browsing, item preview cards, owned stock counts, dotted grid overlay, floor-finish switching, Save/Load/Clear Room controls, floor furniture, wall windows, preview states, and runtime gizmo dragging.
- Camera-facing walls and the roof switch to a cutaway render mode at runtime instead of being actually removed, which keeps wall collisions and shadows intact.
- Window lighting uses a fake-but-cheap approach: directional sun still drives the outdoor lighting direction, while sun-facing windows create warm non-shadowing interior fill lights and a room bounce light.
- A developer panel in the top-right exposes live environment tuning, stores those values in `user://developer_environment_settings.cfg`, and reapplies the saved preset in the editor preview.
- The shop browser no longer creates live 3D preview scenes at runtime. Instead it loads cached PNG thumbnails generated by the tooling script.
- The debug workflow now centers on a single-item Item Studio instead of the old multi-item showroom, and local item tuning overrides persist to `user://placement_item_profile_overrides.cfg`.
- A `temporary/.gdignore` file is intentionally present so Godot does not re-index duplicated legacy pizzeria source assets.

## Constraints

- Manual workflow only: one requested feature at a time.
- Keep the prototype local-only unless scope is explicitly expanded later.
- Keep the current direct movement controller unless the user asks to replace it.
- Keep the current placement system as the active furniture-editing baseline unless the user asks to replace it.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remove broad source-porting from the active direction | The user wants an original Godot direction instead of broad parity work | Future changes are driven by direct feature requests, not source-repo parity |
| Move from one-wall staging to full-shell cutaway | The user wants a proper room shell without losing the ability to see inside while building | The room now uses four walls plus a roof, and a camera-driven cutaway controller hides only the camera-facing shell surfaces at runtime |
| Use portal-style fake interior sunlight instead of full GI | The room needs light to feel like it passes through windows, but full global illumination is unnecessary and heavier for this prototype | Sun-facing windows now inject lightweight interior fill lights while the actual directional light keeps the main sun direction and shadowing |
| Add a developer environment tuning panel instead of hardcoding lighting tweaks | The user wants to iterate scene presentation without repeated code changes | Lighting, fog, glow, and post-adjustment can be tuned live and saved locally |
| Add persistent sun presets to the developer workflow | The user wants fast time-of-day changes without manually re-aiming the sun each time | The developer panel applies and saves Morning, Noon, Sunset, and Afternoon Cozy presets |
| Persist the room layout locally | The prototype needed to remember placed furniture and floor finish across runs | The room autosaves to `user://room_layout.json` and can also be saved, loaded, or cleared from the left panel |
| Add real wall window placement instead of only floor props | The user wants windows to mount into walls and leave real openings for future wall decor systems | The placement manager supports wall-mounted window placement, and the room shell rebuilds segmented walls around window openings |
| Mirror local saved state in the editor preview | The user wants saved room layout and lighting tweaks visible in the editor 3D view without rebaking the scene each time | Tool-mode preview logic reapplies `user://room_layout.json` and `user://developer_environment_settings.cfg` while the scene is open in the editor |
| Replace the simple stock list with a real shop and owned inventory browser | The user wants a scalable furniture workflow with categories, previews, and free buying before any coin system exists | The left panel separates Inventory from Shop, browses the curated imported-item catalog, and persists owned stock locally |
| Replace unstable live 3D card previews with cached PNG thumbnails | Runtime card previews were leaking objects into the live scene and producing broken/black images for imported assets | Browser cards now load generated PNG thumbnails from `assets/ui/item_previews`, and a preview generator script rebuilds them when the catalog changes |
| Collapse item debugging into a dedicated Item Studio | Editing item size/collision inside the old showroom flow was too noisy and inconvenient | The debug workflow now isolates one item at a time with preview/edit modes, gizmos, overlays, and persistent local tuning overrides |
| Keep a curated imported-item pipeline instead of the old giant household pack | The user wants a cleaner repo and only the chosen active items to remain live | The deleted household FBX pack is gone, the live catalog is curated, and the item pipeline stays unified and tunable |

---
*Last updated: 2026-04-09 after repo cleanup, Item Studio restoration, and planning-doc refresh*
