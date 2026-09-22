# Phase 009 (PLUS-02) — Stale Projects
Status: DONE

## Goal
People find projects they haven't touched in a while and how much build output they hold.

## Tasks
- [x] Detect project roots by markers (Package.swift, *.xcodeproj, package.json, pubspec.yaml, build.gradle(.kts), Cargo.toml, ProjectSettings/)
- [x] Last-touched date from the newest modification among the project's non-artifact folders (from the tree; no extra disk reads where possible)
- [x] Developer view section: projects untouched for more than a chosen period (default 90 days) with their artifacts and totals
- [x] Per-item actions only (Move to Trash for Safe items); no bulk clean (DECISIONS 2026-09-22)
- [x] Tests: project detection and staleness on fixture trees

## Acceptance Criteria
- Stale projects list matches the fixtures exactly
- Artifacts inside active projects are never listed as stale
- Period is adjustable and remembered

## Decisions Made This Phase
- Project detection is free from the tree for `.git` and Xcode projects; marker files are only checked next to folders that already hold a build artifact (DECISIONS 2026-09-22).
- "Last worked on" comes from Git's index, else the newest file two levels down with artifacts skipped.
- Tool repositories (`~/Library`, `/opt`, `/Library`, `/System`, …) are excluded, and the outermost project owns nested ones.
- Tests: 100 (99 pass, 1 opt-in).
- Still to check live with the developer (deferred at their request, 2026-09-22): the list on a real Home scan, the period menu, and how long the extra pass takes.
