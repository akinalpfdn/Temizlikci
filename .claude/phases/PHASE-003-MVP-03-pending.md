# Phase 003 (MVP-03) — Scan engine
Status: PENDING

## Goal
A fast, correct, cancellable scanner with tests, independent of UI.

## Tasks
- [ ] `DiskScanner`: bounded concurrency, allocated sizes, hard-link dedupe, same-volume enforcement, no symlink following, mounted-image skip, firmlink-aware roots
- [ ] Memory model: directory tree + large files + per-directory "Smaller files" + global top-N
- [ ] Unreadable folders recorded as "Needs access", not dropped
- [ ] `VolumeInfoService` (used / available / important-usage capacity) and "Other / not scanned" computation
- [ ] Progress `AsyncStream`, cancellation
- [ ] Fixture tests: nested dirs, hard links, symlink loops, unreadable folders
- [ ] Benchmark vs `du -skx` on a real folder; Instruments memory for full Home scan — record numbers here

## Acceptance Criteria
- Fixture totals exact
- Real-folder totals within 1% of `du -skx`, not slower than `du` (numbers recorded)
- Cancellation stops work promptly, no leaked tasks
- Peak memory measured and recorded

## Decisions Made This Phase
