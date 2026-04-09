# Phase 11: Tanuki Decor Blockbench Guide

## Folder Setup

1. Clone or download the Tanuki Decor repo and keep the original resource-pack-style folder layout intact.
2. Do not move the model JSON away from its sibling texture tree if you want texture resolution to be easy.
3. The minimum structure you want to preserve is:

```text
src/main/resources/assets/tanukidecor/
  blockstates/
  models/
  textures/
```

4. In Blockbench, open the actual model JSON from `models/block/...`.
5. If Blockbench asks what format the file is, choose the Java Block/Item model format.
6. If textures do not auto-resolve, keep the same folder structure and manually attach the PNGs listed below.

## Path Mapping Rule

Use this rule every time you see a texture reference inside a model JSON:

```text
tanukidecor:block/foo/bar
-> src/main/resources/assets/tanukidecor/textures/block/foo/bar.png
```

Examples:

- `tanukidecor:block/vase/small_fancy_vase`
  -> `src/main/resources/assets/tanukidecor/textures/block/vase/small_fancy_vase.png`
- `tanukidecor:block/birdcage`
  -> `src/main/resources/assets/tanukidecor/textures/block/birdcage.png`
- `tanukidecor:block/blue_dresser`
  -> `src/main/resources/assets/tanukidecor/textures/block/blue_dresser.png`

If the model uses a `minecraft:block/...` or `minecraft:item/...` path, that is a vanilla dependency and not a self-contained mod texture.

## How To Pick The Right JSON

### Rule 1: Read the blockstate first

The blockstate tells you which model file is actually used.

- If the blockstate has one simple `variants` entry, open that model JSON.
- If the blockstate uses `multipart`, read every referenced model file.

### Rule 2: Open `models/block/...`, not `blockstates/...`

For a first export pass:

- use `blockstates/...` as the map
- use `models/block/...` as the actual file you open in Blockbench

### Rule 3: Multipart assets need either all parts or a display model

For multipart or tall assets:

- use every referenced model JSON from the blockstate if you want exact placed structure
- use `display.json` when present if you want an easier single-file preview first

### Rule 4: Ignore `models/item/...` for first room-prop exports

Those files are usually item-display wrappers, not the main placed geometry you want for Godot.

## Starter Asset Walkthroughs

### 1. `small_fancy_vase`

- Check blockstate:
  - `src/main/resources/assets/tanukidecor/blockstates/small_fancy_vase.json`
- Open this model JSON in Blockbench:
  - `src/main/resources/assets/tanukidecor/models/block/small_fancy_vase/small_fancy_vase.json`
- Required texture:
  - `src/main/resources/assets/tanukidecor/textures/block/vase/small_fancy_vase.png`
- Why it is easy:
  - one blockstate
  - one model JSON
  - one internal mod texture
  - no vanilla dependency found

### 2. `small_striped_vase`

- Check blockstate:
  - `src/main/resources/assets/tanukidecor/blockstates/small_striped_vase.json`
- Open this model JSON in Blockbench:
  - `src/main/resources/assets/tanukidecor/models/block/small_striped_vase/small_striped_vase.json`
- Required texture:
  - `src/main/resources/assets/tanukidecor/textures/block/vase/small_striped_vase.png`
- Why it is easy:
  - same workflow as the first vase
  - good confirmation that your export naming and scale process is repeatable

### 3. `blue_lamp`

- Check blockstate:
  - `src/main/resources/assets/tanukidecor/blockstates/blue_lamp.json`
- Open this model JSON in Blockbench:
  - `src/main/resources/assets/tanukidecor/models/block/blue_lamp/blue_lamp.json`
- Required texture:
  - `src/main/resources/assets/tanukidecor/textures/block/blue_dresser.png`
- Important gotcha:
  - the asset is named `blue_lamp`, but the texture key points at `tanukidecor:block/blue_dresser`
- Why it is useful:
  - it proves whether your process catches internal texture reuse instead of assuming every asset has a same-name PNG

### 4. `birdcage`

- Check blockstate:
  - `src/main/resources/assets/tanukidecor/blockstates/birdcage.json`
- Easiest single-file preview:
  - open `src/main/resources/assets/tanukidecor/models/block/birdcage/display.json`
- Exact placed assembly:
  - `src/main/resources/assets/tanukidecor/models/block/birdcage/lower.json`
  - `src/main/resources/assets/tanukidecor/models/block/birdcage/upper.json`
- Required texture:
  - `src/main/resources/assets/tanukidecor/textures/block/birdcage.png`
- Why it is medium difficulty:
  - multipart blockstate
  - tall split geometry
  - cutout-style material behavior

## Common Failure Cases

### Opening the blockstate JSON directly

That file is a router, not the real geometry file. Read it first, then open the model JSON it points to.

### Assuming the texture name matches the asset name

`blue_lamp` is the first trap here. The model uses `tanukidecor:block/blue_dresser`, so the texture file you need is:

- `src/main/resources/assets/tanukidecor/textures/block/blue_dresser.png`

### Multipart assemblies

`birdcage` is the clean first example.

- quick preview: open `display.json`
- exact in-world structure: open `lower.json` and `upper.json`

Use the blockstate to decide which version you want.

### Vanilla dependency cases

Do not start with `rough_log_bench`.

Its model references:

- `minecraft:block/oak_log`
- `minecraft:block/oak_log_top`

That means the asset is not fully self-contained inside Tanuki Decor.

### Empty or state-only helper models

Some storage or clock assets include helper files such as `empty.json` or state-specific subparts. Those are not good first exports because they describe behavior states rather than a simple decorative prop.
