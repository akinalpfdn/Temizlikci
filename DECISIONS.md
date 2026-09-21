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
