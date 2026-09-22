# Phase 008 (PLUS-01) — What Grew
Status: DONE

## Goal
People see what grew or shrank since their previous scan of the same location.

## Tasks
- [x] Persist a compact snapshot after each finished scan (folder sizes down to a fixed depth + every cleanup match), per location, in Application Support; keep the last N
- [x] Diff the current result against the previous snapshot: per-folder and per-artifact deltas
- [x] UI: growth column/badges in the list (e.g. +15 GB since Sep 21), a "What Grew" view listing the biggest changes, chart hover shows the delta
- [x] Handle first scan (no history), deleted/renamed folders, and scans of different locations
- [x] Tests: snapshot encode/decode, diff logic on fixture trees
- [x] Large Files (added 2026-09-22, user decision): the sidebar item listed nothing since Phase 2; now lists the 200 largest files of the scan with change, Show in Chart, Reveal, Quick Look, and Move to Trash (never for items inside a Keep/Tool match)

## Acceptance Criteria
- After two scans, the biggest growth appears with its size and date range
- Snapshots stay small (measured and recorded) and old ones are pruned
- Works without Full Disk Access (unread folders marked, not reported as shrinking)
- Large Files lists files of 10 MB or more after a scan, without a second scan

## Decisions Made This Phase
- Large Files reuses the scan tree: the scanner already keeps every file of 10 MB or more as its own node, so no extra disk pass is needed.
- Tests: 91 (90 pass, 1 opt-in). Snapshot size on the startup disk and the two-scan flow still to be checked live.
- Growth direction is a warm/cool color pair, never color alone (DECISIONS 2026-09-22).
- What Grew reads the two newest saved snapshots at launch, so history survives quitting (DECISIONS 2026-09-22).
- Live check with the developer (2026-09-22): both scans compared correctly, Large Files listed and acted on, snapshot size 61 KB per scan of the startup disk (128 KB for two), well under any concern.
- Tests: 95 (94 pass, 1 opt-in).
