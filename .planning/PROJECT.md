# Risk It Meow

## What This Is

Risk It Meow is now a manual-feature Godot prototype. The active scene includes one player, a 10x10 floor platform, one room-view orbit camera, and a runtime placement prototype for furniture. New features are still added manually, one request at a time.

## Core Value

Keep the project easy to change by preserving a clean baseline and only adding features the user explicitly asks for.

## Requirements

### Validated

- [x] The player can move with the existing direct keyboard and mouse controller.
- [x] The game uses one room-view orbit camera instead of the old multi-camera stack.
- [x] The main scene shows a floor platform in the editor and at runtime.
- [x] The player stands upright on the floor without the earlier tilt and floating issue.
- [x] The active scene now includes a working chair placement prototype with grid snapping, runtime gizmo controls, and placement validation.
- [x] The floor is an exact 10x10 checkered build surface and the player can reach the border tiles correctly.
- [x] Walls and roof geometry stay hidden in the live scene.

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
- The room shell is currently used as a floor-only build stage with walls and ceiling hidden.
- Placement now includes a left-side inventory, chair stock, dotted grid overlay, preview states, and runtime gizmo dragging.

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
| Keep walls hidden while the build floor evolves | The user is currently focused on floor placement quality, not room enclosure | The live scene stays floor-only even though placement is active |

---
*Last updated: 2026-04-02 after adding the placement prototype and camera/build polish*
