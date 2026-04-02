# Requirements: Risk It Meow: Godot Port

**Defined:** 2026-04-02
**Core Value:** The Godot runtime can deliver the current cozy shared-room experience with better browser performance and no meaningful regressions from the shipped R3F game.

## v1 Requirements

### Planning and Migration

- [ ] **PLAN-01**: Team has a verified parity inventory mapping the shipped R3F runtime's current gameplay, UI, persistence, backend, tools, assets, and tests into port scope.
- [ ] **PLAN-02**: Team has a Godot migration architecture and phased implementation plan that maps every v1 requirement to executable phases before deep implementation starts.

### Core Runtime

- [ ] **CORE-01**: Player can boot the Godot web runtime directly into the current room experience without relying on the React runtime.
- [ ] **CORE-02**: Player can move a Minecraft-style avatar around the room and use the supported camera modes equivalent to the current runtime.
- [ ] **CORE-03**: Player can import or select Minecraft-compatible avatar skins in the Godot runtime.

### Data and Content Backbone

- [ ] **DATA-01**: Local room data, camera/player state, wallet/minigame state, pets, and world settings persist across browser sessions in the Godot runtime.
- [ ] **CONT-01**: The current shipped furniture, decor, windows, pets, variants, and content metadata catalog can be represented in the Godot content pipeline.

### Room Builder

- [ ] **BLDR-01**: Player can enter build mode and place, drag, rotate, nudge, confirm, cancel, and store floor furniture within room bounds.
- [ ] **BLDR-02**: Player can place and edit wall furniture on all four walls, including drag-across-corner flows and explicit wall swaps.
- [ ] **BLDR-03**: Player can place windows that carve real wall openings and restore the wall when removed.
- [ ] **BLDR-04**: Player can place anchored surface decor on valid host furniture and keep anchors intact when the host moves or rotates.
- [ ] **BLDR-05**: Player can place the currently supported ceiling fixtures/decor in the Godot room runtime.

### Player Shell and Economy

- [ ] **SHELL-01**: Player-facing HUD, clock, companion/status surfaces, room details, and drawer flows remain available in the Godot port.
- [ ] **ECON-01**: Player can browse separate Inventory, Shop, and Pet Care surfaces inside the player shell.
- [ ] **ECON-02**: Player can buy, own, place, store, and sell catalog items while preserving the source game's owned-vs-placed furniture model.
- [ ] **ECON-03**: Player can earn and spend coins and keep progression-related wallet state across sessions.

### Activities and Interactions

- [ ] **INTR-01**: Player can trigger the current room interactions such as sit, lie down, stand up, and desk use from the Godot room scene.
- [ ] **ACTV-01**: Player can play the current desk PC activity suite with score, payout, cooldown, and persistence behavior.
- [ ] **ACTV-02**: Player can access the current cozy-rest / ritual reward behaviors that are already shipped in the source runtime.

### World and Presentation

- [ ] **WRLD-01**: Player can use the current world clock modes and Godot-equivalent sun/moon lighting presentation.
- [ ] **WRLD-02**: Camera-driven wall occlusion and interior readability work without breaking room lighting or shadows.
- [ ] **SHOW-01**: A deployable single-player showcase/demo mode exists without requiring backend configuration.

### Pets and Memories

- [ ] **PETS-01**: Player can adopt and persist the current live-room pet set, including the current multi-cat local showcase behavior.
- [ ] **PETS-02**: Cats retain current care rewards, readable room-life behavior, and imported visual variant support.
- [ ] **MEMR-01**: Couple can view, edit, and persist the current shared memory frame / memory collection features.

### Shared Room

- [ ] **SHRD-01**: Couple can authenticate or reclaim identity, pair into one shared room, and re-enter it across browsers or devices.
- [ ] **SHRD-02**: Canonical shared-room state synchronizes room edits, ownership, progression, memories, and shared pet data without silent drift.
- [ ] **SHRD-03**: Live partner presence covers remote avatar transforms, join/reconnect states, and same-item edit conflict handling.
- [ ] **SHRD-04**: Couple progression supports Together Days, activity claim status, and the current breakup reset stakes.

### Tools and Delivery

- [ ] **TOOL-01**: Developer-facing Preview Studio and Mob Lab equivalent workflows exist for ongoing content, preview, and pet-variant iteration.
- [ ] **PERF-01**: The Godot web runtime is measurably more stable or responsive than the current R3F build on the intended browser targets.

## v2 Requirements

### Expansion

- **V2-01**: After parity, the Godot port can add new gameplay systems beyond the currently shipped R3F runtime.
- **V2-02**: After parity, the Godot port can revisit mobile-specific controls and packaging beyond browser-first delivery.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Net-new features not already shipped in the source runtime | This project is a parity port first, not a sequel roadmap |
| Long-term dual-engine support | The migration target is Godot as primary runtime |
| Native mobile app packaging as part of initial port scope | Browser-first delivery is the immediate problem and target |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAN-01 | Phase 1 | Pending |
| PLAN-02 | Phase 1 | Pending |
| CORE-01 | Phase 2 | Pending |
| CORE-02 | Phase 2 | Pending |
| CORE-03 | Phase 2 | Pending |
| DATA-01 | Phase 3 | Pending |
| CONT-01 | Phase 3 | Pending |
| BLDR-01 | Phase 4 | Pending |
| BLDR-02 | Phase 4 | Pending |
| BLDR-03 | Phase 4 | Pending |
| BLDR-04 | Phase 4 | Pending |
| BLDR-05 | Phase 4 | Pending |
| SHELL-01 | Phase 5 | Pending |
| ECON-01 | Phase 5 | Pending |
| ECON-02 | Phase 5 | Pending |
| ECON-03 | Phase 5 | Pending |
| WRLD-01 | Phase 5 | Pending |
| WRLD-02 | Phase 5 | Pending |
| SHOW-01 | Phase 5 | Pending |
| INTR-01 | Phase 6 | Pending |
| ACTV-01 | Phase 6 | Pending |
| ACTV-02 | Phase 6 | Pending |
| PETS-01 | Phase 7 | Pending |
| PETS-02 | Phase 7 | Pending |
| MEMR-01 | Phase 7 | Pending |
| SHRD-01 | Phase 8 | Pending |
| SHRD-02 | Phase 8 | Pending |
| SHRD-03 | Phase 9 | Pending |
| SHRD-04 | Phase 9 | Pending |
| TOOL-01 | Phase 10 | Pending |
| PERF-01 | Phase 10 | Pending |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after initial definition*
