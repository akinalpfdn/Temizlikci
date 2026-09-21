# Phase 002 (MVP-02) — Project foundation
Status: PENDING

## Goal
A buildable app shell with theme, strings, and test tooling in place.

## Tasks
- [ ] Decide project creation method (Xcode template by developer vs generated) and log it
- [ ] Xcode project: macOS App, SwiftUI, Swift Testing, folder-synchronized groups, macOS 26 target, Swift 6 mode, Hardened Runtime, no sandbox
- [ ] `Theme` module with tokens from Phase 1
- [ ] `Localizable.xcstrings` with app name and shell strings
- [ ] `NavigationSplitView` shell (sidebar, content, inspector) with placeholder/empty states
- [ ] Menu commands wired (no-op) with standard shortcuts
- [ ] README, .gitignore review, CLAUDE.md context update

## Acceptance Criteria
- `xcodebuild build` and `xcodebuild test` succeed from the command line
- No hardcoded colors, fonts, or user-facing strings in views
- Light, Dark, Increase Contrast, and Reduce Transparency render correctly

## Decisions Made This Phase
