# Phase 010 (PLUS-03) — Other Used Space breakdown
Status: PENDING

## Goal
The unattributed segment explains where its space is.

## Tasks
- [ ] Research and verify on this Mac: purgeable space (important-usage vs available capacity), local Time Machine snapshots (tmutil, read-only), Trash size, system volume
- [ ] Split Other Used Space into labeled parts; the remainder stays honest ("not attributed")
- [ ] Inspector explanation per part with a next step (e.g. snapshots: how macOS removes them)
- [ ] Tests with stubbed system readings

## Acceptance Criteria
- Parts add up to the unattributed total
- Nothing here requires new permission prompts
- Every figure states its source

## Decisions Made This Phase
