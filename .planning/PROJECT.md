# Risk It Meow

## What This Is

Risk It Meow is now a manual-feature Godot prototype. The active scene includes one player, an 8x8 room shell with four walls and a roof, one room-view orbit camera, a runtime placement prototype for furniture, a camera-driven cutaway controller, and a developer environment tuning panel. New features are still added manually, one request at a time.

## Core Value

Keep the project easy to change by preserving a clean baseline and only adding features the user explicitly asks for.

## Requirements

### Validated

- [x] The player can move with the existing direct keyboard and mouse controller.
- [x] The game uses one room-view orbit camera instead of the old multi-camera stack.
- [x] The main scene shows the room floor, four walls, and roof in the editor.
- [x] The player stands upright on the floor without the earlier tilt and floating issue.
- [x] The active scene now includes a working chair placement prototype with grid snapping, runtime gizmo controls, and placement validation.
- [x] The active room is an exact 8x8 build surface and the player can reach the border tiles correctly.
- [x] The active room now uses all four walls and a roof, with camera-driven cutaway used to reveal the interior at runtime.
- [x] The floor can switch between a checkerboard debug finish and a brown mat finish from the placement UI.
- [x] The brown mat finish uses a pixelated `32x32` linen tile repeated once per floor block with random `90` degree rotation per cell.
- [x] The furniture inventory currently includes Simple Wood Chair, Office Chair, Office Desk + Computer, and Fridge.
- [x] A developer-only environment panel can tune lighting, fog, glow, and post-processing and persist those settings locally.
- [x] The placement UI now supports a Build/Edit mode toggle, and Edit mode automatically shows the grid and disables new inventory placement.
- [x] In Edit mode, double-clicking a placed furniture item starts a move session using the same placement gizmo and validation rules.
- [x] While editing a placed furniture item, the popup can now move, duplicate, delete, or cancel that item.
- [x] The room layout now persists locally, restoring placed items and floor finish automatically on startup.
- [x] The left panel now includes Save, Load, and Clear Room controls, and room changes autosave after furniture or floor-finish edits.
- [x] The inventory now includes a wall-mounted Window item imported from a local GLB asset.
- [x] Placing a window on a wall now cuts a matching rectangular opening into the wall mesh instead of leaving the wall solid.
- [x] The editor 3D preview now mirrors the locally saved room layout and saved developer-environment preset without baking them into the scene file.
- [x] Runtime camera cutaway now hides the camera-facing walls and roof in a render-only way while preserving shadows and collisions.
- [x] Sun-facing windows now add a lightweight interior portal-light workaround so rooms do not go fully dark without real-time GI.
- [x] The developer environment panel now includes persistent Morning, Noon, and Sunset sun presets.

### Active

- [ ] Add the next gameplay or presentation feature only when it is explicitly requested.

### Out of Scope

- Any broad source-porting or parity roadmap.
- Firebase, backend sync, shared-room, couple, or multiplayer systems.
- Click-to-move locomotion.
- Cats and unrelated legacy systems until they are requested again.

## Context

- The earlier source-porting direction has been intentionally removed.
- The current prototype still reuses the existing Godot player controller, Minecraft-style rig, and orbit camera.
- The room shell is now used as a full single-room shell with four walls and a roof, while runtime cutaway keeps the interior readable.
- Placement now includes a left-side inventory, stock counts, Build/Edit mode switching, dotted grid overlay, floor-finish switching, Save/Load/Clear Room controls, floor furniture, wall windows, preview states, and runtime gizmo dragging.
- Camera-facing walls and the roof now switch to a cutaway render mode at runtime instead of being actually removed, which keeps wall collisions and shadows intact.
- Window lighting now uses a fake-but-cheap approach: directional sun still drives the outdoor lighting direction, while sun-facing windows create warm non-shadowing interior fill lights and a room bounce light.
- A developer panel in the top-right exposes live environment tuning, stores those values in `user://developer_environment_settings.cfg`, and now reapplies the saved preset in the editor preview.
- That same panel now exposes Morning, Noon, and Sunset presets for the directional sun.

## Constraints

- Manual workflow only: one requested feature at a time.
- Keep the prototype local-only unless scope is explicitly expanded later.
- Keep the current direct movement controller unless the user asks to replace it.
- Keep the current placement system as the active furniture-editing baseline unless the user asks to replace it.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remove broad source-porting from the active direction | The user wants an original Godot direction instead of broad parity work | Future changes are driven by direct feature requests, not source-repo parity |
| Reset the live scene to a minimal baseline | A small baseline is easier to inspect, debug, and extend safely | The project restarted from floor + player + one orbit camera |
| Add a runtime placement prototype on top of the baseline | The user requested build-style furniture placement as the next major feature | The current world now includes grid snapping, chair inventory, preview validation, and runtime gizmos |
| Move from one-wall staging to full-shell cutaway | The user wants a proper room shell without losing the ability to see inside while building | The room now uses four walls plus a roof, and a camera-driven cutaway controller hides only the camera-facing shell surfaces at runtime |
| Use portal-style fake interior sunlight instead of full GI | The room needs light to feel like it passes through windows, but full global illumination is unnecessary and heavier for this prototype | Sun-facing windows now inject lightweight interior fill lights while the actual directional light keeps the main sun direction and shadowing |
| Add persistent sun presets to the developer workflow | The user wants fast time-of-day changes without manually re-aiming the sun each time | The developer panel now applies and saves Morning, Noon, and Sunset sun presets |
| Add a developer environment tuning panel instead of hardcoding lighting tweaks | The user wants to iterate scene presentation without repeated code changes | Lighting, fog, glow, and post-adjustment can now be tuned live and saved locally |
| Turn the floor into a per-cell pixelated brown mat | The user wants a more intentional presentation floor than the plain checkerboard | The current brown floor uses a `32x32` linen-derived tile repeated once per floor cell |
| Add an edit mode on top of the build placement prototype | The user wants to reposition already placed furniture instead of only placing new items | The placement manager now supports double-click move, duplicate, and delete flows for placed furniture |
| Persist the room layout locally | The prototype needed to remember placed furniture and floor finish across runs | The room now autosaves to `user://room_layout.json` and can also be saved, loaded, or cleared from the left panel |
| Add real wall window placement instead of only floor props | The user wants windows to mount into walls and leave real openings for future wall decor systems | The placement manager now supports wall-mounted window placement, and the room shell rebuilds segmented walls around window openings |
| Mirror local saved state in the editor preview | The user wants saved room layout and lighting tweaks visible in the editor 3D view without rebaking the scene each time | Tool-mode preview logic now reapplies `user://room_layout.json` and `user://developer_environment_settings.cfg` while the scene is open in the editor |

---
*Last updated: 2026-04-04 after adding window sunlight workaround*
