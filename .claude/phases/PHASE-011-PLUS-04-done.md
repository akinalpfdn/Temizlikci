# Phase 011 (PLUS-04) — More developer rules
Status: DONE

## Goal
Temizlikci recognizes the caches and build outputs of the common developer toolchains.

## Tasks
- [x] Research each tool's cache locations and official clean commands (current docs)
- [x] Rules: Docker, CocoaPods (cache + Pods beside Podfile), SwiftPM (cache + .build beside Package.swift), Rust (target beside Cargo.toml, ~/.cargo registry), Unity (Library beside ProjectSettings), Gradle project build, Maven ~/.m2, JetBrains caches, Yarn/pnpm/Bun caches, Python __pycache__
- [x] Correct safety level and reason per rule; tool-owned ones point to the tool
- [x] Drag rows onto the sidebar Trash (app-internal drag type; same Undo path) — Lore improvementIdea
- [x] Tests: every rule matches its targets and not look-alikes

## Acceptance Criteria
- Each rule has a sourced reason and a match/non-match test
- Keep and tool items still never offer Move to Trash
- Drag to Trash is undoable

## Decisions Made This Phase
- Each rule's safety comes from the tool's own current documentation, read 2026-09-22 (DECISIONS).
- Found while testing: `~/Library/Containers` is labelled "keep", so the engine never looked inside it and Docker's disk image went unlabelled. The search now continues inside kept folders.
- Measured on this Mac: NuGet 750 MB, rustup 528 MB, Maven 426 MB, SwiftPM 379 MB, uv 298 MB, electron 231 MB, cargo registry 172 MB, CocoaPods 156 MB, pip 77 MB, node-gyp 64 MB.
- Drag a row's name onto the sidebar Trash; only items of the current scan that no rule protects are accepted, with the same Undo.
- Tests: 111 (110 pass, 1 opt-in), including one that matches every exact-path rule against its own target and one for look-alike folders.
