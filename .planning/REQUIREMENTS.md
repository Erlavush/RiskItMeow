# Requirements: Risk It Meow

**Defined:** 2026-04-02
**Core Value:** Keep the Godot prototype easy to evolve by adding one requested feature at a time on top of a small, working baseline.

## Active Baseline Requirements

- [x] **CTRL-01**: The player moves with the existing direct keyboard and mouse controller.
- [x] **CAM-01**: The game uses one stable room-view orbit camera.
- [x] **WORLD-01**: The main scene contains a visible floor platform.
- [x] **WORLD-02**: The player stands upright on the floor without rotation drift or floating.
- [x] **WORLD-03**: The build floor is an exact 10x10 checkered grid surface with 1x1 cells.
- [x] **BUILD-01**: The active main scene includes a left-side inventory with `Simple Wood Chair` stock and placement entry.
- [x] **BUILD-02**: Chair placement previews snap to the floor grid and validate against room bounds and other placed chairs.
- [x] **BUILD-03**: Placement previews show clear valid/invalid visual states, a runtime gizmo, and confirm/cancel controls.
- [x] **SCENE-01**: The active main scene excludes cats, walls, and roof geometry from the live scene.
- [x] **FLOW-01**: New work is introduced only through explicit user-requested feature changes.
- [x] **SCOPE-01**: The repo no longer carries an active source-porting commitment.
- [x] **SCOPE-02**: The current baseline contains no Firebase, shared-room, couple, or backend-dependent systems.

## Deferred Until Requested

- Wall and roof restoration
- Cats and pet behavior
- Room detailing, materials, and presentation upgrades
- Save/load layouts, placed-item editing, persistence, shop, or other progression systems

## Out of Scope

| Feature | Reason |
|---------|--------|
| Broad source-project feature parity | The project is no longer following a source-port roadmap |
| Firebase, auth, backend sync | Explicitly removed from the current direction |
| Shared-room or couple gameplay | Explicitly removed from the current direction |
| Click-to-move locomotion | Rejected in favor of the current direct movement controller |

## Traceability

| Requirement | Status | Notes |
|-------------|--------|-------|
| CTRL-01 | Complete | Existing player controller remains active |
| CAM-01 | Complete | Room-view orbit camera is the only active camera |
| WORLD-01 | Complete | Floor is visible in editor and runtime |
| WORLD-02 | Complete | Player pose and floor snap were corrected |
| WORLD-03 | Complete | Floor is currently 10x10 with exact 1x1 checker cells |
| BUILD-01 | Complete | Inventory and `Simple Wood Chair` stock are active in the runtime scene |
| BUILD-02 | Complete | Placement snaps to the floor grid and blocks overlaps/out-of-bounds placement |
| BUILD-03 | Complete | Preview colors, gizmo controls, and confirm/cancel popup are active |
| SCENE-01 | Complete | Main scene is floor-only; walls and roof remain hidden |
| FLOW-01 | Complete | Future work is manual and one request at a time |
| SCOPE-01 | Complete | Broad source-porting is no longer an active planning target |
| SCOPE-02 | Complete | No backend or shared-room systems are active |

---
*Last updated: 2026-04-02 after the placement prototype and build polish pass*
