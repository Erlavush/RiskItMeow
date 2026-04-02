# Phase 1: Local Room Shell, Placement, and Sample Cats - Context

**Gathered:** 2026-04-02
**Status:** Ready for execution
**Source:** User scope correction plus local inspection of the Godot repo and relevant local-builder systems in `Z:\FAHHHH`

<domain>
## Phase Boundary

Phase 1 builds the first real local-only room-builder slice in Godot. It must deliver:

- a usable enclosed room shell
- wall/roof occlusion for interior visibility
- grid-based placement across floor, wall, ceiling/roof, and anchored surface decor
- sample cats in-room
- the current direct movement/camera system as the control baseline

Phase 1 must not include Firebase, backend sync, shared-room logic, partner presence, couple joining, or click-to-move locomotion.

</domain>

<decisions>
## Implementation Decisions

### Locked Decisions

- Backend, Firebase, shared-room, and couple systems are out of scope for this phase.
- Click-to-move is out of scope for this phase.
- The current Godot player controller and camera modes remain the baseline player control model.
- The source repo in `Z:\FAHHHH` is only a reference for local room shell, occlusion, placement, decor anchoring, and cat behavior systems relevant to this slice.
- Phase 1 should result in a usable local sandbox foundation, not a planning-only artifact set.

### The Agent's Discretion

- Exact Godot file/module structure for the shell, placement, and cat systems
- Whether some source behaviors are simplified as long as the local room-builder goal is satisfied and no out-of-scope systems creep back in
- The specific sample-cat representation, as long as cats are visibly present and readable in the room

</decisions>

<canonical_refs>
## Canonical References

**Downstream execution must read these first.**

### Current Godot Repo
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/codebase/ARCHITECTURE.md`
- `.planning/codebase/STRUCTURE.md`
- `.planning/codebase/CONCERNS.md`
- `scenes/main.tscn`
- `scenes/player.tscn`
- `scripts/player.gd`

### Source Local-Builder References
- `Z:\FAHHHH\docs\CURRENT_SYSTEMS.md`
- `Z:\FAHHHH\docs\ARCHITECTURE.md`
- `Z:\FAHHHH\src\components\RoomView.tsx`
- `Z:\FAHHHH\src\components\room-view\RoomShell.tsx`
- `Z:\FAHHHH\src\components\room-view\WallOcclusionController.tsx`
- `Z:\FAHHHH\src\components\room-view\useRoomFurnitureEditor.ts`
- `Z:\FAHHHH\src\components\room-view\useRoomViewBuilderGestures.ts`
- `Z:\FAHHHH\src\components\room-view\useRoomViewSpawn.ts`
- `Z:\FAHHHH\src\components\room-view\placementResolvers.ts`
- `Z:\FAHHHH\src\lib\surfaceDecor.ts`
- `Z:\FAHHHH\src\lib\furnitureCollision.ts`
- `Z:\FAHHHH\src\lib\wallOpenings.ts`
- `Z:\FAHHHH\src\lib\pets.ts`
- `Z:\FAHHHH\src\lib\petPathing.ts`
- `Z:\FAHHHH\tests\roomViewPlacementResolvers.test.ts`
- `Z:\FAHHHH\tests\surfaceDecor.test.ts`
- `Z:\FAHHHH\tests\wallOpenings.test.ts`
- `Z:\FAHHHH\tests\furnitureCollision.test.ts`
- `Z:\FAHHHH\tests\petPathing.test.ts`

</canonical_refs>

<specifics>
## Specific Ideas

- The first slice should feel like a room you can already walk inside and decorate, even before inventory/backend systems exist.
- Placement must cover floor, wall, ceiling/roof, and surface-decor categories instead of only one placement family.
- Occlusion matters because the room should stay readable from the current camera system.
- Sample cats should make the room feel alive immediately, even if cat systems stay lightweight in this phase.

</specifics>

<deferred>
## Deferred Ideas

- Backend/Firebase/shared-room/couple systems
- Click-to-move or interaction-pathing systems from the source runtime
- Full economy, inventory/shop, and memory systems unless needed only as stubs for placement/content testing

</deferred>

---

*Phase: 01-local-room-shell-placement-and-sample-cats*
*Context gathered: 2026-04-02 after scope correction*
