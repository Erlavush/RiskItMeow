# Integrations

## Remote Services
- No remote HTTP APIs, backend services, analytics SDKs, auth providers, or multiplayer services are integrated.
- The repo contains no Firebase, web backend, shared-room, or online sync code.
- All currently active integrations are local engine, file, and asset workflows.

## Local Persistence
- Room layouts persist to `user://room_layout.json` through `scripts/placement/placement_room_layout_store.gd`.
- Developer lighting and post-processing settings persist to `user://developer_environment_settings.cfg` through `scripts/debug/developer_environment_persistence.gd`.
- Per-item tuning overrides persist to `user://placement_item_profile_overrides.cfg` through `scripts/placement/placement_item_profile_override_store.gd`.
- These saves are local-only and are reloaded at startup by the placement manager, developer panel, and Item Studio.

## Filesystem And Editor Integration
- `scripts/skin_picker.gd` uses `FileDialog` and `Image.load_from_file()` so the player can choose a local `64x64` PNG skin.
- `scripts/placement/placement_preview_cache.gd` reads and writes cached PNG previews under `assets/ui/item_previews/`.
- `scripts/tools/generate_item_previews.gd` drives the preview generation pass by creating `PlacementItemPreview` scenes and saving PNG files.
- `scripts/dump_codebase.gd` writes `compiled_codebase.txt` into the repo root.
- `generate_scene.py` can overwrite `scenes/main.tscn`, although that script reflects an older scene layout.

## Engine-Level Asset Integration
- Imported runtime props are loaded from `res://assets/props/...` by `scripts/placement/imported_scene_placeable.gd`.
- `ImportedScenePlaceable` can instantiate `PackedScene` resources directly or rebuild `.gltf` / `.glb` content through `GLTFDocument` if needed.
- `RoomFloorMaterials` and the placement UI load textures and fonts from `res://assets/textures/...` and `res://assets/ui/fonts/...`.
- The player rig loads the default skin from `res://skin.png` and can replace it from a local filesystem path.

## In-Process Communication
- Cross-system coordination is handled through Godot node references and signals, not external messaging.
- `PlacementManager` emits `room_layout_visuals_changed`, which is consumed by `RoomSunlightController`.
- `DeveloperEnvironmentPanel` emits `environment_state_changed`, which is also consumed by `RoomSunlightController`.
- `DebugWorldController` emits `debug_world_enabled_changed`, which is consumed by `DeveloperEnvironmentPanel`.

## Tooling And Execution
- `LOCAL_TOOLING.md` documents the local Godot executables used for editor and console runs.
- `scripts/tools/run_godot_headless.cmd` wraps headless Godot execution and redirects writable user-data folders into `.godot_user/`.
- `.vscode/settings.json` stores the machine-local Godot executable path for the editor extension.
- There is no CI pipeline, build server, or deployment automation in the repo.

## Third-Party Assets
- `THIRD_PARTY_ASSET_SOURCES.txt` tracks the live curated asset sources that still feed the runtime catalog.
- The repo depends on Sketchfab-sourced furniture/window assets and the Titillium Web font.
- Metadata is incomplete for `assets/props/small_shelf` and `assets/props/window`, so those assets are integration/documentation risks.

## Secrets And Environment
- There are no `.env` files, API keys, or secret-management systems in the repository.
- Configuration is path-based and file-based through `project.godot`, scene resources, and the local `user://` save files.
