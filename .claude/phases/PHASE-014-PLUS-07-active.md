# Phase 014 (PLUS-07) — Cached scans
Status: DONE

## Goal
Opening the app shows the last scan straight away, and it refreshes itself only when the data is old.

## Tasks
- [x] Compact archive format for a whole scan tree (names, not repeated paths), written compressed after every finished scan
- [x] Load the cached scan on launch: chart, list and insights filled before any disk read
- [x] Age shown in the UI ("Scanned 3 days ago"); refresh in the background when older than the chosen period, keeping the open folder and selection
- [x] Settings (⌘,) for the refresh period, default 3 days, with an option to never refresh by itself
- [x] Keep the cache correct after Move to Trash and Undo
- [x] Measure on the real startup disk: file size, save time, load time
- [x] Tests: archive round-trip, age logic, refresh keeps the open folder

## Acceptance Criteria
- Launch to a filled chart in under a second on a cached location
- A refresh never clears what is on screen until it has finished
- Nothing is scanned automatically when the cache is fresh

## Decisions Made This Phase
- Measured on the real home folder (1,849,681 files): scan 34.4 s vs archive 5 MB compressed, 2.1 s to write, 1.35 s to read back (`TEMIZLIKCI_CACHE_PATH` benchmark).
- Format is a compact pre-order binary with names only; paths are rebuilt from the parent (DECISIONS 2026-09-22).
- Refresh is age-based (default 3 days, Settings ⌘,), keeps the previous tree on screen and returns to the open folder.
- Tests: 121 (119 pass, 2 opt-in benchmarks).
- Still to check live with the developer, together with phases 009–011.
