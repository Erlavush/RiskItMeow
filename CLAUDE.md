# Project

**Risk It Meow**

Risk It Meow is currently a manual-feature Godot prototype. The active scene now includes one player, an 8x8 room shell with four walls and a roof, a room-view orbit camera, a runtime furniture placement prototype, a camera-driven wall cutaway system, and a developer environment tuning panel. Future work is still added manually, one feature request at a time.

**Core Value:** Keep the project easy to extend by preserving a clean baseline and only adding explicitly requested features.

## Current Baseline

- Main runtime scene: [main.tscn](/Z:/RiskItMeow/risk-it-meow/scenes/main.tscn)
- Active room shell: [room_shell.tscn](/Z:/RiskItMeow/risk-it-meow/scenes/room/room_shell.tscn)
- Orbit camera controller: [room_view_camera_controller.gd](/Z:/RiskItMeow/risk-it-meow/scripts/camera/room_view_camera_controller.gd)
- Player controller: [player.gd](/Z:/RiskItMeow/risk-it-meow/scripts/player.gd)
- Placement manager: [placement_manager.gd](/Z:/RiskItMeow/risk-it-meow/scripts/placement/placement_manager.gd)
- Base placeable actor: [simple_wood_chair.gd](/Z:/RiskItMeow/risk-it-meow/scripts/placement/simple_wood_chair.gd)
- Developer environment panel: [developer_environment_panel.gd](/Z:/RiskItMeow/risk-it-meow/scripts/debug/developer_environment_panel.gd)
- Camera cutaway controller: [room_cutaway_controller.gd](/Z:/RiskItMeow/risk-it-meow/scripts/room/room_cutaway_controller.gd)

## Working Rules

- This repo is not following a source-porting roadmap anymore.
- Add one feature at a time from the current Godot baseline.
- Keep direct player movement unless the user explicitly asks to replace it.
- Keep the current room-view camera unless the user explicitly asks to change it.
- Keep the current runtime placement/inventory prototype unless the user explicitly asks to replace or remove it.
- Do not add cats, backend sync, multiplayer, or other unrelated legacy scope by default.
- Do not add backend, Firebase, shared-room, couple, or multiplayer systems unless the user explicitly asks for them.

## Useful Notes

- The live room is currently `8x8`, with `0.25` floor thickness, `0.25` wall thickness, four walls, and a roof.
- The player tilt, floating, and border-clamp issues were already corrected.
- The active floor uses a dark-brown linen texture that is downscaled to `32x32`, repeated once per floor block, and randomly rotated per tile.
- Placement currently supports `Simple Wood Chair`, `Office Chair`, `Office Desk + Computer`, and `Fridge` inventory entries, dotted grid overlay, floor-finish switching, preview validity colors, runtime gizmo drag, and confirm/cancel popup.
- The placement UI now has `Build` and `Edit` modes. `Edit` forces the grid on, disables inventory placement, and lets the user double-click placed furniture to move it.
- While editing a placed item, the popup now supports `Move`, `Duplicate`, `Delete`, and `Cancel`. Duplicate still uses remaining stock and Delete refunds one stock.
- Room layouts now persist locally in `user://room_layout.json`, including placed items and floor finish.
- The editor 3D preview now mirrors the locally saved room layout by reading `user://room_layout.json` through tool-mode preview logic.
- The left placement panel now includes `Save`, `Load`, and `Clear Room`, and the layout autosaves after place, move, delete, clear, and floor-finish changes.
- The inventory now includes a wall-mounted `Window` item imported from `assets/props/window/window.glb`.
- Window placement snaps to walls instead of the floor, and placed windows rebuild the wall into segmented geometry so the wall opening fits the window.
- Windows now use a lightweight sunlight workaround: they do not cast solid shadows themselves, and sun-facing windows inject warm interior portal light plus a soft room bounce light.
- The room now uses a Sims-style first-pass cutaway controller: the camera-facing walls and roof switch to render-only cutaway mode while preserving collisions and shadows.
- The developer panel can tune lighting, fog, glow, and post-adjustment live, persists locally in `user://`, and now also reapplies that saved preset in the editor preview.
- The developer panel now also includes persistent `Morning`, `Noon`, and `Sunset` sun presets that adjust sun direction and overall light mood.
- Local Godot executable paths are documented in [LOCAL_TOOLING.md](/Z:/RiskItMeow/risk-it-meow/LOCAL_TOOLING.md) and should be treated as the default project executables for editor and console runs.

## Workflow

- For this repo, direct small edits are normal because the user is driving feature work manually.
- If structured planning is needed again later, create a new phase from the current baseline instead of reviving old porting plans.
