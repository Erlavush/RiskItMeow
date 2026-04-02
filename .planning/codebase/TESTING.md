# Testing Patterns

## Test Framework
- No automated test framework is currently configured in this repository.
- There are no `tests/` directories, Gut addons, WAT addons, or CI test runners.
- No headless test harness scripts are committed in the project itself.
- Validation today appears to depend on manual runs in the Godot editor/runtime.

## Test File Organization
- There are no dedicated test files or fixture directories.
- The closest thing to support tooling is `scripts/dump_codebase.gd`, which exports the project for AI review, and `generate_scene.py`, which can rewrite `scenes/main.tscn`.
- Runtime scenes such as `scenes/main.tscn` and `scenes/player.tscn` currently act as manual smoke-test surfaces.
- Root docs like `GODOT_QUIRKS.md` capture known engine pitfalls but are not executable tests.

## Test Structure
- The natural manual smoke test is to open `scenes/main.tscn` through `project.godot` and verify the player loads, camera modes cycle, and movement works.
- Camera behavior in `scripts/player.gd` should be exercised across freecam, third-person, and first-person modes.
- Rig behavior in `scripts/MinecraftRig.gd` should be checked for rebuild correctness, texture loading, and animation response to movement velocity.
- UI behavior in `scripts/skin_picker.gd` should be checked for button wiring, file dialog flow, and status-label updates.
- Tool scripts such as `scripts/WorldGenerator.gd` and `scripts/dump_codebase.gd` need editor-side validation rather than gameplay validation.

## Mocking
- No mocking or stubbing patterns are present.
- Dependencies are mostly engine APIs and scene nodes, so current code directly calls into Godot runtime objects.
- Dynamic calls like `call()` and `get()` in `scripts/skin_picker.gd` and `scripts/MinecraftRig.gd` would need seams before traditional mocking becomes practical.

## Fixtures and Factories
- `scenes/player.tscn` is the main reusable runtime fixture because it packages player body, rig, collision, and camera.
- `skin.png` is the default asset fixture for the rig system.
- `scenes/main.tscn` is the top-level integration fixture for world, ground, lighting, and player instancing.
- `compiled_codebase.txt` is a generated artifact for review workflows, not a runtime fixture.

## Coverage
- There is no code coverage tooling or baseline.
- Movement, camera collision handling, filesystem skin import, and procedural mesh generation have zero automated coverage.
- Tool-script behaviors also have no regression coverage.
- The roadmap in `ROADMAP.md` is ahead of implemented safety nets.

## Test Types
- Current practical test types are manual runtime smoke tests and manual editor tool checks.
- Integration testing should focus first on `project.godot` boot, `scenes/main.tscn`, and the interaction between `scripts/player.gd`, `scripts/MinecraftRig.gd`, and `scripts/skin_picker.gd`.
- Future unit-like tests would need to isolate math helpers, UV mapping helpers, and camera state transitions.
- Future export tests should cover browser/mobile constraints because the project target is web-focused.

## Common Patterns
- There is no established automated test pattern yet.
- The repo instead documents operational knowledge in `GODOT_QUIRKS.md` and `GDSCRIPT_EXPERTISE.md`.
- Manual verification is likely happening inside the editor with immediate visual confirmation and console warnings.
- Adding tests will require introducing a framework, deciding whether to test in-editor or headless, and separating pure logic from scene-bound code.