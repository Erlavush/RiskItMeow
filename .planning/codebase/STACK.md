# Technology Stack

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