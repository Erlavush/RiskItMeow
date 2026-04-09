# Roadmap: Risk It Meow

## Milestones

- [ ] **v1.0 Manual Feature Buildout** - Continue from the current Godot room-building baseline through direct user-requested features.

## Overview

This repo no longer follows a source-porting roadmap. The current prototype baseline includes a player, an `8x8` room shell with four walls and a roof, an orbit room camera, a first-person camera mode, a placement system, a camera-driven cutaway system, a developer environment panel, an inventory/shop browser, and a dedicated debug Item Studio.

**Execution guardrails:**
- Do not assume source-project parity work.
- Do not add backend, multiplayer, shared-room, or couple systems.
- Do not continue old bundled phase plans unless the user explicitly asks to start structured planning again.

## Current Baseline

- Active scene: player + `8x8` room shell + orbit room camera + first-person mode + placement system + cutaway controller + developer environment panel + debug Item Studio
- The room shell uses four walls and a roof, with runtime cutaway hiding camera-facing shell surfaces
- Placement supports Build/Edit modes, move/duplicate/delete, save/load/clear, wall windows with real cutouts, and local persistence
- The placement UI uses Inventory/Shop browsing with category tabs, cached PNG preview cards, owned stock counts, and free unlimited buying
- The live runtime catalog is a curated `7`-item imported-item set rather than a scanned household-pack catalog
- `assets/ui/item_previews` currently contains `7` cached preview PNGs used by the browser UI
- Room layouts persist locally and restore placed furniture, owned inventory stock, and floor finish on startup
- The editor 3D preview mirrors the last locally saved room layout and developer-environment preset
- The developer environment panel includes Morning, Noon, Sunset, and Afternoon Cozy presets
- The inventory includes wall-mounted windows, and the room shell rebuilds wall segments around window openings at runtime
- Wall cutaway is render-only, so room shadows and collisions stay intact while the interior is visible
- Sun-facing windows add lightweight fake interior sunlight so rooms stay readable without real-time GI

## Current Stability Notes

- Browser previews are now stabilized by pre-generated PNG thumbnails instead of runtime live 3D mini-scenes.
- The live catalog is small and curated, but individual item tuning is still an ongoing polish area.
- The `temporary/` directory is intentionally ignored by Godot scanning to prevent duplicate UID warnings while preserving legacy import dependencies.

## Phases

Phase numbering intentionally starts at `11` by explicit user request.

### Phase 11: Tanuki Decor Mod Asset Intake Strategy

**Goal:** Define a legally safe and technically repeatable intake pipeline for bringing selected Tanuki Decor assets, and later similar open-source Minecraft mod assets, into the current Godot placement/catalog workflow without adding runtime mod-loader compatibility.

**Requirements:**
- `MOD-11-01` Inventory Tanuki Decor's loader, license, dependency, asset-count, vanilla-reference, and behavior surface from verified source files instead of assumptions.
- `MOD-11-02` Define intake metadata and provenance rules for source repo URL, commit, authors, credits, license, vanilla dependencies, conversion status, and Godot target paths.
- `MOD-11-03` Choose and document a repeatable conversion path for Class A decorative assets from Minecraft JSON and Blockbench into Godot-importable glTF or scene assets.
- `MOD-11-04` Classify assets into static props, wrapper candidates, and deferred system-dependent content, and explicitly exclude runtime NeoForge, Forge, and Fabric compatibility from this phase.
- `MOD-11-05` Define a curated pilot batch and validation criteria for importing representative Tanuki Decor assets into the existing placement catalog, Item Studio, and preview-generation workflow.

**Depends on:** Current curated imported-item placement pipeline, Item Studio tuning workflow, preview-generation tooling, and third-party provenance tracking.

**Plans:**
- `11-01-PLAN.md` - Define the intake contract, validate the Tanuki Decor pilot workflow, and formalize what stays deferred.

**Artifacts:**
- `.planning/phases/11-tanuki-decor-mod-asset-intake/11-CONTEXT.md`
- `.planning/phases/11-tanuki-decor-mod-asset-intake/11-RESEARCH.md`
- `.planning/phases/11-tanuki-decor-mod-asset-intake/11-01-PLAN.md`

## Next Step

Either execute Phase 11 when the user wants to start the Tanuki Decor intake pilot, or continue with another direct feature request from the current Godot baseline.

---
*Last updated: 2026-04-09 after adding Phase 11 Tanuki Decor intake planning*
