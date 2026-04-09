# Codebase Structure

## Top-Level Layout
- `project.godot` is the engine configuration and runtime entry-point declaration.
- `scenes/` contains the hand-authored Godot scenes for the main world, player, and room shell.
- `scripts/` contains nearly all executable gameplay, room, placement, debug, and tool logic.
- `assets/` contains imported props, textures, fonts, and generated UI thumbnails used by the live build.
- `shaders/` contains custom shaders used by the grid overlay and debug checker materials.
- `.planning/` contains project, roadmap, state, todo, and generated codebase-analysis documents.
- `temporary/` contains hidden legacy source assets preserved outside normal Godot scanning.

## Scene Files
- `scenes/main.tscn`: runtime composition root for the active prototype.
- `scenes/player.tscn`: player body, cameras, and rig scene.
- `scenes/room/room_shell.tscn`: room shell node tree that `RoomShell` resizes/configures procedurally.

## Script Subsystems
- `scripts/player.gd`: movement, room-view versus first-person camera switching, mouse capture, and player bounds syncing.
- `scripts/MinecraftRig.gd` and `scripts/minecraft_rig/*.gd`: procedural Minecraft avatar mesh generation, UV mapping, and animation.
- `scripts/skin_picker.gd`: runtime player-tools UI for skin loading, model switching, and camera toggling.
- `scripts/room/*.gd`: room constants, shell geometry, wall segmentation, floor materials, cutaway behavior, and sunlight helpers.
- `scripts/placement/*.gd`: placeable base classes, imported-item pipeline, catalog, placement manager, UI styles/cards, preview caching, room save/load, and validation helpers.
- `scripts/debug/*.gd`: developer environment panel/state/persistence and the Item Studio debug world.
- `scripts/tools/*.gd`: automation scripts such as item-preview generation.

## Asset Organization
- `assets/props/simple_wood_chair/`: imported live chair asset.
- `assets/props/fnaf-minecraft-pizzeria-pack/`: curated pack source used for office chair, desk/computer, and fridge live items.
- `assets/props/small_shelf/`, `assets/props/three_window/`, `assets/props/window/`: additional curated live props.
- `assets/textures/floors/`: floor texture assets used by the room shell.
- `assets/ui/fonts/`: in-game UI fonts.
- `assets/ui/item_previews/`: generated PNG thumbnails for the placement browser.

## Planning And Documentation
- `CLAUDE.md` is the project guidance source called out by `AGENTS.md`.
- `ROADMAP.md` and `.planning/ROADMAP.md` capture the current manual-feature direction.
- `.planning/STATE.md` captures the latest milestone/baseline summary.
- `.planning/codebase/*.md` stores the generated analysis documents intended for future planning steps.
- `THIRD_PARTY_ASSET_SOURCES.txt` tracks the currently used external assets and their source/license status.

## Naming And File Layout Notes
- Most runtime scripts use snake_case filenames, especially under `scripts/placement/`, `scripts/room/`, and `scripts/debug/`.
- A few older or custom rig/tool files use PascalCase filenames such as `scripts/MinecraftRig.gd` and `scripts/WorldGenerator.gd`.
- Reusable GDScript types generally declare `class_name` in PascalCase.
- Constants are typically uppercase snake case, while functions and variables are snake_case.
- Node names inside scenes are mixed but generally descriptive (`RoomShell`, `PlacementManager`, `DeveloperEnvironmentPanel`, `CameraPivot`).

## Special Directories And Generated State
- `.godot/` is Godot-generated editor/import state and should not be treated as authored runtime code.
- `.godot_user/` is the redirected writable user-data area used by the headless wrapper.
- `.vscode/` contains local editor integration settings.
- `temporary/.gdignore` intentionally keeps the preserved legacy source tree out of Godot’s file scan.
