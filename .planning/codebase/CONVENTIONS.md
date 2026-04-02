# Coding Conventions

## Naming Patterns
- Functions and local variables are written in snake_case, for example `_spawn_ui()`, `_queue_rebuild()`, and `smoothed_camera_distance`.
- Constants use uppercase snake case, for example `THIRD_PERSON_DISTANCE` in `scripts/player.gd`.
- Enums use PascalCase type names with uppercase members, for example `CameraMode.FREECAM` and `SkinModel.CLASSIC`.
- Reusable script classes use `class_name` in PascalCase, for example `MinecraftRig` and `SkinPicker`.
- File naming is not fully uniform across the repo; new files should ideally pick one clear convention and stay consistent within a subsystem.

## Code Style
- Scripts favor typed GDScript for exported fields, constants, parameters, and many locals.
- Early returns are common for guard-style flow control, especially in `scripts/MinecraftRig.gd` and `scripts/skin_picker.gd`.
- Large behaviors are split into focused helper methods such as `_update_freecam()`, `_update_follow_movement()`, and `_sync_follow_camera_rig()` in `scripts/player.gd`.
- `@onready` is used for scene node references in `scripts/player.gd`.
- Small explanatory comments appear near engine-specific or non-obvious behavior, but most code is self-describing.

## Import Organization
- Godot scripts rely on `extends`, `class_name`, `@tool`, `@export`, `@onready`, and `preload()` rather than language-level imports.
- Resource references are usually explicit `res://` paths, for example `preload("res://scripts/skin_picker.gd")` and `load("res://skin.png")`.
- Built-in engine types are used directly without wrapper modules or facades.
- Script layout usually follows this order: type declarations, constants, vars, onready refs, then lifecycle/helper methods.

## Error Handling
- Error handling is pragmatic and localized.
- Invalid inputs often short-circuit silently with `return`, especially when required nodes are missing.
- Asset validation uses `push_warning()` for recoverable issues in `scripts/MinecraftRig.gd`.
- Fallback behavior is preferred over hard failure, for example `_make_fallback_skin()` when a skin cannot be loaded.
- There is no shared error abstraction, structured result type, or logging service.

## Logging
- Logging is intentionally light.
- Editor helpers use `print()` for visible confirmation, for example `scripts/WorldGenerator.gd` and `scripts/dump_codebase.gd`.
- Runtime status is often shown in UI text rather than console logs, for example `status_label.text` updates in `scripts/skin_picker.gd`.
- There is no log level system or remote logging backend.

## Comments
- Comments are sparse and usually justify engine quirks or editor behavior.
- The best examples are in `scripts/WorldGenerator.gd` and `scripts/MinecraftRig.gd`, where comments explain why owner assignment or mixed loading paths are necessary.
- Most naming is descriptive enough that extra commentary is avoided.

## Function Design
- Functions are usually small and single-purpose, especially in `scripts/player.gd`.
- Setter-driven side effects are common in tool scripts, for example exported properties that call `_queue_rebuild()` or `_generate_ground()`.
- Helper methods encapsulate repeated state sync logic, such as `_apply_outer_visibility()` and `_cache_rest_pose()`.
- Dynamic calls are used in a few places, for example `player_node.call("cycle_camera_mode")`, which trades type safety for loose coupling.

## Module Design
- Each script owns one primary responsibility tied to a scene node or tool role.
- `scripts/player.gd` owns movement and camera behavior.
- `scripts/MinecraftRig.gd` owns procedural geometry, materials, UV mapping, and animation.
- `scripts/skin_picker.gd` owns runtime UI concerns.
- `scripts/WorldGenerator.gd` and `scripts/dump_codebase.gd` are support tools rather than gameplay modules.