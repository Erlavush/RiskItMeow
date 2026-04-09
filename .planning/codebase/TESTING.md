# Testing

## Current State
- No automated test framework is configured in the repository.
- There is no `tests/` directory, no Gut/WAT addon, and no CI runner executing gameplay or editor tests.
- Validation is currently done through manual playtesting and a small set of headless smoke-test commands.

## Existing Smoke-Test Commands
- Headless runtime boot: `scripts/tools/run_godot_headless.cmd --headless --path "Z:\RiskItMeow\risk-it-meow" --quit-after 1`
- Headless editor scan: `scripts/tools/run_godot_headless.cmd --headless --editor --path "Z:\RiskItMeow\risk-it-meow" --quit-after 1`
- Preview regeneration: `Z:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe --path Z:\RiskItMeow\risk-it-meow --script res://scripts/tools/generate_item_previews.gd`
- The headless runtime boot currently exits cleanly.
- The headless editor scan currently initializes and exits successfully, with the usual scan-thread-aborted warning caused by the forced immediate quit.

## Manual Validation Surfaces
- `scenes/main.tscn` is the primary end-to-end runtime smoke-test surface.
- Placement workflows should be validated in both Build and Edit modes, including save/load, duplicate/delete, and preview validity states.
- Window placement should be validated together with wall cutouts and the `RoomSunlightController`.
- The player should be validated in both room-view and first-person camera modes.
- The developer panel and debug Item Studio should be validated because both mutate persisted local state and cross-system behavior.

## High-Risk Untested Areas
- `scripts/placement/placement_manager.gd` has no automated coverage despite being the largest runtime controller.
- `scripts/debug/debug_world_controller.gd` has no automated coverage despite its size and editor-like responsibilities.
- `scripts/placement/imported_scene_placeable.gd` has no automated checks for auto-fit metrics, bounds extraction, or GLTF fallback loading.
- `scripts/room/room_shell.gd`, `scripts/room/room_cutaway_controller.gd`, and `scripts/room/room_sunlight_controller.gd` have no regression coverage for room visibility rules.
- `scripts/player.gd` camera-mode transitions and direct-key movement handling are untested.

## What Counts As Useful Future Tests
- Headless scene boot tests for `project.godot` and `scenes/main.tscn`.
- Pure-logic tests for `PlacementSurfaceQueries`, `PlacementValidator`, and room-layout serialization helpers.
- Regression tests for imported-item profile overrides and room save/load round-trips.
- Focused interaction tests for cutaway state, wall openings, and window-driven sunlight updates.
- Tooling checks that regenerate item previews and verify expected output files under `assets/ui/item_previews/`.

## Missing Infrastructure
- No CI pipeline exists to run even the current smoke-test commands automatically.
- No golden scenes or fixtures are defined beyond the live runtime scenes themselves.
- No coverage tooling is present.
- No test-only seams have been introduced for the larger node-heavy controllers, so future automation will require some refactoring.
