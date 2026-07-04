# ADR-000 — ADR process

**Status:** Accepted (2026-07-04)

## Context

We make architectural and tech-stack decisions that need a durable, reviewable record of
*why*. Conventions (`CLAUDE.md`) and the per-action READMEs say *how / what* — but not
*why*. ADRs are that.

## Decision

Every significant decision (new tech, new dependency, new external service, a load-bearing
design choice) is one ADR at `docs/adr/NNN-short-slug.md`, written **before the
implementation PR** for the area it governs. Format:

- **Status:** Proposed | Accepted (YYYY-MM-DD) | Superseded by ADR-MMM
- **Context:** what problem / forces
- **Options considered:** ≥2 alternatives, honest pros/cons
- **Decision:** the chosen option
- **Consequences:** what this locks in / out

Numbers are monotonic across the repo (never reused). `docs/adr/README.md` indexes all
ADRs and doubles as the **decision log** for choices already made but not yet written up.

## Consequences

- The *why* behind every locked decision is captured next to the code it governs.
- Discipline-enforced, not CI-enforced — the reviewer is the gate.
- Decisions made during planning are listed in the index as "accepted (planning)" and
  graduate to a full ADR file when their release lands.
