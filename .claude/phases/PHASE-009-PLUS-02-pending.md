# Phase 009 (PLUS-02) — Stale Projects
Status: PENDING

## Goal
People find projects they haven't touched in a while and how much build output they hold.

## Tasks
- [ ] Detect project roots by markers (Package.swift, *.xcodeproj, package.json, pubspec.yaml, build.gradle(.kts), Cargo.toml, ProjectSettings/)
- [ ] Last-touched date from the newest modification among the project's non-artifact folders (from the tree; no extra disk reads where possible)
- [ ] Developer view section: projects untouched for more than a chosen period (default 90 days) with their artifacts and totals
- [ ] Per-item actions only (Move to Trash for Safe items); no bulk clean (DECISIONS 2026-09-22)
- [ ] Tests: project detection and staleness on fixture trees

## Acceptance Criteria
- Stale projects list matches the fixtures exactly
- Artifacts inside active projects are never listed as stale
- Period is adjustable and remembered

## Decisions Made This Phase
