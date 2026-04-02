# Risk It Meow

## What This Is

Risk It Meow is a browser-first Godot game focused on a local cozy room sandbox with Minecraft-style presentation, room decoration, and sample cats. Phase 1 delivered the first playable local room-builder slice. Phase 2 has now been narrowed and stopped at the stable room-view orbit camera baseline. Future features will be requested and built manually, one change at a time, instead of continuing a broad preplanned porting pass.

## Core Value

The player can smoothly walk around a cozy room in the browser and decorate it with reliable local-only building systems.

## Requirements

### Validated

- [x] Player can move around a simple 3D Godot scene using the current direct keyboard/mouse controller. - existing prototype
- [x] Player can switch between freecam, third-person, and first-person views. - existing prototype
- [x] Player can render a Minecraft-style avatar and load a skin at runtime. - existing prototype
- [x] Godot supports a local room shell with floor, four walls, and a roof/ceiling. - Phase 1
- [x] Godot supports camera-driven wall and roof occlusion so the room interior stays readable. - Phase 1
- [x] Godot supports grid-based placement for floor, wall, ceiling/roof, and surface decor items. - Phase 1
- [x] Godot supports sample cats in-room as part of the local sandbox slice. - Phase 1
- [x] The local room-builder slice stays browser-first and avoids backend, Firebase, shared-room, or couple-join systems. - Phase 1

### Active

- [ ] Future room, cat, and presentation changes are defined manually per user request instead of continuing the old bulk Phase 2 plan.

### Out of Scope

- Firebase, authentication, shared-room sync, partner presence, or any couple-join flow - explicitly removed from the current target.
- Click-to-move player locomotion from the source runtime - the current direct movement system stays in place.
- Full feature parity with the source R3F game at this stage - the current milestone is still a focused local room-view slice.
- Bulk 1:1 feature porting from the source runtime - future work now proceeds one manual feature request at a time.
- Cat model and behavior overhauls - explicitly deferred until after camera and room presentation are improved.

## Context

- The source repo in `Z:\FAHHHH` contains many more systems than this repo currently needs, including Firebase-backed shared-room logic and couple features. Those systems are no longer part of the immediate target.
- The useful source references for the current milestone are the local room-builder systems: room shell, wall occlusion, placement, windows, surface decor anchoring, and sample pet/cat behavior.
- The current Godot repo already has a usable player controller, a Minecraft-style avatar rig, and runtime skin loading, which should be preserved.
- The next source systems that matter most from `Z:\FAHHHH` are `useRoomViewCamera.ts`, `sceneTargets.ts`, `WallOcclusionController.tsx`, `RoomShell.tsx`, `FloorStage.tsx`, `useRoomViewLighting.ts`, and `themeRegistry.ts`.
- The engine move is still motivated by browser performance and stability, but the scope is now deliberately narrowed to local gameplay and building systems first.

## Constraints

- **Platform**: Browser-first Godot delivery - the room-builder slice must stay viable for web export.
- **Scope**: Local-only milestone - no backend, no shared-room, no Firebase, no couple systems.
- **Controls**: Keep direct keyboard movement, but replace the current multi-camera prototype with a single room-view orbit camera - do not reintroduce click-to-move.
- **Architecture**: Reuse and extend the existing Godot prototype instead of restarting from zero.
- **Parity boundary**: Only port the local room-builder, shell, occlusion, and sample-cat systems that matter to this milestone.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remove Firebase/shared-room/couple scope from the current project target | The user explicitly does not want backend or two-player systems in this milestone | The active roadmap excludes backend, Firebase, shared-room, and couple systems. |
| Keep the current Godot movement model while removing click-to-move | The user explicitly does not want click-to-move ported over | Direct keyboard movement remains the locomotion baseline. |
| Phase 1 should implement the local room-builder foundation instead of only documenting a broader migration | The current need is concrete local gameplay/building capability, not platform-wide backend parity planning | Phase 1 is planned as a code-delivery phase for shell, occlusion, placement, and sample cats. |
| Use the source R3F repo only as a reference for local builder systems relevant to this slice | The source repo contains much more scope than the current Godot milestone should inherit | The source repo is treated as a targeted reference for room shell, placement, occlusion, and cat behavior only. |
| Phase 2 should replace the current camera stack with the `FAHHHH` room-view orbit camera | The current Godot camera shakes and the user wants the stable room-centered shot from the source game | The next phase is centered on a single orbit camera around the room target instead of freecam / first-person / third-person switching. |
| Cat polish is deferred until after camera and room fidelity | The current cat placeholders are acceptable only as temporary proof-of-life content | Phase 2 excludes cat redesign and focuses on camera plus room presentation. |
| Stop broad Phase 2 continuation after the camera baseline | The user wants future work requested manually one feature at a time instead of following the old bundled plan | Pending Phase 2 follow-up plans were removed and the repo now waits for direct feature requests. |

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
*Last updated: 2026-04-02 after narrowing Phase 2 to the completed camera baseline*
