# Phase 11: Tanuki Decor Mod Asset Intake Strategy - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the best legal and technical strategy for bringing selected open-source Minecraft mod assets into the current Godot room-building prototype, starting with Tanuki Decor. This phase is about offline asset intake into the existing placement/catalog pipeline, not about running Minecraft mods, shipping Java compatibility, or chasing gameplay parity with the source mod.

</domain>

<decisions>
## Implementation Decisions

### Scope anchor
- **D-01:** Tanuki Decor is the first reference mod for this support work, but the rules should be reusable for later open-source Minecraft mods.
- **D-02:** Treat this as an asset-intake phase, not a runtime NeoForge, Forge, or Fabric support phase.
- **D-03:** The destination pipeline is the current Godot imported-item catalog, placement workflow, preview generator, and Item Studio tuning flow.

### Intake strategy
- **D-04:** The plan must explicitly analyze loader requirements, external library requirements, vanilla Minecraft asset references, and legal/provenance constraints before any import work is treated as safe.
- **D-05:** Manual Blockbench export is acceptable as a fallback or spot-check path, but the preferred solution should avoid undocumented one-by-one work when the source asset count is large.
- **D-06:** The strategy must separate static decorative props from mechanic-heavy assets and define different handling rules for each class.

### Project guardrails
- **D-07:** Keep the game local-only and room-scale. Do not use this phase to add backend, multiplayer, or source-project parity systems.
- **D-08:** Do not reintroduce Minecraft gameplay systems such as recipe menus, storage parity, redstone-like behavior, or mod-loader compatibility unless they are explicitly requested later.

### the agent's Discretion
- Exact manifest format for mod-source provenance and conversion status
- Exact pilot batch size
- Exact choice between a Blockbench-led export path and a semi-automated converter, as long as the recommendation is grounded in the researched constraints

</decisions>

<specifics>
## Specific Ideas

- The user specifically wants analysis of whether the mod depends on vanilla Minecraft mechanics, textures, or loader infrastructure.
- The user suggested opening assets in Blockbench and exporting them as glTF one by one, but wants the best overall solution rather than a blind manual grind.
- The target mod is Tanuki Decor: [https://github.com/skyjay1/Tanuki-Decor](https://github.com/skyjay1/Tanuki-Decor)

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project baseline
- `.planning/PROJECT.md` - Current validated scope and out-of-scope rules
- `.planning/ROADMAP.md` - Phase 11 goal and requirement IDs
- `.planning/STATE.md` - Current project position and baseline snapshot
- `CLAUDE.md` - Repo guidance reflecting the real 8x8 room-shell baseline

### Existing Godot placement pipeline
- `scripts/placement/placement_manager.gd` - Placement/edit/save workflow entry point
- `scripts/placement/placement_inventory_catalog.gd` - Current curated item-catalog source
- `scripts/placement/imported_scene_placeable.gd` - Imported-scene placeable path already used by live assets
- `scripts/debug/debug_world_controller.gd` - Item Studio workflow and tuning entry point
- `scripts/tools/generate_item_previews.gd` - Cached preview PNG pipeline
- `THIRD_PARTY_ASSET_SOURCES.txt` - Existing provenance tracking that Phase 11 must extend

### Tanuki Decor source references
- `https://github.com/skyjay1/Tanuki-Decor` - Upstream mod repo
- `https://raw.githubusercontent.com/skyjay1/Tanuki-Decor/dev/build.gradle` - Loader and dependency configuration
- `https://raw.githubusercontent.com/skyjay1/Tanuki-Decor/dev/gradle.properties` - Minecraft version, license, authors, and credits
- `https://raw.githubusercontent.com/skyjay1/Tanuki-Decor/dev/src/main/resources/META-INF/neoforge.mods.toml` - Declared mod metadata and required dependencies

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/placement/imported_scene_placeable.gd`: already supports data-driven imported scenes, which is the right target for converted mod assets
- `scripts/debug/debug_world_controller.gd`: existing Item Studio gives a place to fix pivots, collisions, scale, and mount rules for imported pilot assets
- `scripts/tools/generate_item_previews.gd`: existing preview cache pipeline can validate whether new imported assets fit the browser workflow

### Established Patterns
- The repo already favors a curated catalog over large unfiltered packs
- Third-party assets already require provenance tracking and item-by-item tuning
- Placement data and previews are local-only and runtime-safe, which matches a curated import workflow better than direct mod loading

### Integration Points
- New imported assets need catalog entries, preview PNGs, provenance entries, and optional Item Studio overrides
- Any future mod-intake schema should plug into the existing imported-item flow instead of creating a second placement architecture

</code_context>

<deferred>
## Deferred Ideas

- Runtime `.jar` loading or live mod-loader support
- Full behavior parity for storage, menus, recipes, ticking block entities, or other Minecraft systems
- "Support any Minecraft mod" as a single generic promise before intake rules exist
- Automatic import of vanilla Minecraft assets until legal and packaging rules are explicit

</deferred>

---

*Phase: 11-tanuki-decor-mod-asset-intake*
*Context gathered: 2026-04-09*
