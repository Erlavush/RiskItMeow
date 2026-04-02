<!-- GSD:project-start source:PROJECT.md -->
## Project

**Risk It Meow**

Risk It Meow is a browser-first Godot game focused on a local cozy room sandbox with Minecraft-style presentation, room decoration, and sample cats. The immediate goal is not to port the full shared-room/Firebase/couple stack from `Z:\FAHHHH`; it is to port the local room-builder slice first: walls, roof, occlusion, grid placement, and floor/wall/ceiling/surface decor systems, while keeping the current direct player/camera controls.

**Core Value:** The player can smoothly walk around a cozy room in the browser and decorate it with reliable local-only building systems.

### Constraints

- **Platform**: Browser-first Godot delivery - the room-builder slice must stay viable for web export.
- **Scope**: Local-only milestone - no backend, no shared-room, no Firebase, no couple systems.
- **Controls**: Keep the current direct movement/camera approach - do not reintroduce click-to-move while building this slice.
- **Architecture**: Reuse and extend the existing Godot prototype instead of restarting from zero.
- **Parity boundary**: Only port the local room-builder, shell, occlusion, and sample-cat systems that matter to this milestone.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Primary runtime code is GDScript in `scripts/player.gd`, `scripts/MinecraftRig.gd`, `scripts/skin_picker.gd`, `scripts/WorldGenerator.gd`, and `scripts/dump_codebase.gd`.
- Scene composition is stored as Godot text scenes in `scenes/main.tscn` and `scenes/player.tscn`.
- Project configuration lives in the Godot INI-style file `project.godot`.
- Tooling also includes a small Python helper in `generate_scene.py`.
- Project notes and workflow context live in Markdown files such as `ROADMAP.md`, `GODOT_QUIRKS.md`, and `GDSCRIPT_EXPERTISE.md`.
## Runtime
- The project is a Godot 4.6 application configured in `project.godot`.
- `project.godot` sets `run/main_scene="res://scenes/main.tscn"`, so `scenes/main.tscn` is the runtime entry scene.
- Rendering uses `gl_compatibility` on desktop and mobile, which fits the stated web/mobile browser target in `ROADMAP.md`.
- Physics is configured to use Jolt via `3d/physics_engine="Jolt Physics"` in `project.godot`.
- There are no autoload singletons defined in `project.godot`.
- Runtime behavior is mostly node-driven: `CharacterBody3D`, `Node3D`, `SpringArm3D`, `Camera3D`, `CanvasLayer`, and `WorldEnvironment`.
## Frameworks
- The codebase relies on stock Godot engine APIs rather than external packages.
- Scene instancing is central: `scenes/main.tscn` instances `scenes/player.tscn`.
- Character movement and camera behavior are implemented in `scripts/player.gd`.
- Procedural rig generation and animation are implemented in `scripts/MinecraftRig.gd`.
- Runtime UI is constructed in code with Godot Control nodes inside `scripts/skin_picker.gd`.
- Editor-time automation uses `@tool` scripts in `scripts/MinecraftRig.gd`, `scripts/WorldGenerator.gd`, and `scripts/dump_codebase.gd`.
## Key Dependencies
- There is no package manager manifest such as `package.json`, `requirements.txt`, or `Cargo.toml`; the main dependency is the installed Godot editor/runtime.
- `skin.png` is the default texture asset used by `scenes/player.tscn` and `scripts/MinecraftRig.gd`.
- `scripts/skin_picker.gd` depends on OS and dialog APIs such as `OS.get_system_dir()` and `FileDialog`.
- `scripts/dump_codebase.gd` depends on editor-only APIs such as `EditorScript`, `DirAccess`, and `FileAccess`.
- `.vscode/settings.json` pins a local Windows Godot executable path for development.
## Configuration
- `project.godot` is the canonical engine configuration file.
- `.gitignore` excludes `.godot/`, `.import/`, export presets, and `.vscode/`.
- `.gitattributes` normalizes text files to LF line endings.
- `.vscode/settings.json` points Godot Tools to `z:\\Godot_v4.6.1-stable_win64.exe\\Godot_v4.6.1-stable_win64.exe`.
- `compiled_codebase.txt` is a generated export target produced by `scripts/dump_codebase.gd`.
## Platform Requirements
- Development appears Windows-oriented because of the VS Code Godot path in `.vscode/settings.json`.
- The intended deployment target is web/mobile web per `ROADMAP.md`.
- Current gameplay input in `scripts/player.gd` is keyboard and mouse based, so mobile input is not implemented yet.
- Current skin import flow in `scripts/skin_picker.gd` expects desktop filesystem access, which is weaker for web exports.
- No export presets are present, so packaging and deployment configuration has not been established in-repo yet.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Functions and local variables are written in snake_case, for example `_spawn_ui()`, `_queue_rebuild()`, and `smoothed_camera_distance`.
- Constants use uppercase snake case, for example `THIRD_PERSON_DISTANCE` in `scripts/player.gd`.
- Enums use PascalCase type names with uppercase members, for example `CameraMode.FREECAM` and `SkinModel.CLASSIC`.
- Reusable script classes use `class_name` in PascalCase, for example `MinecraftRig` and `SkinPicker`.
- File naming is not fully uniform across the repo; new files should ideally pick one clear convention and stay consistent within a subsystem.
## Code Style
- Scripts favor typed GDScript for exported fields, constants, parameters, and many locals.
- Early returns are common for guard-style flow control, especially in `scripts/MinecraftRig.gd` and `scripts/skin_picker.gd`.
- Large behaviors are split into focused helper methods such as `_update_freecam()`, `_update_follow_movement()`, and `_sync_follow_camera_rig()` in `scripts/player.gd`.
- `@onready` is used for scene node references in `scripts/player.gd`.
- Small explanatory comments appear near engine-specific or non-obvious behavior, but most code is self-describing.
## Import Organization
- Godot scripts rely on `extends`, `class_name`, `@tool`, `@export`, `@onready`, and `preload()` rather than language-level imports.
- Resource references are usually explicit `res://` paths, for example `preload("res://scripts/skin_picker.gd")` and `load("res://skin.png")`.
- Built-in engine types are used directly without wrapper modules or facades.
- Script layout usually follows this order: type declarations, constants, vars, onready refs, then lifecycle/helper methods.
## Error Handling
- Error handling is pragmatic and localized.
- Invalid inputs often short-circuit silently with `return`, especially when required nodes are missing.
- Asset validation uses `push_warning()` for recoverable issues in `scripts/MinecraftRig.gd`.
- Fallback behavior is preferred over hard failure, for example `_make_fallback_skin()` when a skin cannot be loaded.
- There is no shared error abstraction, structured result type, or logging service.
## Logging
- Logging is intentionally light.
- Editor helpers use `print()` for visible confirmation, for example `scripts/WorldGenerator.gd` and `scripts/dump_codebase.gd`.
- Runtime status is often shown in UI text rather than console logs, for example `status_label.text` updates in `scripts/skin_picker.gd`.
- There is no log level system or remote logging backend.
## Comments
- Comments are sparse and usually justify engine quirks or editor behavior.
- The best examples are in `scripts/WorldGenerator.gd` and `scripts/MinecraftRig.gd`, where comments explain why owner assignment or mixed loading paths are necessary.
- Most naming is descriptive enough that extra commentary is avoided.
## Function Design
- Functions are usually small and single-purpose, especially in `scripts/player.gd`.
- Setter-driven side effects are common in tool scripts, for example exported properties that call `_queue_rebuild()` or `_generate_ground()`.
- Helper methods encapsulate repeated state sync logic, such as `_apply_outer_visibility()` and `_cache_rest_pose()`.
- Dynamic calls are used in a few places, for example `player_node.call("cycle_camera_mode")`, which trades type safety for loose coupling.
## Module Design
- Each script owns one primary responsibility tied to a scene node or tool role.
- `scripts/player.gd` owns movement and camera behavior.
- `scripts/MinecraftRig.gd` owns procedural geometry, materials, UV mapping, and animation.
- `scripts/skin_picker.gd` owns runtime UI concerns.
- `scripts/WorldGenerator.gd` and `scripts/dump_codebase.gd` are support tools rather than gameplay modules.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

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
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
