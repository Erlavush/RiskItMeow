# Roadmap: Risk It Meow

## Milestones

- [ ] **v1.0 Local Room Builder Foundation** - Phase `1` ports the first local-only gameplay slice into Godot.

## Overview

Milestone v1.0 is intentionally narrow. It does not include Firebase, shared-room sync, partner presence, couple joining, or click-to-move controls. The milestone only targets the local room-builder slice: room shell, roof, wall/roof occlusion, grid placement across floor/wall/ceiling/surface layers, sample cats, and the current direct-movement camera baseline.

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
- [ ] 01-02: Build the grid placement and anchored decor systems
- [ ] 01-03: Add sample cats and integrate the local room-builder slice

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Local Room Shell, Placement, and Sample Cats | v1.0 | 1/3 | In Progress|  |
