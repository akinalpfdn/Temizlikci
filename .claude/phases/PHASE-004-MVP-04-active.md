# Phase 004 (MVP-04) — Sunburst, list & navigation
Status: ACTIVE

## Goal
People can see and navigate what uses their disk.

## Tasks
- [x] Canvas sunburst: rings by depth, min-angle merging, separators, labels on large segments
- [x] Hover + selection + drill-down animation (Reduce Motion aware), breadcrumb
- [x] List synced with chart; sort; search
- [x] Inspector details; Reveal in Finder; Quick Look
- [x] Progressive rendering during scan
- [x] Accessibility: segment elements, `AXChartDescriptor`, keyboard navigation, change announcements

- [ ] Measure peak memory of a full Home scan in the running app (developer watching; carried over from Phase 3)

- [ ] Developer check in the running app: scan the startup disk, UI responsiveness, VoiceOver/Audio Graphs, keyboard/menu reachability

## Acceptance Criteria
- UI responsive during a full scan (Instruments)
- VoiceOver reaches and describes every visible segment and row; Audio Graphs available
- Every action reachable via keyboard and menu bar

## Decisions Made This Phase
- Highlight Reclaimable removed until Phase 6 (DECISIONS 2026-09-22).
- Interaction and shortcuts: see DECISIONS "Chart interaction model".
- `xcodebuild test`: 49 tests, 48 passed, 1 opt-in benchmark skipped (no app windows opened).
- Added Contacts/Calendars/Reminders stores to the unread-without-FDA list as a precaution before the first in-app startup-disk scan.
