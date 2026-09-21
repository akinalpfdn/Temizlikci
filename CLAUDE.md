# Temizlikci

## What This Is
A native macOS app that shows what uses disk space — folder by folder, as an interactive sunburst chart with a synchronized list — and helps developers reclaim space safely by recognizing developer artifacts (Xcode, simulators, Gradle/Android, Node, Flutter, Go, build folders) and labelling each as safe to trash, removable only via its owning tool, or user data to keep. Built for the developer's own Mac first; potentially distributed later.

## Tech Stack
| Layer | Technology | Why |
|-------|-----------|-----|
| UI | SwiftUI (macOS 26+), AppKit only where needed | Native, HIG-aligned, Liquid Glass for free |
| Charts | Custom `Canvas` sunburst; Swift Charts for conventional charts | Sunburst needs multi-ring hit testing and drill-down (see DECISIONS.md) |
| Language | Swift 6.3, Swift 6 mode, strict concurrency | Off-main scanning without data races |
| Tests | Swift Testing | Scanner and rules tested on real temp file trees |
| Toolchain | Xcode 26.6 (macOS 26.5 SDK) | User decision 2026-09-21 |
| Distribution | Developer ID + notarized DMG, not sandboxed | Needs `xcrun simctl` and Full Disk Access |

## Architecture
MVVM. App (scenes, commands) → Features (View + `@MainActor @Observable` ViewModel) → Domain (FileNode tree, CleanupRule, SafetyLevel) → Services (DiskScanner, VolumeInfoService, TrashService, ToolRunner, AccessService, RuleEngine — protocols, injected). `Theme` and the String Catalog are shared. Full detail: `DEVPLAN.md`.

## Current Phase
See `.claude/phases/` — always check the active phase file before starting work. Only one phase is active; never start the next without explicit approval.

## Rules

### Always active
@rules/common/core.md
@rules/common/decisions.md
@rules/common/git.md
@rules/common/testing.md
@rules/common/debug.md
@rules/common/existing-code.md

### UI projects only
@rules/common/frontend.md

### Language rules
@rules/swift/swift.md

## Project-Specific Constraints
- **App name is "Temizlikci"; every other user-facing string is English**, and all of them go through `Localizable.xcstrings`.
- **Apple HIG is binding.** Before designing or changing UI, read `claudedocs/hig-research-2026-09.md` and the relevant raw page in `claudedocs/hig/`. If the notes are older than ~3 months or a new OS shipped, run `scripts/fetch-hig.sh` first. Never design from memory.
- **Never delete user content with `removeItem`.** Deletion goes through `TrashService` (Move to Trash, undoable) or a tool strategy (`xcrun simctl` …). Destructive code paths are tested on temp fixtures only — never against real user folders.
- **Never run tests or experiments that delete from real locations** (Home, `~/Library`, `/Library`). Use temporary directories.
- The app never runs as root and never ships a privileged helper.
- Liquid Glass stays in the control layer; no `glassEffect` on chart or list content.
- No Xcode 27 / macOS 27–only APIs until the toolchain migration decision is revisited.

## Context
- Toolchain is Xcode 26.6 on macOS 26.6.2 (developer's Mac). When the developer upgrades to macOS 27, Xcode 27 becomes mandatory — plan a migration session (Swift 6.4, `@State` macro change).
- Lore: project not registered yet. Once registered, mirror `.claude/phases/` as work items.
- Open source vs private: undecided; treat as private.
- Motivation and real-world numbers (what regrows on a developer Mac): see DEVPLAN.md Overview and Constraints.
