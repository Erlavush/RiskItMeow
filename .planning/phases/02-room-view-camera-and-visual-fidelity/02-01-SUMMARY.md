---
phase: 02-room-view-camera-and-visual-fidelity
plan: 01
subsystem: camera
tags: [godot, camera, orbit, room-view, occlusion]
requires: []
provides:
  - stable room-view orbit camera aimed at the room center
  - player movement aligned to the shared room camera instead of the player spring arm
  - reset-camera UI flow for the single live room view
affects: [02-02, 02-03, build-mode, occlusion]
tech-stack:
  added: []
  patterns:
    - world-owned camera controller that exposes one active room camera to downstream systems
    - player movement that reads the active room camera basis without reviving click-to-move
key-files:
  created:
    - scripts/camera/room_view_camera_controller.gd
  modified:
    - scenes/main.tscn
    - scripts/player.gd
    - scripts/build/build_mode_controller.gd
    - scripts/room/room_occlusion_controller.gd
    - scripts/skin_picker.gd
key-decisions:
  - "Moved the live room camera out of the player scene so the room can orbit around a fixed center target without spring-arm shake."
  - "Kept build preview and occlusion on the existing get_active_camera hook so downstream systems can swap camera ownership without changing their runtime contract."
patterns-established:
  - "Room-scale camera ownership now lives in a dedicated controller under the world scene, not inside the player rig."
  - "The single active room camera exposes reset behavior through UI instead of mode cycling."
requirements-completed: [CTRL-01, CAM-01, CAM-02, PERF-01, SCOPE-01]
duration: 1 min
completed: 2026-04-02
---

# Phase 2 Plan 01: Room Camera Baseline Summary

**Room-view orbit framing now uses a single world camera aimed at the room center, with player movement, build preview, and occlusion all reading from that shared view**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-02T19:19:32+08:00
- **Completed:** 2026-04-02T19:20:05+08:00
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added a dedicated `RoomViewCameraController` that reproduces the `FAHHHH` room-view baseline with a fixed center target, wheel zoom, reset behavior, and one explicit `Camera3D`.
- Rewired player movement, build preview targeting, and wall/ceiling occlusion to use the shared room camera instead of the old player-owned multi-mode stack.
- Replaced the live UI camera mode cycle with a single reset-camera action so the runtime now presents one clear room-view model.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the room-view orbit camera controller** - `4eed640` (`feat`)
2. **Task 2: Rewire player, build mode, and occlusion around the new camera baseline** - `08b35de` (`feat`)
3. **Task 3: Remove legacy room-camera switching from the active UI flow** - `21155ea` (`feat`)

## Files Created/Modified

- `scripts/camera/room_view_camera_controller.gd` - dedicated room-center orbit camera with smooth zoom and reset support
- `scenes/main.tscn` - live world integration for the room camera controller and active camera ownership
- `scripts/player.gd` - movement-only player flow that now reads orientation from the room camera
- `scripts/build/build_mode_controller.gd` - preview targeting through the active shared room camera
- `scripts/room/room_occlusion_controller.gd` - occlusion visibility updates sourced from the new active room camera hook
- `scripts/skin_picker.gd` - toolbar copy and reset-camera button for the single room-view camera

## Decisions Made

- Kept the camera target fixed near `ROOM_CAMERA_TARGET` parity (`0, 0.9, 0`) so the Godot room and the R3F reference frame the same center point.
- Left the old player camera nodes in the player scene as inactive fallback nodes for now, but removed them from the live runtime path so Phase 2 can keep moving without a player-scene resave.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Relaxed the player-side camera controller annotation**
- **Found during:** Verification after Task 3
- **Issue:** Godot headless parsing failed because `player.gd` could not resolve the new `RoomViewCameraController` type annotation in the current project parse order.
- **Fix:** Switched the player hook to a dynamic `Node` reference while keeping the same `get_camera` and `reset_camera` runtime contract.
- **Files modified:** `scripts/player.gd`
- **Verification:** `Z:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe --headless --path . --quit`
- **Committed in:** `e8baf2a`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was narrow and preserved the planned camera architecture while clearing a real runtime parser failure.

## Issues Encountered

None - once the user provided the local Godot 4.6.1 executable path, the headless scene load passed cleanly.

## User Setup Required

None - the new room camera is local-only and does not introduce external services or manual setup.

## Next Phase Readiness

- The main scene now has one stable room camera baseline, which clears the biggest blocker for themed shell work in `02-02`.
- Build preview and occlusion are already following the shared room camera, so later shell and lighting changes can iterate on readability without another camera rewrite.

---
*Phase: 02-room-view-camera-and-visual-fidelity*
*Completed: 2026-04-02*
