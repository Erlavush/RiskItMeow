# Agent Guide

Use `CLAUDE.md` as the generated project guidance source for this repo.

## GSD Workflow

- Start substantial work through a GSD workflow so `.planning/` artifacts stay in sync.
- Use `$gsd-quick` for small targeted changes.
- Use `$gsd-debug` for investigations and bug fixing.
- Use `$gsd-execute-phase <n>` for planned phase execution.

## Project Focus

- This repo currently targets a local-only Godot room-builder slice.
- Do not add Firebase, shared-room sync, partner presence, couple joins, or other backend-dependent systems unless the user explicitly restores that scope.
- Do not reintroduce click-to-move; preserve the current direct keyboard/mouse movement and camera modes.
- Use `Z:\FAHHHH` only as a reference for the local room shell, wall/roof occlusion, floor/wall/ceiling/surface placement, and sample cat behavior that matter to Phase 1.
