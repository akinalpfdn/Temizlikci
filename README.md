# Temizlikci

A native macOS app that shows, folder by folder, what is using your disk — as an interactive sunburst chart with a synchronized list — and helps developers reclaim space safely. It recognizes developer artifacts (Xcode, simulators, Gradle/Android, Node, Flutter, Go, build folders) and labels each one **Safe to Remove**, **Remove with Tool**, or **Keep**.

> Status: early development. See `DEVPLAN.md` for the plan and `.claude/phases/` for progress.

## Requirements
- macOS 26 or later, Apple silicon
- Xcode 26.6 (macOS 26.5 SDK, Swift 6.3)

## Build and test
```sh
xcodebuild -project Temizlikci.xcodeproj -scheme Temizlikci -destination 'platform=macOS' -derivedDataPath build/DerivedData build
xcodebuild -project Temizlikci.xcodeproj -scheme Temizlikci -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```
Or open `Temizlikci.xcodeproj` in Xcode and run the **Temizlikci** scheme.

## Project layout
| Path | Contents |
|---|---|
| `Temizlikci/App` | App entry point, scenes, menu commands |
| `Temizlikci/Features` | Screens — each a SwiftUI view plus an `@Observable` view model |
| `Temizlikci/Services` | Protocol-backed system access (volumes, folder picking; scanning and trash later) |
| `Temizlikci/Theme` | Chart palette, status colors, spacing, typography tokens |
| `Temizlikci/Resources` | Asset catalog, `Localizable.xcstrings`, `Strings/L10n.swift` |
| `TemizlikciTests` | Swift Testing suites, including hygiene checks for strings, colors, and fonts |
| `claudedocs/` | HIG research notes and the approved design prototype |

## Conventions
- Every user-facing string goes through `L10n` and `Localizable.xcstrings`; the catalog is maintained by hand and a test keeps them in sync.
- Views use Theme tokens and system colors only; a test rejects literals, raw colors, and fixed font sizes in views.
- Apple's Human Interface Guidelines are binding. Refresh the local copy with `scripts/fetch-hig.sh`.
- Decisions are logged in `DECISIONS.md`.
