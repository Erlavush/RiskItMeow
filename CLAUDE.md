# Project

**Risk It Meow**

Risk It Meow is currently a manual-feature Godot prototype. The active scene now includes one player, a 10x10 checkered floor platform, a room-view orbit camera, and a runtime chair placement prototype. Future work is still added manually, one feature request at a time.

**Core Value:** Keep the project easy to extend by preserving a clean baseline and only adding explicitly requested features.

## Current Baseline

- Main runtime scene: [main.tscn](/Z:/RiskItMeow/risk-it-meow/scenes/main.tscn)
- Floor-only room shell: [room_shell.tscn](/Z:/RiskItMeow/risk-it-meow/scenes/room/room_shell.tscn)
- Orbit camera controller: [room_view_camera_controller.gd](/Z:/RiskItMeow/risk-it-meow/scripts/camera/room_view_camera_controller.gd)
- Player controller: [player.gd](/Z:/RiskItMeow/risk-it-meow/scripts/player.gd)
- Placement manager: [placement_manager.gd](/Z:/RiskItMeow/risk-it-meow/scripts/placement/placement_manager.gd)
- Chair placement actor: [simple_wood_chair.gd](/Z:/RiskItMeow/risk-it-meow/scripts/placement/simple_wood_chair.gd)

## Working Rules

- This repo is not following a source-porting roadmap anymore.
- Add one feature at a time from the current Godot baseline.
- Keep direct player movement unless the user explicitly asks to replace it.
- Keep the current room-view camera unless the user explicitly asks to change it.
- Keep the current runtime placement/inventory prototype unless the user explicitly asks to replace or remove it.
- Do not add cats, backend sync, multiplayer, or other unrelated legacy scope by default.
- Do not add backend, Firebase, shared-room, couple, or multiplayer systems unless the user explicitly asks for them.

## Useful Notes

- The floor is set up to render in the editor without needing `F5` and is currently sized to an exact 10x10 grid.
- The player tilt, floating, and border-clamp issues were already corrected.
- The current room shell is still used as a floor-only stage; walls and ceiling stay hidden in the main scene.
- Placement currently supports a `Simple Wood Chair`, dotted grid overlay, stock UI, preview validity colors, runtime gizmo drag, and confirm/cancel popup.
- Local Godot executable paths are documented in [LOCAL_TOOLING.md](/Z:/RiskItMeow/risk-it-meow/LOCAL_TOOLING.md) and should be treated as the default project executables for editor and console runs.

## Workflow

- For this repo, direct small edits are normal because the user is driving feature work manually.
- If structured planning is needed again later, create a new phase from the current baseline instead of reviving old porting plans.
