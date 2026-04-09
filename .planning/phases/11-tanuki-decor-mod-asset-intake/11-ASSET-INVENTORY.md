# Phase 11: Tanuki Decor Asset Inventory

## Verified Mod Facts

- Loader: `NeoForge`
- Minecraft version: `1.21.1`
- License: `GNU LGPLv3`
- Required runtime dependencies: `minecraft`, `neoforge`
- Optional integration found: `JEI`
- Verified resource counts:
  - `212` blockstates
  - `967` total model files
  - `213` item model files
  - `218` texture files

## What's Inside The Mod

### Content Families

| Family | Count | What it means |
|-------|------:|---------------|
| `misc` | 55 | Display props, machines, tables, tarps, decorative oddities |
| `storage` | 38 | Wardrobes, dressers, bookshelves, desks, cabinets |
| `clock` | 34 | Clocks, clock towers, dials, moving hands |
| `seat` | 30 | Chairs, benches, stools, sofas |
| `light` | 16 | Lamps, fireplaces, signs, glowing props |
| `entity` | 15 | Block entities and logic-heavy prop backends |
| `bed` | 14 | Beds and bed providers |

### Major Visual Themes

These are the dominant style families in the block model folder:

| Theme | Approx. Count | Examples |
|-------|--------------:|----------|
| `antique` | 17 | chair, desk, table, wardrobe, wall shelf |
| `gorgeous` | 12 | bed, chest, desk, lamp, sofa |
| `regal` | 12 | armoire, bed, chair, clock, table |
| `green` | 12 | bed, chair, clock, pantry, wardrobe |
| `blue` | 11 | bed, chair, clock, dresser, lamp |
| `minimalist` | 11 | bed, chair, couch, lamp, table |
| `sweets` | 10 | bed, bookcase, chair, sofa, wall lamp |
| `cabana` | 10 | armchair, bed, dresser, lamp, wardrobe |
| `wooden_block` | 9 | bed, bench, bookshelf, chair, clock |

### Reading The Mod Tree

- `blockstates/` tells you which model JSONs the placed block actually uses.
- `models/block/` contains the geometry you usually want for Blockbench export.
- `models/item/` mostly contains item wrappers and display transforms, not the best first place to start for placed-room assets.
- `textures/` holds the PNGs, but the texture file name does not always match the asset name.

## Starter Assets

Start in this order.

| Order | Asset | Why start here | Open this JSON first | Required texture PNGs |
|-------|-------|----------------|----------------------|-----------------------|
| 1 | `small_fancy_vase` | single model, single texture, no vanilla dependency | `src/main/resources/assets/tanukidecor/models/block/small_fancy_vase/small_fancy_vase.json` | `src/main/resources/assets/tanukidecor/textures/block/vase/small_fancy_vase.png` |
| 2 | `small_striped_vase` | same workflow as the first vase, easy repeat check | `src/main/resources/assets/tanukidecor/models/block/small_striped_vase/small_striped_vase.json` | `src/main/resources/assets/tanukidecor/textures/block/vase/small_striped_vase.png` |
| 3 | `blue_lamp` | still one model, but it proves whether you catch internal texture reuse | `src/main/resources/assets/tanukidecor/models/block/blue_lamp/blue_lamp.json` | `src/main/resources/assets/tanukidecor/textures/block/blue_dresser.png` |
| 4 | `birdcage` | good first multipart test after the simple props work | `src/main/resources/assets/tanukidecor/models/block/birdcage/display.json` | `src/main/resources/assets/tanukidecor/textures/block/birdcage.png` |

### Notes On The Starter Assets

- `small_fancy_vase` and `small_striped_vase` are the cleanest first exports because the texture path lives entirely inside the mod and the blockstate only points at one model.
- `blue_lamp` is easy geometry-wise, but it is useful because the model points at `tanukidecor:block/blue_dresser`, so it catches texture-name assumptions early.
- `birdcage` is the right next step once the vases and lamp work. Its `blockstates/birdcage.json` is multipart and the real in-world asset is split into `lower.json` and `upper.json`. `display.json` is easier if you want a single-file preview first.

## Do Not Start Here

| Asset | Why it is a bad first export target |
|-------|-------------------------------------|
| `rough_log_bench` | references vanilla `minecraft:block/oak_log` and `minecraft:block/oak_log_top` textures |
| `slot_machine` | uses block-entity-driven behavior and multiple moving parts |
| `train_set` | combines animated pieces and multiple display parts |
| `diy_workbench` | tied to menu and recipe systems that do not help the first art-export pass |
| `antique_wardrobe` | storage-oriented multi-state object, including empty or alternate state variants |
| `antique_bed` | bed placement and multi-block assembly are more complex than a simple decor prop |

If you want the process to stay easy, stick to `Class A` single-model decorative props first and only move to multipart or logic-heavy assets after that path is solid.
