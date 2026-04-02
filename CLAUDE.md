# Project

**Risk It Meow**

Risk It Meow is currently a fresh Godot prototype baseline. The active scene is intentionally minimal: one player, one visible floor platform, and one room-view orbit camera. Future work is added manually, one feature request at a time.

**Core Value:** Keep the project easy to extend by preserving a clean baseline and only adding explicitly requested features.

## Current Baseline

- Main runtime scene: [main.tscn](/Z:/RiskItMeow/risk-it-meow/scenes/main.tscn)
- Floor-only room shell: [room_shell.tscn](/Z:/RiskItMeow/risk-it-meow/scenes/room/room_shell.tscn)
- Orbit camera controller: [room_view_camera_controller.gd](/Z:/RiskItMeow/risk-it-meow/scripts/camera/room_view_camera_controller.gd)
- Player controller: [player.gd](/Z:/RiskItMeow/risk-it-meow/scripts/player.gd)

## Working Rules

- This repo is not following a source-porting roadmap anymore.
- Add one feature at a time from the current Godot baseline.
- Keep direct player movement unless the user explicitly asks to replace it.
- Keep the current room-view camera unless the user explicitly asks to change it.
- Do not reintroduce cats, build mode, placement systems, walls, or roof by default.
- Do not add backend, Firebase, shared-room, couple, or multiplayer systems unless the user explicitly asks for them.

## Useful Notes

- The floor is set up to render in the editor without needing `F5`.
- The player tilt and floating issues were already corrected.
- The current room shell is being used as a floor-only stage; walls and ceiling stay hidden in the main scene.

## Workflow

- For this repo, direct small edits are normal because the user is driving feature work manually.
- If structured planning is needed again later, create a new phase from the current baseline instead of reviving old porting plans.
