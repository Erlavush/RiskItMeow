# Requirements: Risk It Meow

**Defined:** 2026-04-02
**Core Value:** The player can smoothly walk around a cozy room in the browser and decorate it with reliable local-only building systems.

## v1 Requirements

### Controls

- [x] **CTRL-01**: Player moves with the current direct keyboard/mouse controller and room-view camera instead of a click-to-move system.

### Room View Camera

- [x] **CAM-01**: The game uses one stable room-view orbit camera aimed at the room center instead of the current freecam / third-person / first-person stack.
- [x] **CAM-02**: Camera orbit and zoom feel stable enough for gameplay and build mode, with no obvious shake during normal room use.

### Room Shell

- [x] **SHELL-01**: The Godot room has a floor, four walls, and a roof/ceiling that define a readable enclosed interior space.
- [x] **SHELL-02**: Camera-driven wall and roof occlusion keeps the room interior visible without breaking the shell structure.

### Placement

- [x] **PLAC-01**: Player can place floor furniture on a grid inside valid room bounds.
- [x] **PLAC-02**: Player can place wall furniture on all four walls with consistent wall targeting.
- [x] **PLAC-03**: Player can place ceiling or roof furniture on valid overhead surfaces.
- [x] **PLAC-04**: Player can place surface decor on valid support hosts using anchored local offsets.
- [x] **PLAC-05**: Placement logic distinguishes floor, wall, ceiling/roof, and surface-decor families instead of treating all items the same.

### Cats

- [x] **CATS-01**: Sample cats can be spawned or shown inside the room as part of the local sandbox slice.
- [x] **CATS-02**: Sample cats move or idle in a readable room-safe way without relying on backend or multiplayer systems.

### Presentation

- [ ] **VIS-01**: The room shell replaces the current plain white floor, walls, and ceiling with a themed material palette.
- [ ] **VIS-02**: The room adds trim, floor staging, and shell detailing so it no longer reads like a hollow white box.
- [ ] **VIS-03**: Lighting, backdrop, and occlusion tuning make the room readable and atmospheric while staying browser-friendly.

### Delivery

- [x] **PERF-01**: The local room-builder slice remains browser-first and performs reliably enough to justify using Godot for this foundation.
- [x] **SCOPE-01**: The milestone contains no Firebase, shared-room sync, couple joining, or backend-dependent flows.

## v2 Requirements

### Local Expansion

- **V2-01**: Add local inventory, shop, and persistence layers on top of the room-builder foundation.
- **V2-02**: Add richer local cat behavior, room interactions, and additional decor/content once the shell and placement systems are stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Firebase, auth, and backend sync | Explicitly removed from current target |
| Shared-room or couple-join gameplay | Explicitly removed from current target |
| Click-to-move locomotion | Rejected in favor of the existing movement system |
| Full parity with every shipped R3F system right now | Current milestone is intentionally narrowed to the local room-builder slice |
| Cat visual overhaul in Phase 2 | Explicitly deferred until after camera and room fidelity improve |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CTRL-01 | Phase 1 | Complete |
| CAM-01 | Phase 2 | Complete |
| CAM-02 | Phase 2 | Complete |
| SHELL-01 | Phase 1 | Complete |
| SHELL-02 | Phase 1 | Complete |
| PLAC-01 | Phase 1 | Complete |
| PLAC-02 | Phase 1 | Complete |
| PLAC-03 | Phase 1 | Complete |
| PLAC-04 | Phase 1 | Complete |
| PLAC-05 | Phase 1 | Complete |
| CATS-01 | Phase 1 | Complete |
| CATS-02 | Phase 1 | Complete |
| VIS-01 | Manual / TBD | Pending |
| VIS-02 | Manual / TBD | Pending |
| VIS-03 | Manual / TBD | Pending |
| PERF-01 | Phase 1 | Complete |
| SCOPE-01 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 17 total
- Mapped to phases: 14
- Unmapped: 3

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after removing the pending bundled Phase 2 follow-up plans*
