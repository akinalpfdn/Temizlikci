# Phase 011 (PLUS-04) — More developer rules
Status: PENDING

## Goal
Temizlikci recognizes the caches and build outputs of the common developer toolchains.

## Tasks
- [ ] Research each tool's cache locations and official clean commands (current docs)
- [ ] Rules: Docker, CocoaPods (cache + Pods beside Podfile), SwiftPM (cache + .build beside Package.swift), Rust (target beside Cargo.toml, ~/.cargo registry), Unity (Library beside ProjectSettings), Gradle project build, Maven ~/.m2, JetBrains caches, Yarn/pnpm/Bun caches, Python __pycache__
- [ ] Correct safety level and reason per rule; tool-owned ones point to the tool
- [ ] Drag rows onto the sidebar Trash (app-internal drag type; same Undo path) — Lore improvementIdea
- [ ] Tests: every rule matches its targets and not look-alikes

## Acceptance Criteria
- Each rule has a sourced reason and a match/non-match test
- Keep and tool items still never offer Move to Trash
- Drag to Trash is undoable

## Decisions Made This Phase
