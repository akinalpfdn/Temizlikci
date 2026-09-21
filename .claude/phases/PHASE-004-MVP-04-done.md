# Phase 004 (MVP-04) — Sunburst, list & navigation
Status: DONE

## Goal
People can see and navigate what uses their disk.

## Tasks
- [x] Canvas sunburst: rings by depth, min-angle merging, separators, labels on large segments
- [x] Hover + selection + drill-down animation (Reduce Motion aware), breadcrumb
- [x] List synced with chart; sort; search
- [x] Inspector details; Reveal in Finder; Quick Look
- [x] Progressive rendering during scan
- [x] Accessibility: segment elements, `AXChartDescriptor`, keyboard navigation, change announcements

- [x] Measure peak memory of a full scan in the running app: startup disk, Debug build — peak RSS 1,112 MB (see notes)

- [x] Developer check in the running app: first scan exposed the /.nofollow double count (fixed); developer reopened the fixed build and asked to continue without reporting the new totals

## Acceptance Criteria
- UI responsive during a full scan (Instruments)
- VoiceOver reaches and describes every visible segment and row; Audio Graphs available
- Every action reachable via keyboard and menu bar

## Decisions Made This Phase
- Highlight Reclaimable removed until Phase 6 (DECISIONS 2026-09-22).
- Interaction and shortcuts: see DECISIONS "Chart interaction model".
- `xcodebuild test`: 49 tests, 48 passed, 1 opt-in benchmark skipped (no app windows opened).
- Added Contacts/Calendars/Reminders stores to the unread-without-FDA list as a precaution before the first in-app startup-disk scan.
- 2026-09-22 01:07–01:10 — In-app startup-disk scan (Debug build, developer at the keyboard), sampled with `ps` every second: ~2 min at ~378% CPU; peak RSS 1,112 MB at the end of the scan; ~49 MB idle afterwards (likely compression). Logged as a known issue (memory model); target to agree: < ~500 MB.
- 2026-09-22 — Developer's screenshot showed 731 GB on a 494 GB disk: `/.nofollow` (419 GB) aliased the whole volume. `/.nofollow`, `/.resolve`, `/.vol` are virtual root folders that look ordinary (not volumes, not symlinks); now skipped via `ScanConfiguration.skippedPaths` (fix 0d88405). Same screenshot: ring labels misplaced (drawn in an unaligned rect), share column clipped in Turkish locale (%59), current breadcrumb looked disabled, "System, Snapshots & Purgeable" misleading without FDA → all fixed.
- 2026-09-22 — Closed. VoiceOver/Audio Graphs not explicitly verified by the developer; re-check in the Phase 7 accessibility audit. Memory issue logged separately (Lore knownIssue, not in sprint).
