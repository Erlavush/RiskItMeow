# Quick Task 260409-whv

## Description

Add a graceful `Grid Placement` toggle so the runtime placement system can switch between snapped placement and free placement without regressing the current build/edit workflow. This should preserve today's behavior when snapping is on, and make free placement feel intentional rather than like a partially bypassed snap system.

## Scope

- Add one explicit placement-mode toggle in the existing placement tools UI.
- Apply the toggle to active placement, edit, and duplicate preview flows.
- Thread the mode through floor, wall, ceiling, and support-surface positioning behavior.
- Keep validation, autosave, save/load, wall openings, sunlight syncing, popup actions, and camera-input blocking stable.
- Do not add unrelated camera rewrites, InputMap refactors, new placeable types, scene restructuring, or new persistence systems.

## Assumptions

- Repurpose the current `Grid Overlay` tools button into the primary `Grid Placement: On/Off` toggle instead of adding a second adjacent toggle. Overlay visibility should become contextual to the active placement mode.
- `Grid Placement` defaults to `On`, which must preserve the current placement behavior exactly.
- The toggle itself is runtime/session state only. Individual placed transforms must persist; the global toggle state does not need to be saved in `user://room_layout.json`.
- Free mode means continuous positional movement on the valid mount surface, not unrestricted transform editing.
- Even if the live catalog does not currently expose ceiling or support-surface decor items, the existing code paths should still be updated now so those mount types do not diverge silently.
- `scripts/player.gd` and `scripts/camera/room_view_camera_controller.gd` are regression-watch files only. No direct edits are planned unless input blocking breaks during execution.

## Must Haves

- `Grid Placement` is visible in the placement tools UI, defaults to `On`, and its label/state updates immediately.
- With `Grid Placement` on, floor, wall, ceiling, and support-surface positioning behaves the same as the current snapped implementation.
- With `Grid Placement` off, floor items move continuously in `x/z`, stay inside room bounds by rotated footprint, and still fail validation on overlap.
- With `Grid Placement` off, wall items move continuously along the active wall plane, stay inside wall bounds by wall half extents, preserve wall-facing rotation, and keep wall-opening/cutaway/sunlight behavior intact.
- With `Grid Placement` off, ceiling items move continuously across the ceiling plane while staying locked to ceiling `y`.
- With `Grid Placement` off, support-surface items move continuously within the host surface bounds, remain parented to the host, keep `host_surface_id`, and keep `SUPPORT_SURFACE_CLEARANCE`.
- Rotation stays intentionally snapped to `90` degree steps in both modes; free mode only changes positional snapping.
- Edit, duplicate, cancel, save/load, and autosave flows work in both modes without surprise resnapping.
- Status text and popup hints reflect the current mode and stop using snapped-only wording like `cell` when free mode is active.
- Saved layouts round-trip both snapped and free transforms without collapsing them back to grid centers.

## Tasks

### 1. Add explicit placement-mode state and UI threading

**Files**
- `scripts/placement/placement_manager.gd`

**Action**
- Introduce a dedicated placement snap-mode state such as `_grid_placement_enabled := true` instead of piggybacking on `_manual_grid_visible`.
- Replace the current `Grid Overlay` button behavior with a `Grid Placement: On/Off` toggle in the existing tools section.
- Allow the toggle to apply gracefully during idle, build, edit, and duplicate preview sessions.
- When switching `Off`, keep the current preview on its current valid surface and continue from that transform.
- When switching `On`, immediately resnap the active preview to the nearest valid snapped position on the same surface so the user sees a deterministic result.
- Update `_update_inventory_ui()`, `_update_status_text()`, `_update_popup_visuals()`, `_update_grid_visibility()`, and related UI state so the label, helper text, and visual treatment always match the active mode.
- Keep room overlay visibility contextual: show the dotted room overlay when snapped room placement/editing is active, and hide it for support-surface placement and free mode unless execution finds a strong UX reason to preserve a separate overlay toggle.

**Bug prevention**
- Keep one source of truth for placement mode across build, edit, and duplicate flows.
- Do not change `scenes/main.tscn`; the UI is already constructed in code by `PlacementManager`.

**Verify**
- Automated: `Godot_v4.6.1-stable_win64_console.exe --headless --path Z:\\RiskItMeow\\risk-it-meow --quit-after 1`
- Manual: start a placement session, flip the toggle on/off mid-preview, and confirm the button text, status text, and preview behavior update immediately without canceling the session.

**Done**
- The placement UI exposes one clear snapped/free toggle, defaults to snapped behavior, and live mode changes are reflected consistently across idle/build/edit UI states.

### 2. Unify surface-specific snapped and free positioning logic

**Files**
- `scripts/placement/placement_manager.gd`
- `scripts/placement/placement_surface_queries.gd`
- `scripts/placement/placement_validator.gd`

**Action**
- Refactor preview movement so `_set_preview_position()`, `_update_drag()`, duplicate seed positioning, and edit-session movement all flow through one surface-aware resolver instead of scattered snap calls.
- Floor: keep the current grid resolver when snapped mode is on; add free placement using raw floor hits clamped by rotated footprint extents when snapped mode is off.
- Ceiling: mirror floor behavior but keep `y` locked to `room_shell.get_ceiling_y()`.
- Wall: keep current wall snap behavior when snapped mode is on; add free wall-plane placement when snapped mode is off by clamping horizontal and vertical wall values against wall bounds plus item wall half extents, then rebuilding the final mount position with `build_wall_mount_position()`.
- Support surfaces: keep current `0.25` support-surface snapping when snapped mode is on; add unclamped-but-bounded local placement when snapped mode is off, still using host local space, rotated footprint extents, support-surface bounds, and `SUPPORT_SURFACE_CLEARANCE`.
- Move floor and ceiling bounds checks onto rotated planar half extents as part of the same refactor. Today `PlacementValidator` uses raw `get_footprint_half_extents()` for those surfaces, while support-surface placement already accounts for rotation; free mode should not introduce a second footprint-bounds path.
- Preserve validation rules from `PlacementValidator`: surface visibility, supported wall filters, occupancy, bounds, and host attachment must keep working in both modes.
- Keep these behaviors intentionally constrained even in free mode:
- wall items stay aligned to the wall normal and supported wall list;
- floor/ceiling/support-surface `y` anchoring stays locked to the active mount surface;
- Q/E and rotate-gizmo rotation stays snapped to `90` degree steps;
- support-surface items stay attached to the chosen host and `surface_id`.

**Bug prevention**
- Do not fork separate free-placement math for mouse drag versus gizmo axis drag; both should share the same resolved/clamped helpers.
- Do not leave floor/ceiling validation on unrotated footprint extents after the resolver changes, or long rectangular items will appear to fit visually but fail or clip at room edges after rotation.
- Windows and other wall-opening items must continue to drive `_sync_room_wall_openings()` from the resolved wall transform so openings do not drift between snapped and free mode.

**Verify**
- Automated: `Godot_v4.6.1-stable_win64_console.exe --headless --editor --path Z:\\RiskItMeow\\risk-it-meow --quit-after 1`
- Manual:
- Floor: move a chair with snapping on and off; confirm continuous free motion and unchanged snapped behavior.
- Wall: move/place a window with snapping on and off; confirm continuous wall sliding in free mode and correct opening alignment in both modes.
- Ceiling/support surface: if no live catalog item exists, use the existing mount-aware debug path or a temporary mount-capable item during execution so those code paths are verified now instead of deferred.

**Done**
- Every placement surface uses one shared mode-aware positioning path, free mode feels deliberate, and snapped mode remains functionally identical to today.

### 3. Lock down persistence, edit-flow regressions, and user guidance

**Files**
- `scripts/placement/placement_manager.gd`
- `scripts/placement/placement_room_layout_store.gd` (review and change only if execution reveals a real free-placement serialization gap)

**Action**
- Audit the current room-layout save/load path before changing schema. The default expectation is that current `Vector3` serialization at `0.001` precision already preserves free floor, ceiling, wall, and support-surface transforms.
- Do not add the global placement-mode toggle to saved room layout unless execution uncovers a strong user-facing reason.
- If a schema addition becomes necessary, keep it backward-compatible and limited.
- Update status text and popup hint text so snapped mode can reference `grid`, `cell`, or `nearest slot`, while free mode uses `surface`, `spot`, or `area`.
- Recheck edit-specific flows: double-click edit, duplicate, delete, cancel/restore original transform, autosave after confirm, and load-after-save should all preserve the chosen placement result without unexpected resnapping.
- Keep camera/input behavior unchanged from the user perspective; only touch `scripts/player.gd` or `scripts/camera/room_view_camera_controller.gd` if free-mode dragging starts leaking orbit input or blocking input incorrectly.

**Bug prevention**
- Canceling an edit in free mode must restore the exact original transform, not a new snapped transform.
- Loading a saved free-placed wall or support-surface item must restore the same effective transform and attachment metadata, not just the same item count.

**Verify**
- Automated:
- `Godot_v4.6.1-stable_win64_console.exe --headless --path Z:\\RiskItMeow\\risk-it-meow --quit-after 1`
- `Godot_v4.6.1-stable_win64_console.exe --headless --editor --path Z:\\RiskItMeow\\risk-it-meow --quit-after 1`
- Manual:
- Place one item in snapped mode and one in free mode.
- Save, reload, and restart the project.
- Enter edit mode on each item, move it, cancel once, then confirm once.
- Duplicate and delete an item in both modes.
- Verify wall openings and window sunlight still look correct after reload.

**Done**
- Save/load keeps precise transforms, edit/cancel/duplicate behavior remains stable, and the UI/help text no longer misleads the user about whether placement is snapped or free.

## Risks

- `scripts/placement/placement_manager.gd` is already the main hotspot, so the biggest regression risk is duplicating logic between build, edit, duplicate, and gizmo movement instead of consolidating it.
- Support-surface placement is easy to break because parent/local transforms, host metadata, and cutaway visibility are coupled. Free mode must clamp in host local space, not world space.
- Wall windows are the most visible regression surface; a small wall-position math error can misalign the opening, sunlight portal, or cutaway behavior.
- Several current UI strings assume snapped placement. Leaving even one stale hint will make free mode feel accidental.
- There are no automated gameplay tests, so the execution pass must treat the manual verification matrix as required work.

## Verification

### Automated smoke checks

- `Godot_v4.6.1-stable_win64_console.exe --headless --path Z:\\RiskItMeow\\risk-it-meow --quit-after 1`
- `Godot_v4.6.1-stable_win64_console.exe --headless --editor --path Z:\\RiskItMeow\\risk-it-meow --quit-after 1`

### Manual regression matrix

- Build mode, snapping on:
- place and rotate a floor item;
- confirm behavior matches the current build exactly.
- Build mode, snapping off:
- place the same floor item between grid centers;
- confirm occupancy and bounds still block invalid spots.
- Wall placement:
- place or edit a window with snapping on and off;
- confirm free wall sliding works, supported wall restrictions still apply, and the wall opening remains aligned after save/load.
- Ceiling placement:
- verify free versus snapped ceiling movement on a ceiling-capable item, with `y` locked to the ceiling plane.
- Support-surface placement:
- verify free versus snapped tabletop/shelf placement stays on the host surface, respects rotated footprint bounds, and restores the same host after save/load.
- If the live catalog still lacks a ceiling-capable or support-surface item, verify those code paths through the existing debug/mount-aware tooling during execution rather than leaving them untested.
- Edit flow:
- double-click edit, move, cancel, then re-edit and confirm;
- duplicate and delete once in each placement mode.
- UI/help text:
- confirm the toggle label, main status label, and popup hint text all change with the mode and never refer to `cell` or `grid` while free mode is active.
- Camera/input:
- confirm left-drag orbit still works on empty space and does not fight with gizmo/preview drag in either mode.
