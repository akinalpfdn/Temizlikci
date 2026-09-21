# Phase 003 (MVP-03) — Scan engine
Status: ACTIVE

## Goal
A fast, correct, cancellable scanner with tests, independent of UI.

## Tasks
- [x] `DiskScanner`: bounded concurrency, allocated sizes, hard-link dedupe, same-volume enforcement, no symlink following, mounted-image skip, firmlink-aware roots
- [x] Memory model: directory tree + large files + per-directory "Smaller files" + global top-N
- [x] Unreadable folders recorded as "Needs access", not dropped
- [x] `VolumeInfoService` (used / available / important-usage capacity) and "Other / not scanned" computation
- [x] Progress `AsyncStream`, cancellation
- [x] Fixture tests: nested dirs, hard links, symlink loops, unreadable folders
- [x] Benchmark vs `du -skx` on a real folder (numbers below)
- [ ] Peak memory for a full Home scan — needs the developer's go-ahead (reads the real home folder)
- [x] Consent-prompt fix: without Full Disk Access, prompting folders are never opened (Lore knownIssue 94)
- [x] Tests no longer open app windows (windowless test host)

## Acceptance Criteria
- Fixture totals exact
- Real-folder totals within 1% of `du -skx`, not slower than `du` (numbers recorded)
- Cancellation stops work promptly, no leaked tasks
- Peak memory measured and recorded

## Decisions Made This Phase
- Benchmarks on `~/Documents/GitHub` (read-only):
  - before autorelease pool: scanner 79,545,556,992 B in 5.31 s; du 79,545,556,992 B in 13.01 s; diff 0.000%; peak RSS 336 MB
  - after autorelease pool: scanner 79,332,085,760 B in 7.10 s; du 79,332,085,760 B in 12.66 s; diff 0.000%; peak RSS 219 MB (includes test-host baseline)
- 2026-09-22 — A home-folder benchmark triggered TCC prompts (Music) and repeated test runs opened app windows; developer stopped it. Fixed both (see DECISIONS).
- 2026-09-22 — This file was accidentally emptied during the Phase 2→3 transition (opened for writing before reading) and restored from commit f15d403.
