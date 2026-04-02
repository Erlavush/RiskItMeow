# Phase 1 Research: Local Room Shell, Placement, and Sample Cats

## Objective

Answer: "What do we need to know to implement the first local room-builder slice well?"

## Source Systems That Matter

The relevant source systems from `Z:\FAHHHH` are the local builder/runtime pieces only:

- enclosed room shell with walls, windows, and roof/ceiling presentation
- wall occlusion for keeping the room interior readable
- placement math for floor, wall, and anchored surface decor
- collision/validation between placed furniture families
- sample pet/cat presence and room-safe motion

The following source systems are intentionally excluded from this phase:

- Firebase/auth/shared-room sync
- partner presence and edit locks
- couple progression and breakup flow
- click-to-move locomotion

## Godot Starting Point

The current Godot repo already gives us:

- a controllable player using `CharacterBody3D`
- freecam, third-person, and first-person camera modes
- a simple world scene with ground and environment
- a Minecraft-style avatar rig and skin import UI

This means Phase 1 should extend the prototype rather than replace it.

## Implementation Implications

### Room Shell

The current `main.tscn` is only an open platform. Phase 1 needs a real interior shell:

- floor surface
- four walls
- roof/ceiling geometry
- geometry organization that supports selective hiding or fading for occlusion

### Occlusion

Occlusion should work with the current camera model, not with click-to-move assumptions. The likely requirement is:

- detect camera relation to the room
- hide or peel front/side/top surfaces as needed
- preserve room readability without making the shell disappear entirely

### Placement Families

The phase must support four placement families:

- floor
- wall
- ceiling/roof
- surface decor

Surface decor needs explicit support-host rules and anchored local offsets instead of being treated as free-floating objects.

### Sample Cats

Sample cats do not need full gameplay depth yet, but they do need:

- visible in-room presence
- safe spawn positions
- readable idle/wander behavior
- compatibility with the local room shell and player movement

## Main Risks

- Placement rules can sprawl quickly if floor, wall, ceiling, and surface decor are not separated clearly.
- Occlusion can easily fight with the camera if the room shell is not structured around hideable surfaces.
- Sample cats can feel broken fast if they clip through furniture or spawn out of bounds.
- The unrelated local change in `scenes/main.tscn` means execution needs to read and preserve current scene state carefully.

## Recommended Phase Outputs

Phase 1 should leave behind:

- a room shell foundation that future systems can decorate rather than replace
- reusable placement/state structures for multiple placement families
- explicit support-host rules for surface decor
- a simple sample-cat runtime that proves the room can feel alive
- manual verification evidence that direct movement still works and click-to-move was not introduced

## Verification Focus

Phase verification should check:

- the room is enclosed and readable
- occlusion works from the current camera modes
- placement succeeds only on valid surfaces
- sample cats stay inside the room and behave visibly
- player movement is still driven by the existing direct controller
