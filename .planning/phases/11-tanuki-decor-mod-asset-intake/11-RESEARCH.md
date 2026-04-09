# Phase 11: Tanuki Decor Mod Asset Intake Strategy - Research

**Researched:** 2026-04-09
**Domain:** Open-source Minecraft mod asset intake into Godot 4.6
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Start with Tanuki Decor, but make the strategy reusable for later open-source Minecraft mods.
- Treat this as an offline asset-intake/support phase, not a runtime NeoForge, Forge, or Fabric compatibility phase.
- Use the current Godot imported-item placement pipeline as the target.
- Explicitly analyze loader requirements, library requirements, vanilla Minecraft dependencies, and legal/provenance issues before importing anything.
- Manual Blockbench export is allowed as a fallback, but the preferred path should avoid undocumented one-by-one work at scale.
- Separate static decorative props from mechanic-heavy assets and plan different handling for each class.

### the agent's Discretion
- Manifest shape for mod-intake metadata
- Exact pilot asset count
- Exact choice between Blockbench-led export and a semi-automated converter

### Deferred Ideas (OUT OF SCOPE)
- Runtime `.jar` loading
- Mod-loader compatibility
- Recipe, storage, menu, and ticking-system parity
- Broad "any Minecraft mod" support without curation rules

</user_constraints>

<research_summary>
## Summary

Tanuki Decor is not a self-contained art drop. The repo is a NeoForge `1.21.1` mod with `GNU LGPLv3` licensing, required dependencies only on NeoForge and Minecraft, optional JEI integration, and a large resource tree containing `212` blockstate files, `967` model files, and `218` texture files. The asset side is substantial, but it is tightly shaped around Minecraft conventions such as `minecraft:block/block`, `minecraft:item/generated`, vanilla texture references, and Minecraft render types like `minecraft:solid`, `minecraft:cutout`, and `minecraft:translucent`.

The content also is not "just meshes." Tanuki Decor includes behavior-heavy Java code for beds, storage, clocks, display cases, DIY workbenches, phonographs, slot machines, train sets, multiblocks, wall pieces, and block entities with dedicated renderers. That means "use all assets" only works if the phase distinguishes decorative meshes from assets whose identity depends on Minecraft systems. A straight one-pass export of every model would produce a pile of geometry, but it would not produce meaningful support for the mod.

**Primary recommendation:** Build a curated asset-intake pipeline, not direct mod support. Use Tanuki Decor as the first source mod, classify assets into `Class A` static props, `Class B` wrapper candidates, and `Class C` deferred system-dependent content, and only import a small representative `Class A` pilot into the current Godot catalog until the provenance and conversion workflow is proven.

</research_summary>

<standard_stack>
## Standard Toolchain

### Core
| Tool | Purpose | Why it fits this phase |
|------|---------|------------------------|
| Git source inspection | Verify loader, license, credits, counts, and code complexity from upstream files | Avoids guessing about dependencies and asset independence |
| Blockbench | Inspect Minecraft JSON models and export selected assets to glTF when they open cleanly | Practical viewer/exporter for Minecraft-style model JSON |
| glTF 2.0 / `.glb` | Portable handoff format for imported 3D assets | Matches Godot's current imported-scene workflow better than raw Minecraft JSON |
| Existing Godot imported-item pipeline | Final destination for pilot assets | The repo already uses data-driven imported scenes, previews, and Item Studio tuning |

### Supporting
| Tool / Pattern | Purpose | When to use |
|----------------|---------|-------------|
| Intake manifest file | Track per-asset provenance, dependencies, class, and conversion status | Required before importing more than a few assets |
| Item Studio | Fix pivots, collisions, and scale on converted scenes | Every pilot asset should pass through it |
| Preview generator | Validate browser-card compatibility | Run after assets are added to the catalog |
| Semi-automated converter script | Reduce repetitive export work | Use only if Blockbench-led export is too slow or too fragile |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Curated offline import | Runtime mod-loader compatibility | Runtime compatibility is far more complex and does not match the current Godot architecture |
| Blockbench-assisted export | Custom Godot runtime Minecraft JSON parser | A runtime parser would still need to solve vanilla references, material mapping, and behavior gaps |
| Small curated pilot | Export every Tanuki Decor asset immediately | Bulk export hides legal and behavior problems until late and creates cleanup debt |

</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Intake Structure
```
source mod repo (read-only)
    -> verified metadata + dependency audit
    -> per-asset intake manifest
    -> conversion output (.glb / Godot scenes)
    -> existing imported-item catalog
    -> Item Studio tuning
    -> preview PNG generation
```

### Pattern 1: Asset Class Matrix First
**What:** Classify every candidate before conversion.
**When to use:** Immediately after auditing the upstream mod.

Suggested classes:
- `Class A` - static decorative props that can become ordinary Godot placeables
- `Class B` - assets that can work visually but need a Godot wrapper for interaction, animation, seating, lighting, or multiblock behavior
- `Class C` - assets whose value depends on Minecraft systems and should stay deferred

### Pattern 2: Provenance-Driven Intake
**What:** Every imported asset carries source metadata, credit, license, dependency notes, and conversion status.
**When to use:** Before adding any mod asset to the live repo.

Minimum manifest fields:
- `source_mod_id`
- `source_repo_url`
- `source_commit_or_tag`
- `license`
- `authors`
- `credits`
- `asset_id`
- `asset_class`
- `source_models`
- `source_textures`
- `vanilla_dependencies`
- `behavior_flags`
- `conversion_path`
- `target_scene_path`
- `catalog_item_id`
- `preview_image_path`
- `status`

### Pattern 3: Curated Pilot Through the Existing Catalog
**What:** Import a small set of low-risk assets through the same path already used by live imported scenes.
**When to use:** After the manifest and provenance rules exist.

Recommended pilot seed:
- `small_fancy_vase`
- `small_striped_vase`
- `blue_lamp`
- `birdcage`

Optional edge-case candidate:
- `rough_log_bench` because it references vanilla log textures and is useful for testing dependency detection

### Anti-Patterns to Avoid
- Treating "open-source mod" as permission to ignore art provenance or vanilla dependencies
- Treating all `967` model files as equally importable
- Building Godot support around raw mod-loader compatibility before the first asset pilot succeeds
- Allowing pilot assets into the catalog without preview, pivot, collision, and provenance checks

</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mod compatibility | NeoForge, Forge, or Fabric runtime bridge inside Godot | Offline asset intake plus selective Godot-side wrappers | Loader parity solves the wrong problem for this prototype |
| Large asset migration | Untracked one-by-one manual exports | Manifest-driven, curated workflow with optional semi-automation | Manual bulk work becomes unrepeatable and error-prone fast |
| Asset independence | "It is open-source, so everything is self-contained" | Explicit dependency scan for vanilla parents, textures, and render rules | Tanuki Decor uses Minecraft parents and some vanilla textures |
| Behavior parity | Direct port of recipes, menus, block entities, and storage logic | Reinterpret only the interactions that matter for this game | Most of that complexity has no value in the current room-builder baseline |

**Key insight:** The best support path is not "make Godot understand Minecraft mods." It is "make a safe, repeatable intake process for selected mod assets that fit the current Godot game."

</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Assuming the mod art is fully self-contained
**What goes wrong:** Converted assets silently miss parents, textures, or material rules.
**Why it happens:** Minecraft JSON models frequently inherit `minecraft:` parents and reference vanilla textures or render types.
**How to avoid:** Record every `minecraft:` parent and vanilla texture reference in the intake manifest before export.
**Warning signs:** Missing faces, wrong transparency, placeholder particles, or broken materials in Godot.

### Pitfall 2: Treating every asset as a simple mesh
**What goes wrong:** The repo fills with converted geometry that still does not represent the mod's meaningful behavior.
**Why it happens:** Tanuki Decor includes beds, clocks, block entities, storage, menus, multiblocks, and client renderers.
**How to avoid:** Classify content into `Class A`, `Class B`, and `Class C` first, and only pilot `Class A`.
**Warning signs:** Assets require custom rotation logic, paired placement, ticking, inventories, or separate rendered subparts.

### Pitfall 3: Losing provenance during import
**What goes wrong:** The repo gains imported assets with incomplete author, credit, or license traceability.
**Why it happens:** Conversion work often focuses on geometry first and documentation last.
**How to avoid:** Require provenance fields at manifest creation time, not after import.
**Warning signs:** Imported scenes exist without a clear source URL, author credit, or vanilla dependency note.

### Pitfall 4: Underestimating manual export cost
**What goes wrong:** The user ends up exporting dozens or hundreds of assets with no repeatable record.
**Why it happens:** Blockbench is good for inspection and spot export, but not as a complete undocumented migration strategy for a large mod.
**How to avoid:** Use Blockbench for pilot validation first, then decide whether semi-automation is worth it.
**Warning signs:** Export notes only exist in chat history or memory instead of repo files.

</common_pitfalls>

<code_examples>
## Data Examples

### Example Intake Manifest Record
```json
{
  "source_mod_id": "tanukidecor",
  "source_repo_url": "https://github.com/skyjay1/Tanuki-Decor",
  "source_branch": "dev",
  "license": "GNU LGPLv3",
  "authors": ["skyjay1"],
  "credits": ["Art by Skart2000", "NeoForge 1.21.1 update by Alex (CrabMods)"],
  "asset_id": "blue_lamp",
  "asset_class": "A",
  "source_models": [
    "assets/tanukidecor/models/block/blue_lamp/blue_lamp.json"
  ],
  "source_textures": [
    "assets/tanukidecor/textures/block/blue_lamp.png"
  ],
  "vanilla_dependencies": [],
  "behavior_flags": ["light_state"],
  "conversion_path": "blockbench_to_glb",
  "target_scene_path": "res://assets/placeables/mods/tanuki_decor/blue_lamp.glb",
  "catalog_item_id": "tanuki_blue_lamp",
  "preview_image_path": "res://assets/ui/item_previews/tanuki_blue_lamp.png",
  "status": "pilot_candidate"
}
```

### Example Catalog Metadata Extension
```gdscript
{
    "id": "tanuki_blue_lamp",
    "display_name": "Blue Lamp",
    "scene_path": "res://assets/placeables/mods/tanuki_decor/blue_lamp.glb",
    "source_mod_id": "tanukidecor",
    "source_asset_id": "blue_lamp",
    "asset_class": "A",
    "provenance_ref": "tanuki_decor_manifest.json#blue_lamp"
}
```

### Example Deferred Record
```json
{
  "asset_id": "slot_machine",
  "asset_class": "C",
  "status": "deferred",
  "deferred_reason": "Depends on block entity, custom renderer, and gameplay logic not wanted in the current room-builder phase"
}
```

</code_examples>

<sota_updates>
## State of the Art (2024-2026)

| Old assumption | Current practical approach | Impact |
|----------------|----------------------------|--------|
| "Support the mod" means loader compatibility | For cross-engine reuse, offline asset intake is the durable path | Better fit for Godot and for curated room-builder scope |
| Minecraft JSON can be treated like engine-native assets | Most non-Minecraft engines still want conversion into their native import formats | glTF is a better handoff into Godot than raw mod JSON |
| Open-source art imports are mostly a geometry task | Provenance, vanilla references, and behavior classification are first-order concerns | Intake metadata is mandatory, not optional polish |

**New patterns to consider:**
- Manifest-driven asset intake per source mod
- Curated-first pilot imports before any broad library migration
- Wrapper-by-need only for assets whose interaction matters in the target game

**Deprecated for this repo's needs:**
- Broad source-porting assumptions
- Large blind asset-pack imports with no provenance structure
- Loader-specific thinking before the asset pipeline itself is proven

</sota_updates>

<open_questions>
## Open Questions

1. **Can all desired pilot assets export cleanly through Blockbench without custom preprocessing?**
   - What we know: several models include Blockbench credits, which makes Blockbench a credible pilot tool
   - What's unclear: how many variant-heavy or parent-dependent assets need preprocessing to open/export cleanly
   - Recommendation: prove the path on `3-5` pilot assets before investing in automation

2. **What is the repo policy for vanilla Minecraft texture references at distribution time?**
   - What we know: Tanuki Decor models do reference vanilla parents and some vanilla textures
   - What's unclear: whether shipped Godot assets can legally include copied vanilla textures, or must substitute/omit them
   - Recommendation: block any public redistribution path that requires unreviewed vanilla content until legal packaging rules are explicit

3. **Which `Class B` assets are worth custom Godot wrappers after the pilot succeeds?**
   - What we know: seats, lamps, and some animated decor may map well to this game
   - What's unclear: whether interactive sets like clocks, display cases, or train sets add enough value to justify wrapper work
   - Recommendation: decide after the `Class A` pilot proves the intake contract and pipeline

</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- [Tanuki Decor repository](https://github.com/skyjay1/Tanuki-Decor) - upstream mod structure and assets
- [build.gradle](https://raw.githubusercontent.com/skyjay1/Tanuki-Decor/dev/build.gradle) - NeoForge plugin and dependency declarations
- [gradle.properties](https://raw.githubusercontent.com/skyjay1/Tanuki-Decor/dev/gradle.properties) - Minecraft version, mod license, authors, and credits
- [neoforge.mods.toml](https://raw.githubusercontent.com/skyjay1/Tanuki-Decor/dev/src/main/resources/META-INF/neoforge.mods.toml) - required dependencies on NeoForge and Minecraft
- Representative model files under `src/main/resources/assets/tanukidecor/models/` in the upstream repo - credits, parent references, render types, and vanilla texture references
- Representative Java packages under `src/main/java/tanukidecor/` in the upstream repo - block entities, menus, integrations, and behavior-heavy content classes

### Secondary (MEDIUM confidence)
- Local inspection of a temporary clone of the upstream repo on 2026-04-09 for counts and representative examples

### Tertiary (LOW confidence - needs validation)
- None

</sources>

<metadata>
## Metadata

**Research scope:**
- Source mod metadata and dependencies
- Resource counts and asset layout
- Vanilla Minecraft parent and texture references
- Behavior-heavy systems that block blind import
- Recommended Godot-side intake architecture

**Confidence breakdown:**
- Mod loader and dependency facts: HIGH - taken from upstream build and mod metadata files
- Asset structure and counts: HIGH - counted directly from the upstream resource tree
- Behavior classification: HIGH - based on upstream Java package and class structure
- Recommended pipeline: HIGH - grounded in the current Godot repo architecture and the upstream mod facts

**Research date:** 2026-04-09
**Valid until:** 2026-05-09

</metadata>

---

*Phase: 11-tanuki-decor-mod-asset-intake*
*Research completed: 2026-04-09*
*Ready for planning: yes*
