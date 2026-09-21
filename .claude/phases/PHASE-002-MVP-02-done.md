# Phase 002 (MVP-02) — Project foundation
Status: DONE

## Goal
A buildable app shell with theme, strings, and test tooling in place.

## Tasks
- [x] Decide project creation method (Xcode template by developer vs generated) and log it
- [x] Xcode project: macOS App, SwiftUI, Swift Testing, folder-synchronized groups, macOS 26 target, Swift 6 mode, Hardened Runtime, no sandbox
- [x] `Theme` module with tokens from Phase 1
- [x] `Localizable.xcstrings` with app name and shell strings
- [x] `NavigationSplitView` shell (sidebar, content, inspector) with placeholder/empty states
- [x] Menu commands: only working ones (Choose Folder… ⌘O, Highlight Reclaimable, sidebar/inspector). Others ship with their features — see DECISIONS 2026-09-22
- [x] README, .gitignore review, CLAUDE.md context update

## Acceptance Criteria
- `xcodebuild build` and `xcodebuild test` succeed from the command line
- No hardcoded colors, fonts, or user-facing strings in views
- Light, Dark, Increase Contrast, and Reduce Transparency render correctly

## Decisions Made This Phase
- Project hand-written with synchronized folders; bundle id com.akinalpfdn.Temizlikci; team WQ54PPL5VQ; Hardened Runtime on; sandbox off.
- Increased-contrast palette derived and validated (all checks pass in both modes, all slots ≥ 3:1).
- `xcodebuild build` succeeded with no warnings; `xcodebuild test`: 49 tests passed (view model, string catalog sync, source hygiene, palette).
- App launches in Light and Dark (`-AppleInterfaceStyle`). Window screenshots failed: the terminal lacks Screen Recording permission. Visual check of Light/Dark/Increase Contrast/Reduce Transparency is pending with the developer.
- 2026-09-22 — Developer asked to commit and continue. Visual check of Increase Contrast / Reduce Transparency was not explicitly reported; re-check in the Phase 7 accessibility audit.
