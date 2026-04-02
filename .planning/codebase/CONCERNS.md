# Codebase Concerns

## Tech Debt
- `scenes/player.tscn` contains a large amount of serialized rig mesh data even though `scripts/MinecraftRig.gd` rebuilds the rig procedurally at runtime. That duplicates source of truth and makes the scene noisy to diff.
- `generate_scene.py` can overwrite `scenes/main.tscn`, but its generated scene shape no longer matches the current hand-authored `scenes/main.tscn`. That creates a drift risk between tooling and runtime assets.
- Naming conventions are mixed across `scripts/`, which makes future discovery and refactors less predictable.
- Important product intent lives in `ROADMAP.md`, but that intent is ahead of the implemented runtime systems.

## Known Bugs
- The skin-loading workflow in `scripts/skin_picker.gd` depends on desktop filesystem dialogs and likely will not translate cleanly to browser/mobile web deployment.
- Player movement bounds in `scripts/player.gd` are hardcoded to a 10x10 platform via `PLATFORM_HALF_SIZE`, so changing ground dimensions in `scenes/main.tscn` can desynchronize movement limits from the actual level.
- `scripts/MinecraftRig.gd` depends on `get_parent().get("velocity")`; parent refactors can silently break animation if the property disappears or changes type.

## Security Considerations
- There are no obvious secrets or credentials in the repository.
- `scripts/skin_picker.gd` accepts an arbitrary local PNG path chosen by the user. That is low-risk in a local game, but it is still direct filesystem access.
- `scripts/dump_codebase.gd` exports a full project snapshot into `compiled_codebase.txt`. If the repo later contains secrets, that export file could amplify accidental disclosure.
- No authentication, server trust boundaries, or remote attack surfaces exist yet.

## Performance Bottlenecks
- `scenes/main.tscn` uses `CSGBox3D` for the ground, which is acceptable for a prototype but not ideal for a larger world or web/mobile performance target.
- `scripts/MinecraftRig.gd` creates multiple `MeshInstance3D` nodes per body part, which is reasonable for one character but may scale poorly for many actors.
- Runtime camera collision handling in `scripts/player.gd` is lightweight now, but overall character presentation cost is high relative to the current tiny scene.
- The serialized `ArrayMesh` data inside `scenes/player.tscn` increases file size and review friction even if runtime cost is manageable.

## Fragile Areas
- `scripts/player.gd` uses direct key polling (`KEY_W`, `KEY_A`, etc.) instead of `InputMap` actions, so remapping and multi-platform input will be harder.
- `scripts/skin_picker.gd` uses string-based `call()` to trigger player behavior, which reduces compile-time safety.
- `scripts/WorldGenerator.gd` mutates scene children in an exported setter, so editor-time usage needs care to avoid accidental scene churn.
- `scripts/MinecraftRig.gd` mixes editor-time rebuilding, runtime animation, and texture loading in one class, making it a high-change hotspot.

## Scaling Limits
- The current architecture is optimized for a single prototype world and a single player avatar.
- There is no save system, state management layer, asset pipeline folder, or content streaming strategy.
- The project has no abstraction for mobile controls, multiple characters, or larger rooms.
- There is no automated deployment path for the stated web target.

## Dependencies at Risk
- The project depends heavily on Godot 4.6 behavior and Jolt configuration set in `project.godot`.
- Browser/mobile support assumptions in `ROADMAP.md` are not yet backed by browser-safe input and file-loading flows.
- Local developer tooling depends on a machine-specific path in `.vscode/settings.json`.
- Several notes in `GODOT_QUIRKS.md` imply the team is already working around engine-specific edge cases.

## Missing Critical Features
- There are no automated tests.
- There is no export configuration for web deployment.
- Mobile/touch input is missing despite the platform target.
- Building mode, lighting occlusion logic, interactive props, and broader gameplay systems described in `ROADMAP.md` are not implemented in the current runtime.

## Test Coverage Gaps
- `scripts/player.gd` camera mode transitions, movement clamping, and spring-arm behavior are untested.
- `scripts/MinecraftRig.gd` UV mapping, rebuild logic, and animation blending are untested.
- `scripts/skin_picker.gd` file dialog behavior and invalid-file handling are untested.
- Tooling scripts that write files or mutate scenes have no regression coverage.