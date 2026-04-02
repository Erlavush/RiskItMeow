# Codebase Structure

## Directory Layout
- `scenes/` contains serialized Godot scenes, currently `main.tscn` and `player.tscn`.
- `scripts/` contains gameplay, rigging, editor, and utility GDScript files.
- Root-level files contain project configuration and documentation such as `project.godot`, `ROADMAP.md`, `GODOT_QUIRKS.md`, and `GDSCRIPT_EXPERTISE.md`.
- `.godot/` contains generated editor cache, import metadata, and shader cache files and is ignored by Git.
- `.vscode/` contains local editor integration settings and is also ignored by Git.
- `.planning/codebase/` is the generated codebase map output directory.

## Directory Purposes
- `scenes/` is the physical composition layer for runtime node trees.
- `scripts/` is the implementation layer for runtime behavior and editor tools.
- Root docs such as `ROADMAP.md` describe project direction and workflow context rather than executable behavior.
- `compiled_codebase.txt` is a generated whole-project export for AI-assisted editing, not a source file to edit by hand.
- `.godot/` should be treated as generated local state, not an authoring surface.

## Key File Locations
- Engine configuration: `project.godot`.
- Main scene entry: `scenes/main.tscn`.
- Player scene: `scenes/player.tscn`.
- Player movement and camera logic: `scripts/player.gd`.
- Procedural rig construction and animation: `scripts/MinecraftRig.gd`.
- Runtime toolbar UI: `scripts/skin_picker.gd`.
- Optional ground generation helper: `scripts/WorldGenerator.gd`.
- Codebase export script: `scripts/dump_codebase.gd`.
- Scene-writing Python helper: `generate_scene.py`.

## Naming Conventions
- Scene files are lowercase: `scenes/main.tscn`, `scenes/player.tscn`.
- Script filenames are mixed: some are PascalCase (`scripts/MinecraftRig.gd`, `scripts/WorldGenerator.gd`) while others are snake_case (`scripts/player.gd`, `scripts/skin_picker.gd`, `scripts/dump_codebase.gd`).
- Reusable script classes use `class_name` in PascalCase, for example `MinecraftRig` and `SkinPicker`.
- GDScript functions and variables use snake_case, for example `_update_follow_camera()` and `camera_pitch`.
- Constants use uppercase snake case, for example `FAST_SPEED` and `HEAD_OUTER_INFLATE_PX`.
- Scene node names tend to use PascalCase such as `CameraPivot`, `SpringArm3D`, and `DirectionalLight3D`.

## Where to Add New Code
- Add new runtime scenes under `scenes/`.
- Add new gameplay or UI scripts under `scripts/`.
- Keep editor-only helpers in `scripts/` only if they are clearly marked with `@tool` or `extends EditorScript`.
- Place future planning artifacts under `.planning/` rather than the project root.
- Keep generated exports like `compiled_codebase.txt` out of hand-maintained design documentation.

## Special Directories
- `.godot/` is generated and should be ignored for architecture decisions unless debugging import/editor behavior.
- `.vscode/` is local developer tooling and not required by the game runtime.
- `.planning/codebase/` is intended for GSD workflow documents that future planning steps can consume.
- There is currently no dedicated `assets/` directory; texture assets like `skin.png` live at the repo root.