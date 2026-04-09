# Architecture

## Pattern Overview
- The project is a scene-centric Godot application with behavior attached directly to nodes rather than a service layer or ECS.
- `project.godot` boots `scenes/main.tscn`, and that scene wires the active runtime graph together in one place.
- Most runtime complexity is concentrated in a few large controller scripts: `scripts/placement/placement_manager.gd`, `scripts/debug/debug_world_controller.gd`, `scripts/debug/developer_environment_panel.gd`, `scripts/player.gd`, and `scripts/room/room_shell.gd`.
- Shared data is mostly passed through node references, exported `NodePath`s, signals, and static helper classes.

## Main World Composition
- `scenes/main.tscn` creates the environment, directional light, room shell, orbit camera controller, placement manager, cutaway controller, sunlight controller, debug world controller, developer panel, and player instance.
- `scenes/player.tscn` packages the `CharacterBody3D`, Minecraft rig, third-person camera rig, and first-person camera.
- `scenes/room/room_shell.tscn` provides the shell node hierarchy for the floor, four walls, and ceiling, while `scripts/room/room_shell.gd` procedurally resizes and reconfigures them at runtime.

## Runtime Layers
- Player layer: `scripts/player.gd`, `scripts/MinecraftRig.gd`, `scripts/skin_picker.gd`, and `scripts/minecraft_rig/*.gd`.
- Room layer: `scripts/room/room_shell.gd`, `scripts/room/room_wall_segments.gd`, `scripts/room/room_floor_materials.gd`, `scripts/room/room_cutaway_controller.gd`, and `scripts/room/room_sunlight_controller.gd`.
- Placement layer: `scripts/placement/placement_manager.gd` plus catalog, validation, surface-query, preview, save-store, and UI helper scripts.
- Debug/tuning layer: `scripts/debug/developer_environment_panel.gd`, `scripts/debug/developer_environment_state.gd`, and `scripts/debug/debug_world_controller.gd`.
- Tooling layer: `scripts/tools/generate_item_previews.gd`, `scripts/dump_codebase.gd`, `scripts/WorldGenerator.gd`, and `generate_scene.py`.

## Data Flow
- Startup begins in `project.godot`, which loads `scenes/main.tscn`.
- `PlacementManager` builds the curated item catalog through `PlacementInventoryCatalog.build_item_defs()`, loads local room state, and owns the build/edit browser UI.
- When the user starts placement, `PlacementManager` creates a `SimpleWoodChair`-compatible placeable, updates the preview from camera raycasts, validates it through `PlacementValidator`, and commits it into `PlacedItems`.
- Saved room layout data flows through `PlacementRoomLayoutStore`, which serializes world-anchored and support-surface-attached props into `user://room_layout.json`.
- `RoomCutawayController` and `RoomSunlightController` react to camera position and placed windows to keep the room readable and lit.
- `DebugWorldController` reuses the same placement catalog and imported-item pipeline to preview one item at a time and write per-item override data back into `user://placement_item_profile_overrides.cfg`.
- `DeveloperEnvironmentPanel` captures, applies, and persists environment/light settings, then notifies `RoomSunlightController` so interior portal lighting can resync.

## Key Abstractions
- `RoomShell` is the geometry authority for room extents, wall positions, floor/ceiling heights, wall openings, and cutaway state.
- `SimpleWoodChair` is the base placeable actor contract for collision, visuals, preview rendering, mounting rules, and support surfaces.
- `ImportedScenePlaceable` extends that base contract to support imported `.gltf` / `.glb` assets, auto-fit metrics, and per-item overrides.
- `PlacementInventoryCatalog` is the single source of truth for the live curated catalog.
- `PlacementManager` is both the runtime placement state machine and the browser UI owner.
- `DebugWorldController` is effectively a separate in-game Item Studio that shares the placement catalog rather than a standalone editor plugin.

## Editor And Runtime Split
- Many scripts are marked `@tool`, so the same file can run in the editor and at runtime.
- `RoomShell`, `PlacementManager`, `ImportedScenePlaceable`, `DeveloperEnvironmentPanel`, `RoomSunlightController`, `MinecraftRig`, and `PlacementBrowserCard` all have editor-aware behavior.
- This gives fast iteration inside the editor but increases the risk of editor-side side effects and mixed responsibilities inside a single file.

## Entry Points
- Engine entry point: `project.godot`.
- Runtime scene entry point: `scenes/main.tscn`.
- Main gameplay callbacks: `_ready()`, `_physics_process()`, `_process()`, `_input()`, and `_unhandled_input()` across `scripts/player.gd`, `scripts/placement/placement_manager.gd`, and `scripts/debug/debug_world_controller.gd`.
- Tooling entry points: `_run()` in `scripts/tools/generate_item_previews.gd`, `_run()` in `scripts/dump_codebase.gd`, the exported setter in `scripts/WorldGenerator.gd`, and the direct file write in `generate_scene.py`.
