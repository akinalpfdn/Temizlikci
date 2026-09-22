# Temizlikci — Development Plan

## Overview
Temizlikci is a native macOS app that shows, folder by folder, what is using disk space — as an interactive sunburst chart paired with a sortable list — and helps developers reclaim space safely. It recognizes developer artifacts (Xcode, simulators, Android/Gradle, Node, Flutter, Go, build folders) and labels each one as safe to trash, removable only through its owning tool, or user data that should not be touched.

It exists because a developer Mac regrows ~100 GB of caches per month, generic analyzers do not know which of those folders are safe, and developer-specific cleaners (e.g. DevCleaner) only cover Xcode.

The app name is **Temizlikci**. Every other user-facing string is **English**.

## Platform & Stack
- Target: macOS 26 (Tahoe) minimum. Apple silicon only.
- Toolchain: Xcode 26.6 (macOS 26.5 SDK), Swift 6.3, Swift 6 language mode with strict concurrency. Migrate to Xcode 27 when the developer moves to macOS 27 (Xcode 26.6 does not run on macOS 27).
- Framework: SwiftUI first. AppKit only where SwiftUI has no equivalent (e.g. `NSWorkspace` for Finder reveal and Trash, `NSOpenPanel`).
- Charts: custom SwiftUI `Canvas`-based sunburst renderer (see DECISIONS.md). Swift Charts is used for secondary, conventional charts (e.g. category bar chart) where its built-in accessibility is a free win.
- Key dependencies: none at MVP. Sparkle (auto-update) is a post-MVP candidate.
- Architecture: MVVM — one `@Observable`, `@MainActor` ViewModel per screen; Views render state only. Services are protocol-backed and injected.
- Design patterns: Strategy for cleanup rules (each developer-artifact rule is a strategy that matches paths and describes its cleanup action); Composite for the file tree; Observer via `@Observable` / `AsyncStream` for scan progress.
- Localization: **Prepared for future.** English is the development language. All user-facing strings live in a String Catalog (`Localizable.xcstrings`), including the app name. No string literals rendered directly in views.
- Theming: **System-following Light + Dark**, respecting the system accent color, Increase Contrast, Reduce Transparency, and Reduce Motion. All colors, typography, spacing, radii, and chart palettes come from a central `Theme` module. No raw colors or font sizes in view code.

## Constraints & Platform Considerations
- **Not sandboxed; distributed outside the Mac App Store.** The App Sandbox prevents launching `xcrun simctl` and scanning arbitrary system locations. Distribution is a Developer ID–signed, notarized DMG with Hardened Runtime enabled.
- **Full Disk Access (FDA) cannot be requested via a system prompt, and there is no public API to query it.** Detect it by probing a known TCC-protected location. Verify which location is reliable on macOS 26 before relying on it. Deep-link people to System Settings › Privacy & Security › Full Disk Access (verify the `x-apple.systempreferences` URL on macOS 26). Per HIG Privacy: do not ask at launch. Ask in context when a scan hits protected folders, and explain why.
- **Scanning without FDA must still work.** Protected folders appear as a distinct "Needs access" segment rather than silently shrinking totals.
- **Firmlinks and volumes.** On macOS the system volume (`/`) and the Data volume are joined by firmlinks; scanning `/` naively double-counts `/System/Volumes/Data`. The scanner must never cross into a different volume than the one being scanned, must skip mounted disk images (e.g. `/Library/Developer/CoreSimulator/Volumes/*`, which inflated `du` by ~57 GB on this machine), and must not follow symlinks.
- **Hard links** are counted once (dedupe by file identity when the link count is greater than 1). **APFS clones** cannot be attributed correctly — macOS offers no API to find shared clone blocks. Totals may therefore exceed the real used space; the UI states this honestly.
- **Use allocated (on-disk) size**, not logical size, so sparse files and small-file overhead are represented correctly.
- **"Other" space must be explained.** The difference between the volume's used capacity and scanned totals (APFS snapshots, purgeable space, other volumes in the container, unreadable folders) is shown as its own labelled segment, not hidden.
- **Moving to Trash does not free space until the Trash is emptied.** The UI must make this clear after every trash action and show how much reclaimable space currently sits in the Trash.
- **Tool-owned items** (simulator runtimes and devices, Homebrew caches, Android SDK packages) are removed only through their tool (`xcrun simctl runtime delete`, `xcrun simctl delete unavailable`, `brew cleanup`, …), launched via `Process` with full argument arrays (no shell interpolation). Simulator runtimes live in root-owned `/Library/Developer/CoreSimulator`; `simctl` may trigger an admin authorization prompt.
- **The app never runs as root and ships no privileged helper.** SIP already protects `/System`; running unprivileged is the primary safety guarantee.
- **Scale.** The home folder on this machine holds several million files. A node per file is too much memory: keep full directory structure, keep individual files only above a size threshold, aggregate the rest per directory as "Smaller files", and track a global top-N of largest files separately.

## Design Direction (HIG-driven)
Sources and extracted guidance: `claudedocs/hig-research-2026-09.md`. Non-negotiables:
- **Liquid Glass only in the control layer.** The sidebar, toolbar, and inspector get their glass from system components. The chart, list, and backgrounds sit in the content layer on standard materials. No `glassEffect` on content. Use custom glass sparingly, if at all.
- **The sunburst is a novel chart type.** Pair it with a conventional sortable, searchable list of the same data. Teach it through a brief, interactive, optional introduction (HIG Onboarding): if skipped it never reappears, and it stays reachable from the Help menu. Never require hovering or clicking to reveal critical information: the selected folder's name, size, and share are always visible as text.
- **Never encode meaning in color alone.** Put separators between adjacent segments, use text labels on large segments, and apply a consistent color per category (developer artifact, media, apps, system, other) in both the chart and the list.
- **Accessibility from day one:** an accessibility element with a label for every meaningful segment, an `AXChartDescriptor` for Audio Graphs, full keyboard navigation (arrows move between siblings and rings, Return drills in, Escape goes up), plus Reduce Motion and Increase Contrast variants.
- **Sidebar with at most two levels.** It holds locations and insights only, never the folder tree. Sidebar icons follow the system accent color unless a fixed color carries meaning.
- **Every toolbar action is also a menu-bar command** with a standard keyboard shortcut (e.g. Option-Command-I shows the inspector, Command-F finds; Show/Hide Sidebar lives in the View menu). Verify each shortcut against `claudedocs/hig/keyboards.md` before assigning.
- **Alerts:** no alert for undoable Trash moves (offer Undo instead). Irreversible tool deletions get an alert with a specific verb ("Delete Runtime"), a Cancel button, and no destructive default.
- **Writing:** plain language; title-style capitalization for buttons, menu items, and fragment titles ("Move to Trash", "Delete Runtime"); sentence-style capitalization with ending punctuation for complete sentences and informative text; sizes formatted by the system (`ByteCountFormatStyle`), never abbreviated by hand; empty states give a clear next step; no jargon in primary UI. Developer detail lives in the inspector.

## Architecture
```
┌──────────────── App ────────────────┐
│ TemizlikciApp · Scenes · Commands   │  menu bar, shortcuts, window
└──────────────┬──────────────────────┘
┌──────────────▼──────────────────────┐
│ Features (View + ViewModel pairs)   │
│  Overview (sunburst + list)         │
│  Inspector (selection details)      │
│  Developer (artifact insights)      │
│  Access (FDA onboarding)            │
└──────────────┬──────────────────────┘
┌──────────────▼──────────────────────┐
│ Domain                              │
│  FileNode tree · SizeCategory       │
│  CleanupRule · SafetyLevel          │
│  ScanSnapshot · VolumeUsage         │
└──────────────┬──────────────────────┘
┌──────────────▼──────────────────────┐
│ Services (protocols, injected)      │
│  DiskScanner      (off-main, async) │
│  VolumeInfoService                  │
│  TrashService     (move / put back) │
│  ToolRunner       (Process wrapper) │
│  AccessService    (FDA probe/link)  │
│  RuleEngine       (applies rules)   │
└─────────────────────────────────────┘
Theme (tokens) and Strings (String Catalog) are shared by all layers above Services.
```
- **Data flow:** a ViewModel starts a scan → `DiskScanner` enumerates concurrently (bounded task group, never on the main actor) and emits progress snapshots through an `AsyncStream` → the ViewModel publishes coalesced snapshots (a few per second) → Views render them. Results appear progressively; the largest folders settle first.
- **State:** the current scan tree is owned by the Overview ViewModel. Selection and navigation path (breadcrumb) are ViewModel state. Nothing is persisted at MVP; the post-MVP scan history uses a small on-disk snapshot store.
- **Cancellation:** every scan and tool invocation is cancellable. Tasks store their handles and cancel on teardown.

## Feature Scope
### MVP
- Scan a location (startup disk's Data volume, Home, or any folder chosen via open panel) with live progress and cancellation.
- Correct sizes: allocated size, hard-link dedupe, no volume or symlink crossing, mounted images skipped, "Other / not scanned" segment explained.
- Sunburst chart with drill-down, breadcrumb, hover highlight, and selection; always-visible summary text.
- Sortable, searchable list synchronized with the chart selection.
- Inspector: path, size, item count, last modified, category, safety label, actions.
- Reveal in Finder, Quick Look, Move to Trash with Undo; Trash size awareness.
- Full Disk Access onboarding in context.
- Developer insights: rule catalog for Xcode (DerivedData, iOS DeviceSupport, Archives, Previews, DocumentationCache), simulator runtimes and devices, Gradle, Android AVDs and system images, `node_modules`, Flutter `build/` and `.dart_tool/`, Go build cache, Homebrew cache, npm cache. Each rule has a safety level: **Safe to remove** (regenerates), **Remove with tool** (runs the owning tool), or **Keep** (user data, e.g. messaging app containers, Application Support).
- Tool actions for simulators (delete unavailable devices, delete a runtime) with a confirmation alert.

### Post-MVP (user-approved 2026-09-22)
- **What Grew:** keep a lightweight snapshot of every scan and show what grew or shrank since the previous one (per folder and per developer artifact).
- **Stale Projects:** find projects nobody has touched for a while and show how much build output they hold (per-item actions only; no bulk clean).
- **Other Used Space breakdown:** split the unattributed segment into purgeable space, local Time Machine snapshots, folders not read without Full Disk Access, the Trash, and the remainder.
- **More developer rules:** Docker, CocoaPods, SwiftPM, Rust, Unity, Gradle project builds, Maven, JetBrains, Yarn/pnpm/Bun caches, Python caches; drag items onto the sidebar Trash.
- **What is this folder?:** deterministic identification first, then an optional, labeled on-device explanation (Foundation Models). Informational only.
- Declined: one-click "Clean All Safe", menu bar extra (see DECISIONS 2026-09-22).
- Later: Turkish localization, Sparkle updates.

## Phases
Phase files live in `.claude/phases/`. Each phase is one Claude Code session. Only one phase is active; the next starts only with the developer's approval.

### Phase 1 (001-MVP-01): Design direction & mockups
**Goal:** An approved visual design exists before any UI code is written.
**Delivers:** A one-sentence visual direction; a design canvas (Artifact) with the main window in light and dark mode — sidebar, sunburst plus list, inspector, FDA onboarding state, empty/scanning state, and a Developer insights view; category color palette validated for contrast in both modes; app icon concept.
**Depends on:** Nothing.
**Acceptance criteria:**
- [ ] Design follows every item in "Design Direction (HIG-driven)"
- [ ] Category palette passes contrast checks in light, dark, and Increase Contrast
- [ ] Developer approves the design (explicit gate)

### Phase 2 (002-MVP-02): Project foundation
**Goal:** A buildable, empty-but-real app shell with the theme, strings, and quality tooling in place.
**Delivers:** Xcode project (macOS App, SwiftUI, Swift Testing, folder-synchronized groups; created from the Xcode template by the developer or generated — decide at phase start); bundle ID, Hardened Runtime, no sandbox entitlement; `Theme` module with tokens from Phase 1; `Localizable.xcstrings`; window with `NavigationSplitView` (sidebar, content, inspector) showing placeholder states; menu commands wired to no-op actions; test target running; README, `.gitignore`, and a `CLAUDE.md` context update.
**Depends on:** Phase 1.
**Acceptance criteria:**
- [ ] `xcodebuild build` and `xcodebuild test` succeed from the command line
- [ ] No hardcoded colors, fonts, or user-facing strings in views
- [ ] Light, Dark, Increase Contrast, and Reduce Transparency render correctly

### Phase 3 (003-MVP-03): Scan engine
**Goal:** A fast, correct, cancellable scanner with tests, independent of UI.
**Delivers:** `DiskScanner` (bounded concurrency, allocated sizes, hard-link dedupe, same-volume enforcement, symlink and mount skipping, firmlink-aware root handling); the memory strategy (directory tree plus top-N files plus per-directory "Smaller files"); `VolumeInfoService` with used, available, and important-usage capacity; progress `AsyncStream`; permission-denied folders recorded, not dropped; fixture-based tests (nested dirs, hard links, symlink loops, unreadable folders).
**Depends on:** Phase 2.
**Acceptance criteria:**
- [ ] Totals for test fixtures match expected sizes exactly
- [ ] On a real folder, totals are within 1% of `du -skx` for the same folder, and the scanner is not slower than `du` (measure and record both in the phase file)
- [ ] Cancelling mid-scan stops all work promptly and leaks no tasks
- [ ] Peak memory for a full Home scan is measured with Instruments and recorded

### Phase 4 (004-MVP-04): Sunburst, list & navigation
**Goal:** People can see and navigate what uses their disk.
**Delivers:** Canvas sunburst (rings by depth, tiny segments merged, separators, labels on large segments, hover and selection, animated drill-down honoring Reduce Motion); breadcrumb; list synced with chart; search; inspector details; Reveal in Finder and Quick Look; progressive rendering during scans; accessibility (segment elements, `AXChartDescriptor`, keyboard navigation).
**Depends on:** Phase 3.
**Acceptance criteria:**
- [ ] UI stays responsive during a full scan (no main-thread hitches visible in Instruments)
- [ ] VoiceOver can reach and describe every visible segment and list row; Audio Graphs available
- [ ] Every action is reachable from the keyboard and the menu bar

### Phase 5 (005-MVP-05): Actions & access
**Goal:** People can safely reclaim space and grant access when needed.
**Delivers:** `TrashService` (move to Trash, Undo via put-back, error reporting per item); post-action tree update without a rescan; Trash size indicator and guidance; `AccessService` with FDA probe, contextual onboarding view, and System Settings deep link; recheck on app activation; explicit error states.
**Depends on:** Phase 4.
**Acceptance criteria:**
- [ ] Move to Trash and Undo work, and are covered by tests on fixtures
- [ ] No alert for undoable actions; failures are reported specifically, never silently
- [ ] FDA flow verified on macOS 26 with access both granted and denied

### Phase 6 (006-MVP-06): Developer insights
**Goal:** Developer artifacts are recognized and cleaned with the right method.
**Delivers:** `CleanupRule` strategy catalog and `RuleEngine`; safety badges in chart, list, and inspector; Developer view grouping artifacts by ecosystem with reclaimable totals; `ToolRunner` for `xcrun simctl` (list runtimes, delete runtime, delete unavailable devices) with confirmation alerts; per-rule explanation text ("Regenerates on next build").
**Depends on:** Phase 5.
**Acceptance criteria:**
- [ ] Each rule has a test proving it matches its targets and does not match look-alikes
- [ ] "Keep" items never offer a delete action
- [ ] Tool actions show progress and report output; failures surface the tool's error

### Phase 7 (007-MVP-07): Polish & release
**Goal:** A signed, notarized build the developer can use daily and share.
**Delivers:** Layered app icon via Icon Composer; optional interactive sunburst introduction (reachable from Help); empty, error, and low-space states reviewed; performance pass; accessibility audit (VoiceOver, Full Keyboard Access, contrast, motion); Developer ID signing, notarization, and DMG (via the `mac-release` skill).
**Depends on:** Phase 6.
**Acceptance criteria:**
- [ ] Notarized DMG installs and runs on a clean user account
- [ ] Accessibility audit checklist completed and recorded
- [ ] HIG compliance review against `claudedocs/hig-research-2026-09.md` completed

## Implementation Guidelines
These apply to ALL phases. Claude Code must follow these throughout development.

- Follow SOLID principles, especially Single Responsibility and Dependency Inversion. Services are protocols and are injected into ViewModels; nothing creates its own dependencies.
- Apply design patterns where they remove complexity (Strategy for rules, Composite for the tree). Don't force patterns elsewhere.
- Write clean, self-documenting code. Comments explain "why", never "what".
- No hardcoded values. Thresholds, concurrency limits, and ring counts live in named configuration constants.
- **Theming must be centralized.** Colors, typography, spacing, radii, and chart palettes live in `Theme`. Views consume tokens only. Prefer semantic system colors and materials; custom category colors must define light, dark, and high-contrast variants.
- **Localization-ready.** Every user-facing string, including the app name, alert text, and accessibility labels, goes through `Localizable.xcstrings`. Sizes and dates use system formatters (`ByteCountFormatStyle`, date formatting), never hand-built strings.
- **Concurrency (Swift 6 strict).** ViewModels are `@MainActor`. Scanning and tool execution never run on the main actor. Every stored `Task` is cancelled on teardown. Use `Task.detached` only with a comment explaining why.
- **Safety first for anything destructive.** Deletion goes only through `TrashService` or a tool strategy, never `removeItem` on user content. Every destructive path is tested on fixtures in a temporary directory.
- Error handling must be explicit and meaningful: no silent catches and no generic "Something went wrong". Errors are typed enums conforming to `LocalizedError`.
- Tests use Swift Testing, with names that describe behavior. The scanner and the rules are tested against real temporary file trees, not mocks.
- Keep `DECISIONS.md` current. Re-read the active phase file after context compaction.
- Respect existing code patterns: read a file fully before modifying it.

## Risks & Watch Items
- **FDA detection reliability.** The probe path may change between macOS versions. Isolate it in `AccessService` and verify on each major macOS release.
- **Sunburst performance** with thousands of segments. Merge segments below a minimum angle, cap ring depth, and profile early in Phase 4.
- **Scanner memory** on multi-million-file volumes. Measure in Phase 3 before building UI on top of it.
- **APFS clones and snapshots** make "scanned total" ≠ "used space". Must be explained in the UI, or users will distrust the numbers.
- **`simctl` behavior changes** across Xcode releases. Parse its JSON output (`--json` / `-j`) rather than human-readable text, and handle authorization prompts.
- **Toolchain migration.** Moving to macOS 27 forces Xcode 27 (Swift 6.4, `@State` macro change is source-breaking for default-initialized state assigned in `init`). Budget a short migration session.
- **Open source vs private:** undecided. The repository is treated as private until decided; add LICENSE and public-repo hygiene if it goes public.
- **Lore tracking:** the project is not yet registered in Lore. Register it in the Lore app, then mirror the phases as work items.
