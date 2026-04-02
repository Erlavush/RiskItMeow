# Risk It Meow: Godot Port

## What This Is

Risk It Meow is the Godot port of the currently shipped React Three Fiber game in `Z:\FAHHHH` (`Risk It All: Cozy Couple Room`). The goal is to reproduce the existing room-building, shared-room, pet, memory, activity, and authoring experience in a Godot runtime that is more stable and responsive in the browser than the current R3F stack.

## Core Value

The Godot runtime can deliver the current cozy shared-room experience with better browser performance and no meaningful regressions from the shipped R3F game.

## Requirements

### Validated

- [x] Player can move through a simple 3D Godot room prototype with freecam, third-person, and first-person camera modes. - existing prototype
- [x] Player can render a Minecraft-style avatar, switch classic/slim body models, and import a `64x64` skin at runtime. - existing prototype
- [x] The Godot project can boot a lit prototype world with a small runtime UI and editor utility scripts. - existing prototype

### Active

- [ ] Godot reaches parity with the currently shipped R3F runtime in `Z:\FAHHHH`, including room editing, inventory/shop flows, interactions, desk activities, pets/cat care, memories, shared-room sync, progression, and breakup stakes.
- [ ] The Godot port preserves the current content-authoring workflows needed to maintain furniture, cats, variants, and room content after the runtime transition.
- [ ] The Godot web target becomes the primary browser delivery path and materially improves runtime stability and responsiveness compared with the current R3F build.
- [ ] Port work stays phase-driven: Phase 1 exhaustively audits the source runtime and defines migration architecture before deep implementation starts.

### Out of Scope

- Net-new gameplay beyond features already shipped in the current R3F runtime - parity comes before expansion.
- Keeping React Three Fiber as a long-term runtime fallback - the target is a real runtime migration, not a dual-engine product.
- Native mobile clients - this effort is focused on the browser-delivered Godot port first.

## Context

- The source game in `Z:\FAHHHH` already ships a much larger feature set than this repo's current Godot prototype. Source-of-truth feature inventories currently live in `Z:\FAHHHH\README.md`, `Z:\FAHHHH\docs\CURRENT_SYSTEMS.md`, `Z:\FAHHHH\docs\GAME_OVERVIEW.md`, `Z:\FAHHHH\docs\ARCHITECTURE.md`, and the source repo's `.planning` docs.
- The source runtime already includes build-mode room editing, separate inventory/shop/pet-care flows, owned-vs-placed furniture invariants, desk PC activities, world clock and lighting controls, multiple local cats, shared memories, shared-room identity and sync, partner presence, Together Days, breakup reset, and developer-facing authoring surfaces.
- The current Godot repo only contains an early prototype: player movement, camera modes, a procedural Minecraft-style avatar rig, runtime skin import, and a simple world scene.
- The migration is motivated by browser performance and stability problems in the current R3F/Three.js build.
- The source repo also contains detailed tests and GSD planning artifacts that can be used as migration references instead of rediscovering behavior from scratch.

## Constraints

- **Platform**: Browser-first Godot delivery - the port must stay viable for web export because that is the reason for the engine move.
- **Parity baseline**: The shipped runtime in `Z:\FAHHHH` is the feature baseline - not future roadmap ideas and not stale prototypes.
- **Architecture**: Preserve core domain invariants from the source game, especially owned-vs-placed furniture, anchored surface decor, four-wall placement, canonical shared-room state, and authoring/runtime boundaries.
- **Migration strategy**: Use phased delivery with explicit parity checkpoints - rewriting blindly would create regressions faster than it creates value.
- **Performance**: The Godot port must outperform or out-stabilize the current R3F runtime on the target browsers/devices - a same-performance port is not enough.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat this repo as a brownfield Godot prototype, not a greenfield game | The project already has working Godot movement, avatar, and scene foundations worth preserving | - Pending |
| Use the shipped R3F runtime in `Z:\FAHHHH` as the parity baseline | The source game already has a much broader implemented feature set than the Godot prototype | - Pending |
| Make Phase 1 a planning and migration-blueprint phase | The scope is too large to start implementation without an exact feature inventory and architecture map | - Pending |
| Preserve source gameplay/data concepts even if the engine architecture changes | A port should not silently change ownership, sync, or progression semantics | - Pending |
| Optimize for browser-ready Godot delivery instead of maintaining both engines long-term | The engine move is driven by browser lag and runtime instability in the current R3F build | - Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-02 after project initialization*
