# Phase 008 (PLUS-01) — What Grew
Status: ACTIVE

## Goal
People see what grew or shrank since their previous scan of the same location.

## Tasks
- [ ] Persist a compact snapshot after each finished scan (folder sizes down to a fixed depth + every cleanup match), per location, in Application Support; keep the last N
- [ ] Diff the current result against the previous snapshot: per-folder and per-artifact deltas
- [ ] UI: growth column/badges in the list (e.g. +15 GB since Sep 21), a "What Grew" view listing the biggest changes, chart hover shows the delta
- [ ] Handle first scan (no history), deleted/renamed folders, and scans of different locations
- [ ] Tests: snapshot encode/decode, diff logic on fixture trees

## Acceptance Criteria
- After two scans, the biggest growth appears with its size and date range
- Snapshots stay small (measured and recorded) and old ones are pruned
- Works without Full Disk Access (unread folders marked, not reported as shrinking)

## Decisions Made This Phase
