# Roadmap: Risk It Meow

## Milestones

- [ ] **v1.0 Local Room Builder Foundation** - Phases `1` and `2` establish the local room sandbox, then stabilize the room-view camera and presentation.

## Overview

Milestone v1.0 is intentionally narrow. It does not include Firebase, shared-room sync, partner presence, couple joining, or click-to-move controls. The milestone now targets two local-only slices: Phase 1 delivered the first room-builder foundation, and Phase 2 upgrades that foundation with the `FAHHHH` room-view camera model plus a presentable themed room shell.

**Execution guardrail:** Any implementation that drifts into backend, multiplayer, or couple systems is out of scope for this milestone.

## Phases

### Phase 1: Local Room Shell, Placement, and Sample Cats
**Goal**: Build the first usable local room-builder slice in Godot with shell geometry, occlusion, grid placement, anchored surface decor, and sample cats while preserving the current direct player controls.
**Depends on**: Existing Godot prototype
**Requirements**: [CTRL-01, SHELL-01, SHELL-02, PLAC-01, PLAC-02, PLAC-03, PLAC-04, PLAC-05, CATS-01, CATS-02, PERF-01, SCOPE-01]
**UI hint**: yes
**Success Criteria**:
  1. The main Godot scene contains a usable room shell with floor, four walls, and roof/ceiling geometry.
  2. Camera-driven occlusion can hide or peel the necessary walls/roof to keep the room interior visible.
  3. Grid-based build placement works for floor, wall, ceiling/roof, and anchored surface decor items.
  4. Sample cats are visible in the room and behave in a readable local-only way.
  5. Player control remains based on the existing direct movement/camera system and no click-to-move flow is introduced.
**Plans**: 3 plans

Plans:
- [x] 01-01: Build the enclosed room shell and camera occlusion foundation
- [x] 01-02: Build the grid placement and anchored decor systems
- [x] 01-03: Add sample cats and integrate the local room-builder slice

### Phase 2: Room-View Camera and Visual Fidelity
**Goal**: Replace the current shaky multi-camera prototype with the single room-view orbit camera from `FAHHHH`, then upgrade the room shell from a plain white box into a themed, readable starter room while preserving local-only scope and direct movement.
**Depends on**: Phase 1
**Requirements**: [CTRL-01, CAM-01, CAM-02, VIS-01, VIS-02, VIS-03, PERF-01, SCOPE-01]
**UI hint**: yes
**Success Criteria**:
  1. The runtime uses one stable room-centered orbit camera instead of freecam / third-person / first-person switching.
  2. Build mode, occlusion, and player control remain usable with the new camera baseline and no click-to-move is introduced.
  3. The room shell no longer reads as a plain hollow white box and instead uses a themed floor, wall, ceiling, and trim presentation.
  4. Lighting and atmosphere give the room readable depth while staying browser-friendly.
  5. Cat redesign work remains explicitly deferred so the phase stays focused on camera and room fidelity.
**Plans**: 3 plans

Plans:
- [x] 02-01: Replace the current camera stack with a stable room-view orbit camera
- [ ] 02-02: Upgrade the room shell from white-box prototype to themed starter room
- [ ] 02-03: Retune lighting, occlusion, and verification around the new room view

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Local Room Shell, Placement, and Sample Cats | v1.0 | 3/3 | Complete   | 2026-04-02 |
| 2. Room-View Camera and Visual Fidelity | v1.0 | 0/3 | Pending    |  |
