---
created: 2026-04-10T08:59:31.126Z
title: Add furniture recolor and material variants
area: general
files:
  - scripts/placement/placement_inventory_catalog.gd
  - scripts/placement/imported_scene_placeable.gd
  - scripts/debug/debug_world_controller.gd
---

## Problem

The room can place curated items, but there is no lightweight way to offer colorways or material variants without duplicating entries in the catalog. That limits visual variety and makes it harder to build coherent room themes from a small prop set.

## Solution

Add a variant system that lets an item expose curated material, palette, or finish options such as wood tone, fabric color, metal finish, or plastic accent. Keep the first pass data-driven so variants stay tied to one item identity and one placement pipeline, with preview support and save-load persistence for the chosen variant.
