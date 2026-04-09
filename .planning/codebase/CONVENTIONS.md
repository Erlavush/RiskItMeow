# Conventions

## Naming
- GDScript functions, locals, and most members use snake_case, for example `_apply_cutaway_state()`, `_sync_window_sunlight()`, and `_build_live_item_defs()`.
- Constants use uppercase snake case, for example `FAST_SPEED`, `WINDOW_ITEM_IDS`, and `CURATED_INITIAL_OWNED`.
- Reusable script classes use `class_name` in PascalCase, for example `RoomShell`, `PlacementManager`, `ImportedScenePlaceable`, and `DebugWorldController`.
- File naming is mostly snake_case, with notable PascalCase exceptions such as `scripts/MinecraftRig.gd` and `scripts/WorldGenerator.gd`.

## Script Layout
- Files usually follow the Godot style of `@tool` / `class_name` / `extends`, then constants, exports, member variables, `@onready` refs, and finally lifecycle plus helper methods.
- Strong typing is used heavily for exported properties, constants, arrays, dictionaries, and return values.
- Godot path references are usually explicit `res://...` strings or `preload()` constants.
- Editor-aware files typically branch early on `Engine.is_editor_hint()`.

## Control Flow
- Guard clauses are the dominant error-handling pattern; missing node refs or invalid state usually short-circuit with `return`.
- Large controller scripts decompose behavior into many private helpers instead of nested mega-functions, even when the file itself remains large.
- Dynamic calls such as `call()` and `has_method()` are used when subsystems want loose coupling across node boundaries.
- Signals are used for cross-system updates where a direct call would be too tightly coupled, especially between placement, developer lighting, and debug systems.

## Scene And UI Patterns
- Runtime UI is built mostly in code rather than authored in `.tscn` UI scenes.
- Placement browser cards, the developer panel, the player-tools panel, and the debug Item Studio all construct `Control` trees procedurally.
- Node-path exports are the standard dependency-injection mechanism between scene-local controllers.
- Metadata on runtime placeables is used as lightweight state storage for values like `item_id`, `placement_surface`, and `host_surface_id`.

## Data Patterns
- Static `RefCounted` helper classes are used for catalog data, save/load helpers, validation, UI styling, and surface-query math.
- Item definitions are dictionaries built by `PlacementInventoryCatalog`, then merged with local override dictionaries from `PlacementItemProfileOverrideStore`.
- Room saves serialize to plain dictionaries and JSON through `PlacementRoomLayoutStore`.
- Persistent developer settings serialize to `ConfigFile` data rather than JSON.

## Error Handling And Logging
- Warnings use `push_warning()` for recoverable issues such as invalid assets or save/load problems.
- Runtime user feedback is often shown in labels/buttons instead of being printed to the console.
- There is no shared logger, error bus, or structured result type used across subsystems.
- Fallback rendering paths exist in `SimpleWoodChair` and `MinecraftRig` when imported visuals or user-selected skins fail.

## Practical Style Boundaries
- `@tool` is common, so new changes should respect editor/runtime dual execution.
- The repo favors direct key polling and shortcut checks over `InputMap` actions in the currently active gameplay and tool controllers.
- Encapsulation is pragmatic rather than strict; some systems reach into other controllers’ internal state when convenient.
- New work should preserve the current manual-feature baseline rather than trying to restore older source-porting abstractions.
