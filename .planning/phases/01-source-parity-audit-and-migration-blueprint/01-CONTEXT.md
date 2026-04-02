# Phase 1: Source Parity Audit and Migration Blueprint - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning
**Source:** User directive plus local inspection of the Godot repo and `Z:\FAHHHH`

<domain>
## Phase Boundary

Phase 1 does not attempt broad gameplay implementation in Godot. Its job is to define exactly what the shipped R3F runtime currently does, decide how those systems should map into Godot, and produce the parity and verification artifacts needed to execute the remaining phases without guessing.

</domain>

<decisions>
## Implementation Decisions

### Locked Decisions

- The parity baseline is the currently shipped runtime in `Z:\FAHHHH`, especially `README.md`, `docs/CURRENT_SYSTEMS.md`, `docs/ARCHITECTURE.md`, `docs/GAME_OVERVIEW.md`, `src/App.tsx`, `src/components/RoomView.tsx`, and the source repo's `.planning` docs.
- Phase 1 is a planning/documentation phase. Its outputs are parity matrices, architecture maps, migration plans, risk registers, verification harnesses, and execution checklists.
- The existing Godot repo remains a brownfield prototype foundation. Do not throw it away or rewrite it from zero in Phase 1.
- Browser-first Godot delivery is a hard target because the engine move exists to replace the laggy/unstable browser behavior of the current R3F runtime.
- Port scope is parity with features already shipped in the source runtime, not future roadmap ideas from the source repo.

### The Agent's Discretion

- Exact artifact filenames and section structure under this phase directory.
- Whether a parity concern belongs in the matrix, risk register, migration map, or verification harness, as long as coverage is exhaustive.
- Whether some source developer-only capabilities should remain external tools versus in-engine Godot tools, as long as the final decision is documented and phased.

</decisions>

<canonical_refs>
## Canonical References

**Downstream planning and execution must read these first.**

### Current Godot Target Repo
- `.planning/PROJECT.md` - current port scope, constraints, and core value
- `.planning/REQUIREMENTS.md` - parity requirements that every later phase must satisfy
- `.planning/ROADMAP.md` - dependency-ordered port phases
- `.planning/STATE.md` - current milestone state
- `.planning/codebase/STACK.md` - current Godot prototype stack and platform constraints
- `.planning/codebase/ARCHITECTURE.md` - current Godot prototype architecture
- `.planning/codebase/STRUCTURE.md` - current Godot file layout
- `.planning/codebase/CONCERNS.md` - current Godot risks and missing systems

### Source R3F Runtime
- `Z:\FAHHHH\README.md` - shipped feature summary and runtime entry points
- `Z:\FAHHHH\docs\CURRENT_SYSTEMS.md` - current feature inventory and control scheme
- `Z:\FAHHHH\docs\ARCHITECTURE.md` - source ownership boundaries and module map
- `Z:\FAHHHH\docs\GAME_OVERVIEW.md` - long-term product fantasy and shipped-vs-future separation
- `Z:\FAHHHH\.planning\PROJECT.md` - source repo milestone context and validated capabilities
- `Z:\FAHHHH\.planning\REQUIREMENTS.md` - shipped source requirements and traceability
- `Z:\FAHHHH\.planning\ROADMAP.md` - source phase history and roadmap semantics
- `Z:\FAHHHH\src\App.tsx` - top-level source runtime orchestration
- `Z:\FAHHHH\src\components\RoomView.tsx` - live room scene composition shell
- `Z:\FAHHHH\tests\` - source behavioral regression inventory

</canonical_refs>

<specifics>
## Specific Ideas

- The user wants a comprehensive plan for porting every currently shipped feature from the R3F runtime into this Godot repo.
- The source runtime includes both player-facing gameplay and developer-facing authoring flows. Phase 1 needs to decide which tools become Godot-native, which stay external, and which can be deferred without blocking parity.
- Shared-room backend/auth/presence behavior is part of current shipped scope, so the port plan must include Godot-side browser/backend strategy instead of assuming a purely local single-player port.

</specifics>

<deferred>
## Deferred Ideas

- Net-new gameplay beyond current shipped source features
- Phase-by-phase implementation details beyond the artifacts defined by this planning phase
- Final production backend choice changes, unless Phase 1 research proves the current source approach is not viable from Godot web

</deferred>

---

*Phase: 01-source-parity-audit-and-migration-blueprint*
*Context gathered: 2026-04-02 via source/runtime inspection*
