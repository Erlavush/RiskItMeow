# Risk It Meow

## What This Is

Risk It Meow is a browser-first Godot game focused on a local cozy room sandbox with Minecraft-style presentation, room decoration, and sample cats. The immediate goal is not to port the full shared-room/Firebase/couple stack from `Z:\FAHHHH`; it is to port the local room-builder slice first: walls, roof, occlusion, grid placement, and floor/wall/ceiling/surface decor systems, while keeping the current direct player/camera controls.

## Core Value

The player can smoothly walk around a cozy room in the browser and decorate it with reliable local-only building systems.

## Requirements

### Validated

- [x] Player can move around a simple 3D Godot scene using the current direct keyboard/mouse controller. - existing prototype
- [x] Player can switch between freecam, third-person, and first-person views. - existing prototype
- [x] Player can render a Minecraft-style avatar and load a skin at runtime. - existing prototype

### Active

- [ ] Godot supports a local room shell with floor, four walls, and a roof/ceiling.
- [ ] Godot supports camera-driven wall and roof occlusion so the room interior stays readable.
- [ ] Godot supports grid-based placement for floor, wall, ceiling/roof, and surface decor items.
- [ ] Godot supports sample cats in-room as part of the local sandbox slice.
- [ ] The local room-builder slice stays browser-first and avoids backend, Firebase, shared-room, or couple-join systems.
- [ ] The click-to-move flow from the source R3F runtime is intentionally not ported; the current direct movement/camera model remains the control baseline.

### Out of Scope

- Firebase, authentication, shared-room sync, partner presence, or any couple-join flow - explicitly removed from the current target.
- Click-to-move player locomotion from the source runtime - the current direct movement system stays in place.
- Full feature parity with the source R3F game at this stage - the first milestone is the local room-builder foundation only.

## Context

- The source repo in `Z:\FAHHHH` contains many more systems than this repo currently needs, including Firebase-backed shared-room logic and couple features. Those systems are no longer part of the immediate target.
- The useful source references for the current milestone are the local room-builder systems: room shell, wall occlusion, placement, windows, surface decor anchoring, and sample pet/cat behavior.
- The current Godot repo already has a usable player controller, camera modes, a Minecraft-style avatar rig, and runtime skin loading, which should be preserved.
- The engine move is still motivated by browser performance and stability, but the scope is now deliberately narrowed to local gameplay and building systems first.

## Constraints

- **Platform**: Browser-first Godot delivery - the room-builder slice must stay viable for web export.
- **Scope**: Local-only milestone - no backend, no shared-room, no Firebase, no couple systems.
- **Controls**: Keep the current direct movement/camera approach - do not reintroduce click-to-move while building this slice.
- **Architecture**: Reuse and extend the existing Godot prototype instead of restarting from zero.
- **Parity boundary**: Only port the local room-builder, shell, occlusion, and sample-cat systems that matter to this milestone.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remove Firebase/shared-room/couple scope from the current project target | The user explicitly does not want backend or two-player systems in this milestone | The active roadmap excludes backend, Firebase, shared-room, and couple systems. |
| Keep the current Godot movement and camera model | The user explicitly does not want click-to-move ported over | Direct keyboard/mouse movement and the existing camera modes remain the control baseline. |
| Phase 1 should implement the local room-builder foundation instead of only documenting a broader migration | The current need is concrete local gameplay/building capability, not platform-wide backend parity planning | Phase 1 is planned as a code-delivery phase for shell, occlusion, placement, and sample cats. |
| Use the source R3F repo only as a reference for local builder systems relevant to this slice | The source repo contains much more scope than the current Godot milestone should inherit | The source repo is treated as a targeted reference for room shell, placement, occlusion, and cat behavior only. |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-02 after scope correction to local-only room-builder systems*
