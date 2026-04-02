# Phase 1 Manual Verification

Verified on 2026-04-02 against the narrowed local-only Godot scope.

## Room Shell and Occlusion

- Confirmed `RoomShell` remains instanced in [scenes/main.tscn](Z:/RiskItMeow/risk-it-meow/scenes/main.tscn) alongside `RoomOcclusionController`.
- Confirmed the room still exposes a floor, four walls, and a ceiling through [scripts/room/room_shell.gd](Z:/RiskItMeow/risk-it-meow/scripts/room/room_shell.gd).
- Confirmed occlusion still depends on the active camera relation to the room in [scripts/room/room_occlusion_controller.gd](Z:/RiskItMeow/risk-it-meow/scripts/room/room_occlusion_controller.gd).
- Headless load check passed on 2026-04-02 with:

```powershell
& 'Z:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe' --headless --path 'Z:\RiskItMeow\risk-it-meow' --quit
```

- Interactive camera peel behavior still needs an in-editor or runtime human smoke check because the terminal cannot drive the 3D camera interactively.

## Placement Families

- Confirmed floor, wall, ceiling, and surface families exist in [scripts/build/placement_types.gd](Z:/RiskItMeow/risk-it-meow/scripts/build/placement_types.gd).
- Confirmed the sample build catalog includes one local item for each family in [scripts/build/build_item_registry.gd](Z:/RiskItMeow/risk-it-meow/scripts/build/build_item_registry.gd).
- Confirmed [scripts/build/placement_resolver.gd](Z:/RiskItMeow/risk-it-meow/scripts/build/placement_resolver.gd) resolves floor, wall, ceiling, and anchored surface placements and rejects invalid overlap.
- Confirmed [scripts/build/build_mode_controller.gd](Z:/RiskItMeow/risk-it-meow/scripts/build/build_mode_controller.gd) preserves current movement/camera baseline while handling `B`, `R`, `1-4`, left click, right click, and `Esc`.
- Interactive placement smoke coverage is still pending for:
  floor placement feel
  wall target precision from each side
  ceiling targeting feel
  surface decor anchoring while the room is already decorated

## Sample Cats

- Confirmed [scenes/cats/sample_cat.tscn](Z:/RiskItMeow/risk-it-meow/scenes/cats/sample_cat.tscn) exists and instantiates a readable prototype cat actor.
- Confirmed [scripts/cats/sample_cat.gd](Z:/RiskItMeow/risk-it-meow/scripts/cats/sample_cat.gd) provides idle plus wander states, facing updates, and lightweight visual motion.
- Confirmed [scripts/cats/sample_cat_manager.gd](Z:/RiskItMeow/risk-it-meow/scripts/cats/sample_cat_manager.gd) is integrated into [scenes/main.tscn](Z:/RiskItMeow/risk-it-meow/scenes/main.tscn) and spawns sample cats inside room-safe floor space.
- Confirmed the cat manager reuses build-mode floor obstacles so cats avoid placed floor furniture when spawning or choosing new wander targets.
- Visual confirmation of final cat pacing and spacing still requires a live runtime smoke check.

## Direct Movement Regression Check

- Confirmed [scripts/player.gd](Z:/RiskItMeow/risk-it-meow/scripts/player.gd) still owns direct keyboard and mouse movement plus the existing camera modes.
- Confirmed no click-to-move logic was added anywhere in the Godot project during Phase 1.
- Confirmed build mode plugs into the player through `set_build_mode_controller` instead of replacing player locomotion.
- Interactive direct-movement regression testing is still pending for a human pass in the running project.

## Scope Audit

- Firebase was not added.
- Shared-room sync was not added.
- Couple joining or partner presence flows were not added.
- Backend-dependent room state was not added.
- Click-to-move was not added.
- Placement, room shell, occlusion, and sample cats remain local-only Godot systems.

## Browser Viability Notes

- The current phase remains browser-oriented in architecture because it stays local-only and uses lightweight procedural meshes for build items and cats.
- A browser export smoke check could not be completed because the repo still has no export presets or browser build pipeline configured.
- The successful headless project load is the strongest automated viability check completed in this terminal session.
- Remaining browser risk is mostly around future export setup rather than backend scope, because this phase deliberately avoided Firebase and multiplayer systems.
