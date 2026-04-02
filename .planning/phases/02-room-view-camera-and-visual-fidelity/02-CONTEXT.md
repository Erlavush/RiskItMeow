# Phase 2: Room-View Camera and Visual Fidelity - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning and execution
**Source:** User direction after Phase 1 completion plus targeted inspection of the `FAHHHH` room-view camera, shell, floor, and lighting systems

<domain>
## Phase Boundary

Phase 2 improves how the existing local room sandbox looks and feels.

It must deliver:

- a single stable room-view orbit camera aimed at the room center
- removal of the current freecam / first-person / third-person switching as the active room camera model
- compatibility between the new camera, build mode, occlusion, and direct keyboard movement
- a themed starter room presentation instead of the current plain white shell
- better floor, wall, ceiling, trim, and lighting readability while staying browser-friendly

Phase 2 must not include Firebase, backend sync, shared-room logic, couple features, click-to-move locomotion, or cat redesign work.

</domain>

<decisions>
## Implementation Decisions

### Locked Decisions

- The current Godot camera stack is no longer the long-term baseline because it shakes and fights readability.
- The new baseline camera should follow the `FAHHHH` room-view pattern: one orbit camera aimed at a fixed room target.
- Direct keyboard movement stays in scope; click-to-move stays out of scope.
- Cat visuals and richer cat behavior are explicitly deferred until after the camera and room shell feel better.
- The room should stop reading as a plain hollow white box during this phase.

### The Agent's Discretion

- Exact Godot file structure for the room camera controller and room theming system
- Whether shell detailing lands through one upgraded `RoomShell` scene or a split shell-plus-floor composition
- How much of the `FAHHHH` lighting stack is simplified as long as the room becomes materially more readable and browser-friendly

</decisions>

<canonical_refs>
## Canonical References

**Downstream execution must read these first.**

### Current Godot Repo
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `scenes/main.tscn`
- `scenes/room/room_shell.tscn`
- `scripts/player.gd`
- `scripts/build/build_mode_controller.gd`
- `scripts/room/room_shell.gd`
- `scripts/room/room_occlusion_controller.gd`

### Source Room-View References
- `Z:\FAHHHH\docs\CURRENT_SYSTEMS.md`
- `Z:\FAHHHH\docs\ARCHITECTURE.md`
- `Z:\FAHHHH\src\components\RoomView.tsx`
- `Z:\FAHHHH\src\components\room-view\useRoomViewCamera.ts`
- `Z:\FAHHHH\src\components\room-view\WallOcclusionController.tsx`
- `Z:\FAHHHH\src\components\room-view\RoomShell.tsx`
- `Z:\FAHHHH\src\components\room-view\FloorStage.tsx`
- `Z:\FAHHHH\src\components\room-view\useRoomViewLighting.ts`
- `Z:\FAHHHH\src\lib\sceneTargets.ts`
- `Z:\FAHHHH\src\lib\themeRegistry.ts`

</canonical_refs>

<specifics>
## Specific Ideas

- The room camera should point at the middle of the room instead of following the player body as a spring-arm camera.
- Camera shake matters more than camera feature count, so Phase 2 should prefer one reliable camera over multiple unstable modes.
- The room needs stronger visual identity: floor wood or staged flooring, non-white walls, ceiling detail, trim, and better light response.
- Existing build placement and occlusion should survive the new camera rather than being replaced.

</specifics>

<deferred>
## Deferred Ideas

- Cat model replacement, cat texture work, and richer pet animation
- Inventory, economy, or persistence expansion
- Shared-room or backend systems
- Click-to-move or interaction-pathing controls from the source runtime

</deferred>

---

*Phase: 02-room-view-camera-and-visual-fidelity*
*Context gathered: 2026-04-02 after Phase 1 completion*
