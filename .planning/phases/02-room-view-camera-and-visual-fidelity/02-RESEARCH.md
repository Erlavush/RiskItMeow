# Phase 2 Research: Room-View Camera and Visual Fidelity

## Objective

Answer: "What do we need to copy or adapt from `FAHHHH` to fix the current camera and upgrade the room presentation without widening scope?"

## Camera Findings From `FAHHHH`

The source game no longer uses a player-bound spring-arm camera for the room view.

Relevant facts from `Z:\FAHHHH\src\components\RoomView.tsx` and `Z:\FAHHHH\src\components\room-view\useRoomViewCamera.ts`:

- one `PerspectiveCamera` is created for the room scene
- `OrbitControls` targets a fixed room center
- pan is disabled
- rotate is enabled
- zoom is handled through a smooth wheel-distance target instead of raw camera jumps
- polar angle and distance are clamped for room readability
- camera reset returns to one canonical default shot

The room camera target lives in `Z:\FAHHHH\src\lib\sceneTargets.ts` as `ROOM_CAMERA_TARGET = [0, 0.9, 0]`.

Implication for Godot:

- Phase 2 should create one room camera controller around a fixed room target
- build mode and occlusion should read from that controller's camera
- player locomotion must stop assuming that the active camera is always parented to the player

## Occlusion Findings

`Z:\FAHHHH\src\components\room-view\WallOcclusionController.tsx` still hides front, side, and ceiling surfaces from camera angle and vertical ratio, but it does so relative to the fixed room target instead of a player-follow camera rig.

Implication for Godot:

- the current occlusion math is directionally compatible, but it should be retuned around the new orbit camera target
- the room shell still needs independently hideable surfaces

## Room Shell Findings

`Z:\FAHHHH\src\components\room-view\RoomShell.tsx` is not just a white box. It layers:

- themed wall colors
- baseboards
- wall trim
- wall rails
- corner trim
- ceiling trim
- segmented wall bands that can support openings

The source shell also derives its colors from `Z:\FAHHHH\src\lib\themeRegistry.ts`, where the default `starter-cozy` theme uses warm wall, trim, ceiling, and wood-floor colors instead of pure white.

Implication for Godot:

- Phase 2 should introduce a theme/palette source of truth instead of hardcoding flat white materials
- the Godot shell should expose separate trim and floor detail meshes, not only six plain box surfaces
- future window/opening work becomes easier if shell surfaces are segmented now instead of later

## Floor Findings

`Z:\FAHHHH\src\components\room-view\FloorStage.tsx` gives the room a stronger base through:

- a stage/platform under the room
- a styled wood floor
- edge and lip pieces around the floor perimeter

Implication for Godot:

- floor presentation should become a deliberate stage rather than a plain white slab
- build placement still needs a stable canonical floor plane even if the visuals gain extra detail

## Lighting Findings

`Z:\FAHHHH\src\components\room-view\useRoomViewLighting.ts` does more than toggle a sun:

- backdrop gradient shifts with time-of-day logic
- fog color follows the sky blend
- room surfaces receive derived light amounts
- practical lighting, bloom, AO, and exposure are throttled for performance risk

Implication for Godot:

- Phase 2 does not need full world-clock parity, but it does need warmer ambient/environment choices and better material readability
- browser-friendly polish is more important than chasing every post-processing feature from the source

## Main Risks

- Replacing the camera affects player movement, build targeting, occlusion, and UI hints at the same time.
- The current `skin_picker.gd` camera actions assume multiple camera modes and will become misleading if not simplified.
- Upgrading the shell visually without a small theme system will likely create another pile of hardcoded colors.
- If shell visuals and build colliders diverge too far, placement math can become fragile.

## Recommended Phase Outputs

Phase 2 should leave behind:

- one stable room-view orbit camera controller
- a room-center camera target contract shared by build mode and occlusion
- a starter room theme/palette source of truth
- a shell that reads as a room, not a white prototype box
- manual verification evidence that the new camera and upgraded room still preserve local-only scope and direct movement

## Verification Focus

Phase verification should check:

- the old camera switching path is gone or intentionally disabled
- the orbit camera is stable and centered on the room
- build mode preview and placement still work under the new camera
- the room shell is visibly themed and no longer flat white
- no Firebase, shared-room, or click-to-move scope leaked back in

---

*Phase: 02-room-view-camera-and-visual-fidelity*
*Research completed: 2026-04-02*
