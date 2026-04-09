# Technology Stack

## Languages
- Primary runtime code is GDScript in `scripts/player.gd`, `scripts/MinecraftRig.gd`, `scripts/placement/*.gd`, `scripts/room/*.gd`, and `scripts/debug/*.gd`.
- Scene composition is stored in Godot text scenes such as `scenes/main.tscn`, `scenes/player.tscn`, and `scenes/room/room_shell.tscn`.
- Rendering helpers use Godot shaders in `shaders/grid_overlay.gdshader` and `shaders/floor_checker.gdshader`.
- Project configuration and workflow context live in `project.godot`, `CLAUDE.md`, `ROADMAP.md`, and `.planning/*.md`.
- Tooling also includes a Windows batch wrapper in `scripts/tools/run_godot_headless.cmd` and a legacy Python helper in `generate_scene.py`.

## Engine And Runtime
- The project runs on Godot `4.6.1` and boots `res://scenes/main.tscn` from `project.godot`.
- Physics uses `Jolt Physics` via `project.godot`.
- Rendering uses the `gl_compatibility` renderer, with `d3d12` selected as the Windows rendering device in `project.godot`.
- There are no autoload singletons; runtime wiring is scene-local and node-driven.
- The main world scene composes `RoomShell`, `RoomViewCameraController`, `PlacementManager`, `RoomCutawayController`, `RoomSunlightController`, `DebugWorldController`, `DeveloperEnvironmentPanel`, and the instanced `Player`.

## Core Runtime Systems
- Player movement, room/first-person camera switching, and input handling live in `scripts/player.gd`.
- The Minecraft-style avatar rig and skin loading pipeline live in `scripts/MinecraftRig.gd`, `scripts/minecraft_rig/*.gd`, and `scripts/skin_picker.gd`.
- The room shell, wall segmentation, floor materials, cutaway logic, and sunlight helpers live in `scripts/room/*.gd`.
- The build/edit placement browser, validation, room save/load, imported-item catalog, and preview cache live in `scripts/placement/*.gd`.
- Developer-only lighting tuning and the in-game Item Studio live in `scripts/debug/*.gd`.

## Assets And Content
- Runtime props are curated imported scenes under `assets/props/`.
- Generated browser thumbnails are cached under `assets/ui/item_previews/`.
- UI fonts live under `assets/ui/fonts/titillium_web/`.
- Floor textures live under `assets/textures/floors/`.
- Legacy source assets are intentionally preserved under `temporary/` and hidden from Godot scanning with `temporary/.gdignore`.

## Configuration And Tooling
- `LOCAL_TOOLING.md` documents the local Windows Godot GUI and console executables.
- `scripts/tools/run_godot_headless.cmd` redirects Godot user-data paths into `.godot_user/` for headless runs.
- `scripts/tools/generate_item_previews.gd` regenerates the cached PNG thumbnails used by the placement browser.
- `scripts/dump_codebase.gd` exports a text snapshot of the repo into `compiled_codebase.txt` for AI review workflows.
- There is no package-manager manifest such as `package.json`, `requirements.txt`, or `Cargo.toml`.

## Platform Assumptions
- The repo is currently Windows-first for development because local tooling paths and the headless wrapper are Windows-specific.
- Runtime input is desktop keyboard and mouse oriented; there is no touch-input layer or InputMap abstraction yet.
- No `export_presets.cfg` is committed, so deployment/export configuration is not tracked in-repo.
- The current project shape is a local Godot prototype rather than a networked game or browser-ready build.
