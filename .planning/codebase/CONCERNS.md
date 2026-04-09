# Concerns

## Current Drift Risks
- Repo guidance is not fully synchronized: `AGENTS.md` still describes a reduced `10x10` floor-only baseline, while the actual runtime in `scenes/main.tscn` and `CLAUDE.md` includes an `8x8` room shell, walls, roof, cutaway, sunlight helpers, the developer panel, and the Item Studio.
- `RoomConstants.DEFAULT_ROOM_HALF_EXTENTS` is `Vector2(5.0, 5.0)`, but the live scene overrides the room to `Vector2(4, 4)`. That increases the chance of stale assumptions leaking into docs or new code.
- Some planning/codebase docs were already lagging the real runtime shape, which is why this map needed a refresh.

## High-Complexity Hotspots
- `scripts/placement/placement_manager.gd` is the main runtime hotspot and carries UI building, placement state, editing, inventory, persistence, cutaway coordination, and editor-preview behavior in one file.
- `scripts/debug/debug_world_controller.gd` is the second major hotspot and effectively embeds a standalone in-game tuning tool.
- `scripts/debug/developer_environment_panel.gd` is another large controller with runtime and editor-preview behavior mixed together.
- These hotspots are still workable, but any change inside them has a broad regression surface.

## Legacy Tooling Still In Repo
- `generate_scene.py` writes an older `10x10` grass-block `scenes/main.tscn` that does not match the current hand-authored room-based runtime.
- `scripts/WorldGenerator.gd` still generates a legacy `10x10` CSG grass floor and no longer reflects the active baseline.
- `scripts/dump_codebase.gd` is useful for export workflows, but it can amplify accidental data disclosure if sensitive files are ever added later.

## Architecture Fragility
- `RoomSunlightController` reaches into `PlacementManager._placed_items_root` directly instead of using a public accessor, so internal placement refactors could break window-light syncing.
- Several systems rely on metadata and dynamic calls rather than explicit interfaces, which is pragmatic but less discoverable and less type-safe.
- Widespread `@tool` usage means editor and runtime behavior are tightly coupled inside shared files.

## Product And Input Gaps
- Input is still hardcoded through direct key polling and tool-specific shortcuts instead of `InputMap` actions, which makes rebinding and non-desktop input harder.
- There is no export configuration, touch UI, or mobile/browser-specific validation despite older docs referencing wider platform ambitions.
- The project is intentionally local-only right now, so future scope expansion would require deliberate architecture work rather than incremental toggles.

## Asset And Content Risks
- `THIRD_PARTY_ASSET_SOURCES.txt` is missing preserved source/license metadata for `assets/props/small_shelf` and `assets/props/window`.
- Imported assets depend on manual collision, pivot, scaling, and mount overrides, and the repo already acknowledges that some curated items still need tuning.
- The legacy pizzeria source tree is intentionally preserved in `temporary/`, which is useful, but it also means old assets remain close to the active content pipeline.

## Safety Net Gaps
- There are no automated tests.
- There is no CI pipeline to at least run headless boot and editor-scan smoke tests.
- The most complex systems are precisely the ones with the least automated protection.
