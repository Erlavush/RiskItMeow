# External Integrations

## APIs & External Services
- No remote HTTP APIs, SaaS integrations, analytics SDKs, or third-party backends are present in this repository.
- The project currently integrates only with built-in Godot engine services.
- `scripts/skin_picker.gd` uses `FileDialog` to let the player pick a PNG from the local filesystem.
- `scripts/MinecraftRig.gd` uses `ResourceLoader.exists()` and `load()` for engine-managed `res://` resources, plus `Image.load_from_file()` for arbitrary filesystem paths.
- `scripts/dump_codebase.gd` integrates with Godot editor file APIs to export a text snapshot into `compiled_codebase.txt`.

## Data Storage
- Persistent project data is file-based and lives directly in repo assets such as `project.godot`, `scenes/*.tscn`, and `scripts/*.gd`.
- There is no database, save-game layer, or cloud storage integration.
- Runtime skin loading in `scripts/MinecraftRig.gd` reads a user-selected PNG directly from disk.
- `scripts/dump_codebase.gd` writes a generated artifact to `compiled_codebase.txt`.
- `generate_scene.py` can write `scenes/main.tscn` directly from outside the engine.

## Authentication & Identity
- There is no authentication provider, user account system, or identity layer in the current codebase.
- No OAuth, JWT, session, or platform sign-in code exists in `scripts/` or `project.godot`.
- The only user-specific interaction is local file selection through `scripts/skin_picker.gd`.

## Monitoring & Observability
- There is no error reporting, telemetry, tracing, or log aggregation integration.
- Runtime and tool feedback rely on lightweight local mechanisms such as `print()` in `scripts/WorldGenerator.gd` and `scripts/dump_codebase.gd`.
- `scripts/MinecraftRig.gd` uses `push_warning()` for invalid skin inputs.
- UI feedback is surfaced locally through `status_label` text in `scripts/skin_picker.gd`.

## CI/CD & Deployment
- No CI pipelines, build scripts, GitHub Actions, or deployment manifests are present in the repository.
- No `export_presets.cfg` file exists, and `.gitignore` explicitly ignores it.
- Deployment intent is documented in `ROADMAP.md`, but automated export/publish workflows are not implemented.
- Git is the only visible release mechanism at this stage.

## Environment Configuration
- `project.godot` defines engine-level runtime configuration.
- `.vscode/settings.json` stores a machine-local Godot executable path.
- There are no `.env` files, secret stores, or environment-variable driven config paths in the repo.
- Runtime resource loading is path-based using `res://` and user-selected filesystem paths.

## Webhooks & Callbacks
- There are no outbound webhooks, inbound callbacks, or background job endpoints in this codebase.
- Signal wiring is local in-process Godot signal usage, for example button `pressed` connections in `scripts/skin_picker.gd`.
- Callback-style flows are limited to engine events like `_ready()`, `_physics_process()`, `_process()`, `_unhandled_input()`, and file dialog signals.