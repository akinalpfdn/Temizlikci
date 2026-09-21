# Decisions

This file tracks all non-trivial technical decisions made during this project.
See `rules/common/decisions.md` for the logging format and rules. Append-only.

---

## 2026-09-21 — Toolchain: Xcode 26.6, deployment target macOS 26
**Chosen:** User decision: build with Xcode 26.6 (macOS 26.5 SDK, Swift 6.3); minimum deployment target macOS 26.0.
**Alternatives:** Xcode 27 (macOS 27 SDK, Swift 6.4, runs on macOS 26.6+) with macOS 26 target.
**Why:** Xcode 27 would cost 10+ GB on a disk with ~40 GB free and would move the developer's other iOS projects to Xcode 27 and iOS 27 simulators. None of the macOS 27–only APIs are required for the MVP. macOS 26 is the first release with Liquid Glass, so targeting it avoids maintaining a pre-Liquid-Glass design.
**Trade-offs:** No macOS 27 APIs (toolbar visibility priority, overflow menu, `appearsActive`). A migration session is required when the developer upgrades to macOS 27, because Xcode 26.6 does not run there.
**Revisit if:** The developer upgrades to macOS 27, or a macOS 27 API becomes necessary.

---

## 2026-09-21 — Distribution outside the Mac App Store, not sandboxed
**Chosen:** Developer ID–signed, notarized DMG; Hardened Runtime on; App Sandbox off.
**Alternatives:** Mac App Store with sandbox and user-selected folder access through security-scoped bookmarks.
**Why:** The sandbox forbids launching `xcrun simctl` (the only safe way to remove simulator runtimes and devices), and a sandboxed app cannot meaningfully use Full Disk Access to scan the whole Data volume. Developer-artifact cleanup is the core value.
**Trade-offs:** No App Store discovery or automatic updates (Sparkle is post-MVP). People must trust a direct download.
**Revisit if:** A store-distributed "analyzer only" edition becomes interesting.

---

## 2026-09-21 — Sunburst rendered with a custom SwiftUI Canvas
**Chosen:** A custom `Canvas`-based sunburst with hand-built hit testing and accessibility (`AXChartDescriptor` for Audio Graphs, one accessibility element per meaningful segment).
**Alternatives:** Swift Charts `SectorMark`, stacking one `Chart` per ring with aligned totals.
**Why:** A sunburst needs multiple aligned rings, hit testing by radius *and* angle, thousands of segments, and a custom drill-down animation. Overlaid Swift Charts make ring alignment fragile (every ring must carry filler segments), and selection APIs work per chart rather than per ring.
**Trade-offs:** Swift Charts' free accessibility and Audio Graphs must be rebuilt by hand; more code to test.
**Revisit if:** Profiling shows Canvas is not faster, or Swift Charts gains native hierarchical/radial support.

---

## 2026-09-21 — Scanner memory model: directories plus large files only
**Chosen:** Keep the full directory tree; keep individual file nodes only above a size threshold; aggregate the rest per directory as "Smaller files"; track a global top-N of largest files.
**Alternatives:** One node per file (like `du` output), or directories only.
**Why:** The Home folder holds millions of files; one node per file would cost hundreds of MB. A directories-only model would lose the "large files" insight.
**Trade-offs:** Can't drill into individual small files. The threshold must be tuned with real measurements (Phase 3).
**Revisit if:** Phase 3 measurements show memory is not a concern at full granularity.

---

## 2026-09-21 — Localization prepared, English only at launch
**Chosen:** String Catalog from day one; English is the development language; the app name "Temizlikci" is also a catalog entry.
**Alternatives:** Hardcoded English.
**Why:** User requirement: English by default. Turkish is a likely later addition, and retrofitting strings is expensive.
**Trade-offs:** Slight overhead per string.
**Revisit if:** Never. Just add languages.

---

## 2026-09-22 — Custom validated chart palette instead of system colors
**Chosen:** An 8-slot categorical palette with separate light/dark values (light `#2a78d6 #eb6834 #1baf7a #eda100 #e87ba4 #008300 #4a3aa7 #e34948`, dark `#3987e5 #d95926 #199e70 #c98500 #d55181 #008300 #9085e9 #e66767`), a neutral for "Smaller items", and the fixed status pair `#0ca30c` / `#fab219` for safety highlighting. All other UI color stays system colors.
**Alternatives:** macOS system colors (`Color.blue`, `.orange`, …) for chart segments.
**Why:** HIG prefers system colors, but measured on this Mac they fail as an adjacent-segment chart palette: light-mode yellow is outside the lightness band (L 0.87), and dark-mode green↔orange collapse for deuteranopia (ΔE 4.9). The custom palette passes every validator check in both modes on the real macOS surfaces (#ffffff / #1e1e1e). HIG explicitly allows custom colors if they have light, dark, and increased-contrast variants.
**Trade-offs:** Three light-mode slots are below 3:1 against the surface, so visible labels and the synchronized list are mandatory, not optional. Increased Contrast variants still have to be derived and validated (Phase 2). Colors don't follow future system color tweaks automatically.
**Revisit if:** Apple publishes chart-oriented system colors, or real use shows slot confusion.

---

## 2026-09-22 — Xcode project written by hand with folder-synchronized groups
**Chosen:** A hand-authored `project.pbxproj` (objectVersion 77) using `PBXFileSystemSynchronizedRootGroup` for `Temizlikci/` and `TemizlikciTests/`, plus a shared scheme. Adding or moving Swift files never touches the project file.
**Alternatives:** Developer creates the project from the Xcode template; XcodeGen or Tuist.
**Why:** No manual clicks and no extra tooling. Synchronized groups keep the project file static, so later phases only add sources. Settings mirror the Xcode 26 macOS template, verified by `xcodebuild -list`, `build`, and `test`.
**Trade-offs:** Target-level changes (new targets, entitlements) are edited by hand or in Xcode.
**Revisit if:** A second target (e.g. menu bar helper, widget) is needed. Then consider XcodeGen.

---

## 2026-09-22 — Swift 6 mode with the Xcode 26 concurrency defaults
**Chosen:** `SWIFT_VERSION = 6.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES` for the app and the tests.
**Alternatives:** Nonisolated default with explicit `@MainActor` everywhere.
**Why:** Most code is UI and belongs on the main actor. Default isolation removes annotation noise and makes the off-main work explicit: the scanner and tool runner (Phases 3 and 6) are marked `nonisolated` or actors, which is exactly where review attention belongs.
**Trade-offs:** Off-main types must opt out explicitly. Test argument tables must be `nonisolated`.
**Revisit if:** Background work grows beyond a few well-defined services.

---

## 2026-09-22 — Hand-maintained String Catalog behind an `L10n` namespace
**Chosen:** All strings are `LocalizedStringResource` constants in `Resources/Strings/L10n.swift` (key, English default, translator comment). `Localizable.xcstrings` holds the same keys with `extractionState: manual`. `STRING_CATALOG_GENERATE_SYMBOLS = NO`. `StringCatalogTests` fails if code and catalog drift or a key is orphaned.
**Alternatives:** String literals in views with automatic extraction; Xcode 26 generated string symbols.
**Why:** The user's rules require a central strings file and no literals in views. A test-enforced catalog works identically from the command line and from Xcode. Generated symbols add a build-time naming layer that is not needed on top of `L10n`.
**Trade-offs:** Adding a string means editing two files; the test points out any miss.
**Revisit if:** Xcode's generated symbols become the clearer single source.

---

## 2026-09-22 — Menu commands ship with the feature that makes them work
**Chosen:** Phase 2 adds only working commands: Choose Folder… (Command-O), Highlight Reclaimable (disabled until results exist), and the system sidebar/inspector commands. Rescan (Command-R), Back/Forward (Command-[ / Command-]), Enclosing Folder (Command-Up Arrow), and Move to Trash (Command-Delete) arrive with Phases 4 and 5. The Scan button arrives with the chart in Phase 4.
**Alternatives:** Wire every planned command to an empty action now (the original Phase 2 wording).
**Why:** Empty actions are stub implementations, which the project rules forbid, and a visible command that does nothing is a broken promise to the person using it.
**Trade-offs:** The shell shows fewer menu items for now.
**Revisit if:** Never. This is the rule going forward.

---

## 2026-09-22 — Increased-contrast colors verified in sources, not at runtime
**Chosen:** `ChartPaletteTests` checks light and dark through AppKit at runtime, and all four variants (including increased contrast) in the colorset sources. Increased contrast was confirmed present in the compiled `Assets.car` with `assetutil --info`.
**Alternatives:** Resolve under `NSAppearance.Name.accessibilityHighContrastAqua` / `…DarkAqua`.
**Why:** Tried first. AppKit does not resolve catalog high-contrast variants through those public names; the compiled catalog stores them under internal accessibility appearances (`NSAppearanceNameAccessibilitySystem`, `NSAppearanceNameAccessibilityDarkAqua`) chosen from the system setting. Testing them at runtime would need private API.
**Trade-offs:** The runtime selection under Increase Contrast is verified by eye, not by a test.
**Revisit if:** Apple exposes a public way to resolve increased-contrast variants.
