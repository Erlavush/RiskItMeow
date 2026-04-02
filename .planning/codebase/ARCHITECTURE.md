# Architecture

## Pattern Overview
- The project follows a scene-centric Godot architecture where `project.godot` boots `scenes/main.tscn`, and that world scene instances `scenes/player.tscn`.
- Behavior is attached to nodes through per-scene scripts rather than a service layer or ECS.
- Most game logic is concentrated in three runtime scripts: `scripts/player.gd`, `scripts/MinecraftRig.gd`, and `scripts/skin_picker.gd`.
- Tooling concerns are separated into editor/helper scripts such as `scripts/WorldGenerator.gd`, `scripts/dump_codebase.gd`, and `generate_scene.py`.

## Layers
- Configuration layer: `project.godot`, `.gitignore`, `.gitattributes`, and `.vscode/settings.json`.
- World composition layer: `scenes/main.tscn` defines the world root, environment, lighting, ground, and instanced player.
- Player controller layer: `scripts/player.gd` handles input, camera mode switching, movement, and UI spawning.
- Character presentation layer: `scripts/MinecraftRig.gd` procedurally builds and animates a Minecraft-style character rig.
- UI layer: `scripts/skin_picker.gd` creates a small in-game toolbar for skin, model, and camera actions.
- Tooling/export layer: `scripts/WorldGenerator.gd`, `scripts/dump_codebase.gd`, and `generate_scene.py`.

## Data Flow
- Startup begins in `project.godot`, which loads `scenes/main.tscn`.
- `scenes/main.tscn` instances `scenes/player.tscn`, giving the world a single playable character.
- `scripts/player.gd::_ready()` captures the mouse, initializes camera state, excludes the player from spring-arm collision, and spawns the `SkinPicker` UI.
- Player input is polled every physics frame in `scripts/player.gd`, then translated into movement and camera behavior.
- `scripts/MinecraftRig.gd::_process()` reads the parent node's `velocity` property to derive walk and idle animation.
- `scripts/skin_picker.gd` drives two-way interactions by calling player methods such as `cycle_camera_mode()` and rig methods such as `load_skin_from_file()`.

## Key Abstractions
- `CharacterBody3D` in `scenes/player.tscn` is the player movement root, scripted by `scripts/player.gd`.
- `MinecraftRig` is a reusable rig builder declared with `class_name MinecraftRig` in `scripts/MinecraftRig.gd`.
- `SkinPicker` is a reusable UI layer declared with `class_name SkinPicker` in `scripts/skin_picker.gd`.
- `WorldGenerator` is an editor utility node that can populate block ground with `CSGBox3D` children.
- `dump_codebase.gd` is an `EditorScript` that exports a compressed textual representation of the project for AI tooling.

## Entry Points
- Engine entry point: `project.godot`.
- Main world scene: `scenes/main.tscn`.
- Player runtime entry points: `_ready()`, `_physics_process()`, `_unhandled_input()`, and `set_camera_mode()` in `scripts/player.gd`.
- Rig runtime entry points: `_ready()`, `_rebuild()`, and `_process()` in `scripts/MinecraftRig.gd`.
- UI entry points: `_ready()` and button/file-dialog callbacks in `scripts/skin_picker.gd`.
- Editor entry points: exported setters in `scripts/WorldGenerator.gd` and `_run()` in `scripts/dump_codebase.gd`.

## Error Handling
- Error handling is defensive and local rather than centralized.
- Scripts use guard clauses heavily, for example null checks in `scripts/skin_picker.gd` and `_pose_ready` checks in `scripts/MinecraftRig.gd`.
- Asset load failures fall back to warnings plus a generated placeholder skin in `scripts/MinecraftRig.gd`.
- There is no shared error bus, exception wrapper, or retry framework.

## Cross-Cutting Concerns
- The target platform influences architecture: `ROADMAP.md` and `project.godot` optimize toward browser-friendly rendering with `gl_compatibility`.
- Input handling is cross-cutting but currently hardcoded to desktop keys in `scripts/player.gd`.
- Editor and runtime logic coexist in `scripts/`, so `@tool` boundaries matter when touching shared files.
- The repo contains both source-of-truth runtime files and generated artifacts such as `compiled_codebase.txt` and `.godot/` cache data.