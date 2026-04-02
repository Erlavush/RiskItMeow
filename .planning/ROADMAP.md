# Roadmap: Risk It Meow: Godot Port

## Milestones

- [ ] **v1.0 Feature-Parity Port** - Phases `1` through `10` establish parity with the currently shipped R3F runtime in `Z:\FAHHHH` while moving the browser runtime to Godot.

## Overview

Milestone v1.0 ports the existing React Three Fiber game to Godot in phased layers instead of attempting a blind full rewrite. The first phase is intentionally documentation-heavy: it inventories the source runtime, defines migration architecture, and creates parity verification baselines before the implementation phases begin.

**Execution guardrail:** Every implementation phase must preserve source runtime invariants and carry explicit parity verification against the shipped R3F experience.

## Phases

### Phase 1: Source Parity Audit and Migration Blueprint
**Goal**: Produce an exhaustive feature inventory, migration architecture, asset/data mapping, and parity verification baseline for porting the shipped R3F runtime into Godot.
**Depends on**: Existing Godot prototype
**Requirements**: [PLAN-01, PLAN-02]
**UI hint**: no
**Success Criteria**:
  1. A parity matrix exists for shipped gameplay, UI, data, backend, tools, assets, and tests from `Z:\FAHHHH`.
  2. Godot target architecture and migration boundaries are defined for runtime, shared-room, tooling, and content systems.
  3. The remaining port work is broken into dependency-ordered implementation phases with explicit parity gates.
**Plans**: 3 plans

Plans:
- [ ] 01-01: Audit the source runtime and build the parity matrix
- [ ] 01-02: Define Godot target architecture, data migration, and asset pipeline decisions
- [ ] 01-03: Define execution backlog, parity gates, and verification harness

### Phase 2: Godot Runtime Foundation and Avatar Controls
**Goal**: Turn the current Godot prototype into a browser-targeted runtime foundation with player movement, camera, avatar, and skin parity as the base for later systems.
**Depends on**: Phase 1
**Requirements**: [CORE-01, CORE-02, CORE-03]
**UI hint**: yes
**Success Criteria**:
  1. The Godot runtime boots as the primary room scene and no longer behaves like a throwaway prototype.
  2. Avatar movement, camera behavior, and skin flows match the currently shipped experience closely enough to serve as the port foundation.
  3. Browser-targeted runtime constraints and baseline profiling are captured for later optimization work.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Stand up the Godot web-runtime scaffold and scene boot path
- [ ] 02-02: Port avatar movement, camera modes, and skin behavior
- [ ] 02-03: Establish browser-safe input, runtime settings, and baseline profiling

### Phase 3: Data Model, Catalog, and Local Persistence Backbone
**Goal**: Recreate the source game's room data model, catalog metadata, and local persistence backbone inside Godot so later port phases do not invent incompatible state shapes.
**Depends on**: Phase 2
**Requirements**: [DATA-01, CONT-01]
**UI hint**: no
**Success Criteria**:
  1. Godot has canonical room, ownership, placement, pet, and settings data models aligned with the source runtime.
  2. The current shipped catalog can be represented in the Godot content pipeline with stable identifiers and metadata.
  3. Local/browser-facing persistence survives reloads without breaking migration assumptions for later shared-room work.
**Plans**: 3 plans

Plans:
- [ ] 03-01: Port room-state, ownership, and persistence contracts
- [ ] 03-02: Build catalog/content import structures for furniture, pets, and variants
- [ ] 03-03: Validate state migration, persistence, and content IDs against source behavior

### Phase 4: Room Builder and Placement Parity
**Goal**: Port the room-editing systems so floor, wall, window, surface, and ceiling placement behavior matches the shipped source runtime.
**Depends on**: Phase 3
**Requirements**: [BLDR-01, BLDR-02, BLDR-03, BLDR-04, BLDR-05]
**UI hint**: yes
**Success Criteria**:
  1. Floor, wall, window, surface, and ceiling placement flows work with the same core invariants as the source game.
  2. Confirm/cancel/store/nudge/rotate/edit interactions behave predictably and support the current build-mode workflows.
  3. Window openings and anchored surface decor survive edit and save/load cycles.
**Plans**: 3 plans

Plans:
- [ ] 04-01: Port floor and wall placement/editor interactions
- [ ] 04-02: Port window openings, wall transitions, and ceiling placement
- [ ] 04-03: Port anchored surface decor and placement validation

### Phase 5: Player Shell, Economy, and World Presentation
**Goal**: Port the player-facing shell, commerce flows, world clock, and room presentation so the Godot runtime feels like the shipped game instead of only an editor shell.
**Depends on**: Phase 4
**Requirements**: [SHELL-01, ECON-01, ECON-02, ECON-03, WRLD-01, WRLD-02, SHOW-01]
**UI hint**: yes
**Success Criteria**:
  1. Inventory, Shop, and Pet Care flows exist in a Godot player shell with readable HUD and details surfaces.
  2. Economy and wallet behaviors match current buy/place/store/sell expectations.
  3. World clock, lighting readability, occlusion, and showcase/demo mode are available in the Godot runtime.
**Plans**: 4 plans

Plans:
- [ ] 05-01: Port player shell HUD, room details, and drawer navigation
- [ ] 05-02: Port economy flows for inventory, shop, and wallet behavior
- [ ] 05-03: Port world clock, lighting, and room readability systems
- [ ] 05-04: Create local showcase/demo mode without backend dependency

### Phase 6: Room Interactions and Desk Activities
**Goal**: Port the gameplay interactions and activity earn loops that give the room moment-to-moment use beyond decoration.
**Depends on**: Phase 5
**Requirements**: [INTR-01, ACTV-01, ACTV-02]
**UI hint**: yes
**Success Criteria**:
  1. Sit, lie, stand, and desk interaction flows work from the Godot room scene.
  2. The current desk PC activities support scoring, payouts, cooldowns, and persistence behavior.
  3. Cozy-rest / ritual reward flows are represented at the same functional level as the shipped runtime.
**Plans**: 3 plans

Plans:
- [ ] 06-01: Port interaction targeting and player approach/pose flows
- [ ] 06-02: Port desk PC activity runtime and persistence
- [ ] 06-03: Port ritual/cozy-rest reward integration into shell and progression state

### Phase 7: Pets, Cat Variants, and Memories
**Goal**: Port the pet, cat-care, variant, and shared-memory systems that make the room feel personal and alive.
**Depends on**: Phase 6
**Requirements**: [PETS-01, PETS-02, MEMR-01]
**UI hint**: yes
**Success Criteria**:
  1. The Godot runtime supports the current local pet/cat roster behaviors and persistence model.
  2. Cat-care rewards and imported visual variant support are preserved.
  3. Shared memory frame / collection behavior exists with editing and persistence hooks.
**Plans**: 3 plans

Plans:
- [ ] 07-01: Port live-room pet and multi-cat runtime behaviors
- [ ] 07-02: Port cat-care rewards and visual variant support
- [ ] 07-03: Port memory frame/collection runtime and shell integration

### Phase 8: Shared Room Identity and Canonical Sync
**Goal**: Port the hosted shared-room identity and canonical room-sync foundation so Godot can own the same couple-room model as the source runtime.
**Depends on**: Phase 7
**Requirements**: [SHRD-01, SHRD-02]
**UI hint**: yes
**Success Criteria**:
  1. Couple identity, pairing, and room re-entry flows work from the Godot runtime.
  2. Canonical shared-room state syncs room edits, progression, memories, and shared pet data without corrupting ownership or placement invariants.
  3. Godot-side backend seams are explicit enough to support browser deployment and later maintenance.
**Plans**: 3 plans

Plans:
- [ ] 08-01: Port identity, linking, and room-entry flows
- [ ] 08-02: Port canonical shared-room document sync and mutation flows
- [ ] 08-03: Validate shared-room schema parity and reconnect behavior

### Phase 9: Live Presence, Couple Progression, and Breakup Stakes
**Goal**: Port the real-time co-op layer and emotional-stakes systems that make the room feel shared rather than merely synchronized.
**Depends on**: Phase 8
**Requirements**: [SHRD-03, SHRD-04]
**UI hint**: yes
**Success Criteria**:
  1. Remote avatar presence, partner status UX, and same-item edit conflict handling work in real time.
  2. Together Days, activity claim state, and couple progression remain legible and persistent.
  3. Breakup reset stakes work safely through the Godot shared-room mutation flow.
**Plans**: 3 plans

Plans:
- [ ] 09-01: Port live partner presence and remote-avatar playback
- [ ] 09-02: Port Together Days and shared progression flows
- [ ] 09-03: Port breakup reset, conflict recovery, and relationship-stakes UX

### Phase 10: Authoring Tool Parity and Performance Hardening
**Goal**: Restore the source runtime's authoring capabilities and finish the browser-performance work that justifies the migration.
**Depends on**: Phase 9
**Requirements**: [TOOL-01, PERF-01]
**UI hint**: yes
**Success Criteria**:
  1. Preview Studio / Mob Lab equivalent tooling exists for ongoing content iteration after the port.
  2. Browser-targeted Godot performance and stability are measurably better than the current R3F runtime on target devices.
  3. Final parity validation confirms the Godot build can replace the source runtime for currently shipped features.
**Plans**: 3 plans

Plans:
- [ ] 10-01: Port Preview Studio and Mob Lab equivalent workflows
- [ ] 10-02: Run browser performance hardening and profiling passes
- [ ] 10-03: Execute final parity verification and replacement readiness audit

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Source Parity Audit and Migration Blueprint | v1.0 | 0/3 | Not started | - |
| 2. Godot Runtime Foundation and Avatar Controls | v1.0 | 0/3 | Not started | - |
| 3. Data Model, Catalog, and Local Persistence Backbone | v1.0 | 0/3 | Not started | - |
| 4. Room Builder and Placement Parity | v1.0 | 0/3 | Not started | - |
| 5. Player Shell, Economy, and World Presentation | v1.0 | 0/4 | Not started | - |
| 6. Room Interactions and Desk Activities | v1.0 | 0/3 | Not started | - |
| 7. Pets, Cat Variants, and Memories | v1.0 | 0/3 | Not started | - |
| 8. Shared Room Identity and Canonical Sync | v1.0 | 0/3 | Not started | - |
| 9. Live Presence, Couple Progression, and Breakup Stakes | v1.0 | 0/3 | Not started | - |
| 10. Authoring Tool Parity and Performance Hardening | v1.0 | 0/3 | Not started | - |
