# Phase 1 Research: Source Parity Audit and Migration Blueprint

## Objective

Answer: "What do we need to know to plan this Godot port well before implementation begins?"

## Source Runtime Inventory

The shipped R3F runtime in `Z:\FAHHHH` is not just a room shell. Current implemented scope spans:

- room building with floor, wall, window, surface, and ceiling placement rules
- owned-vs-placed furniture inventory and coin economy
- separate player-shell surfaces for Inventory, Shop, and Pet Care
- world clock, sun/moon lighting, wall occlusion, and showcase/demo behavior
- room interactions such as sit, lie, stand, and desk use
- desk PC activity loops with persistence and reward logic
- multiple local cats, pet care rewards, and imported Better Cats visual variants
- shared memories, shared-room identity, backend sync, partner presence, edit locks, Together Days, and breakup reset
- developer-facing Preview Studio and Mob Lab authoring flows

## Source-of-Truth References

Use these as the primary behavior references during planning and implementation:

- `Z:\FAHHHH\README.md`
- `Z:\FAHHHH\docs\CURRENT_SYSTEMS.md`
- `Z:\FAHHHH\docs\ARCHITECTURE.md`
- `Z:\FAHHHH\docs\GAME_OVERVIEW.md`
- `Z:\FAHHHH\.planning\PROJECT.md`
- `Z:\FAHHHH\.planning\REQUIREMENTS.md`
- `Z:\FAHHHH\src\App.tsx`
- `Z:\FAHHHH\src\components\RoomView.tsx`
- `Z:\FAHHHH\tests\`

## Godot Target Starting Point

The current repo already provides:

- a Godot 4.6 project with `gl_compatibility` rendering and Jolt physics
- a playable `CharacterBody3D`-based movement controller
- freecam, third-person, and first-person camera modes
- a procedural Minecraft-style avatar rig with classic/slim support
- runtime skin loading UI
- a simple world scene and a few helper/editor scripts

What it does not yet provide is nearly all of the shipped gameplay, persistence, backend, tool, and content systems from the source runtime.

## Port Architecture Implications

### Runtime Structure

The source app centralizes orchestration in `src/App.tsx` and composes many hooks and scene modules. Godot should not mirror that file one-to-one. Instead, Phase 1 should recommend a scene-first structure:

- world scene composition for room, player, furniture, pets, lighting, and effects
- data/domain layer for room state, catalog, progression, pets, shared-room documents, and persistence
- player shell/UI layer for HUD, drawers, dialogs, and overlays
- shared-room service layer for auth, canonical room sync, presence, and conflict recovery
- tooling layer for authoring workflows such as preview capture and imported-mob tuning

### Data Model Strategy

The port must preserve source runtime invariants:

- `ownedFurniture` must stay distinct from placed room furniture
- surface decor must keep stable host anchors and local offsets
- wall placement must keep four-wall semantics
- canonical shared-room state must stay separate from ephemeral presence/locks
- authoring data must stay separate from live room runtime data

Godot can change implementation details, but it should not collapse or blur those models.

### Browser/Backend Strategy

The hardest migration area is not rendering. It is shared-room browser behavior:

- Godot web export still has to authenticate users and talk to a hosted backend
- live presence and edit locks are likely better represented through explicit service adapters rather than scene logic
- file-picker and authoring flows from the source browser app may need platform-specific handling in Godot web
- final architecture may require a mix of HTTP/WebSocket/JavaScript bridge patterns depending on what Firebase parity is feasible from Godot web

Phase 1 must make that strategy explicit instead of assuming direct API parity.

## Main Port Risks

- Source scope is much larger than the current Godot base, so "just start porting" will create hidden omissions.
- Shared-room auth/sync/presence may be the highest technical risk for Godot web.
- Developer tooling parity may not belong entirely inside the game runtime; Phase 1 must decide whether some tools remain external.
- Asset and content volume are large enough that catalog/import strategy must be data-driven early.
- Browser performance gains need measurement, not assumption, or the engine move will lack proof.

## Recommended Phase 1 Outputs

Phase 1 should produce:

- a feature parity matrix
- a source ownership map with file/test references
- a risk register for browser, backend, content, and authoring concerns
- a Godot target architecture map
- a data and asset migration plan
- an implementation execution checklist for phases 2 through 10
- a parity verification harness tying source docs/tests/manual UAT to Godot checks

## Verification Architecture

Godot parity should be verified through three layers:

1. Source behavior references
   - docs, README, source planning docs, and current tests define expected behavior
2. Godot implementation checks
   - scene/manual UAT checklists, targeted script tests where feasible, and artifact verification
3. Browser performance baselines
   - startup stability, interaction responsiveness, and representative frame-rate observations against the current R3F pain points

## Planning Recommendation

Phase 1 should stay documentation-first and execution-oriented. The best next move is not porting a random subsystem; it is locking the source feature inventory, migration seams, backend strategy, and verification approach so implementation phases can move quickly without drifting away from source parity.
