# Risk It Meow

## What This Is

Risk It Meow is now a fresh Godot prototype baseline. The active scene is intentionally minimal: one player, one visible floor platform, and one room-view orbit camera. New features are added manually, one request at a time.

## Core Value

Keep the project easy to change by preserving a clean baseline and only adding features the user explicitly asks for.

## Requirements

### Validated

- [x] The player can move with the existing direct keyboard and mouse controller.
- [x] The game uses one room-view orbit camera instead of the old multi-camera stack.
- [x] The main scene shows a floor platform in the editor and at runtime.
- [x] The player stands upright on the floor without the earlier tilt and floating issue.
- [x] The active scene no longer includes cats, build mode, placement UI, walls, or roof geometry.

### Active

- [ ] Add the next gameplay or presentation feature only when it is explicitly requested.

### Out of Scope

- Any broad source-porting or parity roadmap.
- Firebase, backend sync, shared-room, couple, or multiplayer systems.
- Click-to-move locomotion.
- Cats, build mode, placement systems, walls, and roof until they are requested again.

## Context

- The earlier source-porting direction has been intentionally removed.
- The current baseline still reuses the existing Godot player controller, Minecraft-style rig, and orbit camera.
- The room shell is currently used as a floor-only stage.

## Constraints

- Manual workflow only: one requested feature at a time.
- Keep the prototype local-only unless scope is explicitly expanded later.
- Keep the current direct movement controller unless the user asks to replace it.
- Do not reintroduce removed systems by default.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remove broad source-porting from the active direction | The user wants an original Godot direction instead of broad parity work | Future changes are driven by direct feature requests, not source-repo parity |
| Reset the live scene to a minimal baseline | A small baseline is easier to inspect, debug, and extend safely | The current world is floor + player + one orbit camera |
| Remove cats and build-mode systems from the active baseline | Those systems are not part of the immediate next step | They are no longer mounted in the main scene and are treated as inactive |

---
*Last updated: 2026-04-02 after resetting the repo to a manual feature-by-feature baseline*
