---
created: 2026-04-10T08:01:21.500Z
title: Add ambient Minecraft-style cat companions
area: general
files:
  - scenes/main.tscn
  - scripts/player.gd
  - scripts/MinecraftRig.gd
---

## Problem

The user wants Minecraft-style cats in the room-builder prototype, but the current runtime has no ambient creature actor, pet AI loop, or reusable interaction layer for non-player companions. If this is approached as strict source-project parity, it will sprawl into asset-provenance, animation, behavior, and interaction work without a room-scale design target.

## Solution

Treat this as a cozy local companion feature instead of a parity port. Start with one lightweight cat actor that can idle, wander within room bounds, sit or sleep on valid room spots, notice the player, and support curated visual variants later. Keep the first pass room-scale and offline, and resolve asset provenance before importing any cat model or texture set.
