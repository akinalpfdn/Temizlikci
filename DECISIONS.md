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

---

## 2026-09-22 — Scan "/" and skip volume roots instead of mapping firmlinks
**Chosen:** The startup disk is scanned from `/`. Below the root, directories that are volume roots or mount triggers (`isVolume`, `isMountTrigger`) are skipped and symlinks are never followed.
**Alternatives:** Scan `/System/Volumes/Data` and map paths back to their firmlink names; or compare volume identifiers.
**Why:** Verified on this Mac: `/System/Volumes/Data`, Preboot, and mounted simulator images report `isVolume = true`, while firmlinks (`/Users`, `/opt`, `/private`) are plain directories, and `/` and the Data volume share one volume identifier. So one rule gives familiar paths and counts nothing twice; a volume-identifier rule would have wrongly excluded `/Users`.
**Trade-offs:** Data-volume folders that have no firmlink (e.g. `.Spotlight-V100`) aren't reached; they fall into the explained "unattributed" space.
**Revisit if:** A future macOS changes firmlink or volume-group behavior.

---

## 2026-09-22 — Consent-prompting folders are left unread without Full Disk Access
**Chosen:** `ScanConfiguration.forScan(access:)` probes Full Disk Access (reading the system `TCC.db`, which fails silently). Without it, `ProtectedLocations` (Desktop, Documents, Downloads, Music, Pictures, Movies, iCloud Drive, CloudStorage, Containers, Group Containers) are never opened and appear as "Needs access" nodes.
**Alternatives:** Read everything and let macOS prompt.
**Why:** A home-folder benchmark triggered one consent prompt per protected folder (Music observed) and alarmed the developer. That violates HIG Privacy (ask once, in context). The app will ask for Full Disk Access once, with an explanation (Phase 5).
**Trade-offs:** The folder list is partly empirical: the documented set is Desktop, Documents, Downloads, iCloud Drive, and cloud storage; Music was observed; Pictures, Movies, and app data are included conservatively. An unlisted prompting folder would still prompt once.
**Revisit if:** Any other folder prompts during a scan (add it), or Apple documents the full set.

---

## 2026-09-22 — Unit tests run in a windowless host
**Chosen:** `AppEntry` (`@main`) runs a windowless `TestHostApp` with activation policy `.prohibited` when XCTest environment variables are present; otherwise it runs `TemizlikciApp`.
**Alternatives:** Hostless test bundle (impossible for `@testable import` of an app target); accept windows opening during tests.
**Why:** Each `xcodebuild test` launched a visible Temizlikci window, which the developer experienced as the machine being flooded.
**Trade-offs:** A Dock icon may flash briefly at launch, before the policy applies.
**Revisit if:** UI tests are added (they need the real app).

---

## 2026-09-22 — Scanner memory: autorelease pool per directory; large files come from the tree
**Chosen:** Each directory read runs inside `autoreleasepool`. The Large Files view will be derived from file nodes above the threshold (10 MB) instead of a separate global top-N structure.
**Alternatives:** Keep the planned global top-N heap.
**Why:** Measured on `~/Documents/GitHub` (561k files, 93k folders): peak RSS fell from 336 MB to 219 MB with the pool, with totals still identical to `du -skx`. File nodes above the threshold already are the large files, so a heap would duplicate them.
**Trade-offs:** The Large Files view traverses the tree (cheap compared to scanning).
**Revisit if:** Home-folder memory is too high. The next step is storing names instead of URLs in nodes.

---

## 2026-09-22 — Highlight Reclaimable returns with the cleanup rules (Phase 6)
**Chosen:** The toggle and its menu item were removed in Phase 4 and come back in Phase 6.
**Alternatives:** Keep a permanently disabled toggle until then.
**Why:** Results now exist, so "disabled until results" no longer holds. Without cleanup rules the toggle would paint everything gray, and a control that can't do anything is a broken promise.
**Trade-offs:** The toolbar changes again in Phase 6.
**Revisit if:** Never. It ships with the rules.

---

## 2026-09-22 — Chart interaction model
**Chosen:** Click selects; double-click or Return opens a folder; clicking the center or pressing Escape goes up. Left/Right move between siblings (wrapping); Up moves to the parent ring and Down to the largest child ring. Space or Command-Y opens Quick Look; Option-Command-R reveals in Finder. Command-R rescans and Command-Period stops (HIG: "Cancel an operation"). Back, Forward, and Enclosing Folder use Command-[, Command-], and Command-Up Arrow (Finder precedent; the app has no text editing, so the HIG alignment meanings don't apply).
**Alternatives:** Single click opens (common in sunburst tools).
**Why:** The approved design and HIG: selection must be possible without navigating, so the inspector can show details and actions for any segment.
**Trade-offs:** Opening takes a double-click, which is also available as Return and as the list's primary action.
**Revisit if:** People expect single-click drill-down in testing.

---

## 2026-09-22 — Navigation keeps value snapshots of the tree
**Chosen:** `LocationScanModel` stores the navigation path, back/forward stacks, and selection as `FileNode` values, plus a per-folder map from node ID to its chain of ancestors (only for nodes reachable through the three drawn rings or search).
**Alternatives:** Parent pointers in a class-based tree; an index of every node.
**Why:** `FileNode` stays an immutable Sendable value produced off the main actor; chains cover exactly what can be selected, without indexing millions of nodes.
**Trade-offs:** After Move to Trash (Phase 5) the path must be rebuilt from the updated tree.
**Revisit if:** Tree edits become frequent enough that rebuilding paths shows up in profiles.

---

## 2026-09-22 — Skip the virtual root folders `/.nofollow`, `/.resolve`, `/.vol`
**Chosen:** `ScanConfiguration.skippedPaths` defaults to these three paths; they are never visited or shown.
**Alternatives:** Detect aliasing generically (inode or identifier comparison).
**Why:** The first in-app startup-disk scan reported 731 GB on a 494 GB disk: `/.nofollow` (419 GB) exposes the whole volume again. On this Mac these entries are ordinary-looking directories (not volume roots, not symlinks) with their own inode numbers, so neither the mount rule nor an inode check can catch them.
**Trade-offs:** An explicit list. A future macOS could add another virtual folder.
**Revisit if:** A scan's total exceeds the volume's used capacity again. That is the tell-tale sign; consider asserting it in the app and surfacing it.

---

## 2026-09-22 — Move to Trash: no confirmation, system Undo, tree edited in place
**Chosen:** Move to Trash (inspector, list context menu, Edit menu Command-Delete) runs without an alert, registers with the window's `UndoManager` (Edit › Undo), and shows a transient confirmation with Undo. The tree is edited in place (`removingDescendant` / `insertingDescendant`). For whole-volume scans, trashed space moves into Other Used Space, because it isn't freed until the Trash is emptied. A session ledger lists trashed items with Put Back.
**Alternatives:** A confirmation alert; rescanning after each action; emptying the Trash from the app.
**Why:** HIG Alerts: don't alert for common undoable destructive actions. Rescanning a disk takes minutes. Emptying the Trash through Finder scripting would need Automation permission, and emptying the Trash is Finder's job; the app tells people the space is freed then.
**Trade-offs:** Put Back fails if something now occupies the original path; the error explains how to recover in Finder. The real `FileManager.trashItem` call isn't exercised by tests on purpose, so tests never touch the developer's Trash; it gets verified in the live test.
**Revisit if:** People want to empty the Trash without leaving the app.

---

## 2026-09-22 — Full Disk Access: banner after the scan, settings deep link, recheck on activation
**Chosen:** After a scan that skipped protected folders and without Full Disk Access, a banner explains what was skipped and offers "Open Privacy Settings…" (legacy `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles` URL) or "Not Now". Access is re-probed whenever the app becomes active, and the banner tells people to quit and reopen after turning access on.
**Alternatives:** Ask at launch; a modal sheet before the first scan.
**Why:** HIG Privacy: request only when needed, in context, with a clear reason. The first scan itself shows why access matters.
**Trade-offs:** The URL form must be verified on each macOS release.
**Revisit if:** The deep link stops opening the right pane.

---

## 2026-09-22 — Cleanup rules: a data catalog of strategies, matched after the scan
**Chosen:** `CleanupRule.catalog` lists each artifact with an ecosystem, a safety level, a reason, an action, and a matcher: an exact path (`~`-relative or absolute), a child-of pattern (simulator runtime assets under `/System/Library/AssetsV2`), or a project folder beside a marker file (`build` + `pubspec.yaml`, `node_modules` + `package.json`). `RuleEngine` walks the finished tree off the main actor (`@concurrent`), stops at the first match on each branch (outermost `node_modules` only), and checks marker files on disk, because small files aren't nodes in the tree. Matches cover everything below them.
**Alternatives:** Matching during the scan; name-only matching (every `build` folder).
**Why:** Keeps the scanner rule-agnostic and fast. Marker files avoid calling unrelated `build` folders "safe". Measured on this Mac: runtime images live in `/System/Library/AssetsV2/com_apple_MobileAsset_*SimulatorRuntime`, not only in `/Library/Developer/CoreSimulator`.
**Trade-offs:** Rule matching re-runs after every tree edit, which is a full directory walk (still cheaper than rescanning).
**Revisit if:** Profiling shows the walk is noticeable, or users want custom rules.

---

## 2026-09-22 — Safety levels decide what the app offers
**Chosen:** Safe to Remove → Move to Trash. Remove with Tool → only the owning tool (simctl sheet actions, or opening Android Studio); Move to Trash is disabled for these items and anything inside them. Keep → no delete action anywhere (inspector, list, Developer view, Edit menu). Highlight Reclaimable colors matched segments with the status colors (always paired with a symbol and a label) and fades everything else.
**Alternatives:** Allow trashing tool-owned folders.
**Why:** Deleting simulator folders behind simctl's back leaves Xcode's device list inconsistent; the DEVPLAN requires tool-owned removal.
**Trade-offs:** Tool-owned items take more steps to remove.
**Revisit if:** A tool offers no safe command-line or UI path.

---

## 2026-09-22 — Irreversible simctl actions: alert with a specific verb; Return confirms
**Chosen:** Deleting unavailable simulators and deleting a runtime show an alert with a specific button ("Delete Simulators" or "Delete Runtime") and Cancel. The action button is the SwiftUI default (Return).
**Alternatives:** No default button (the DEVPLAN's first intent).
**Why:** SwiftUI alerts don't offer "no default button". HIG treats a deliberately chosen destructive action like Empty Trash as fine to confirm with Return, without destructive styling. The alert text states "This can't be undone" and the size.
**Trade-offs:** A quick Return confirms.
**Revisit if:** Moving the alert to AppKit (`NSAlert`) becomes worthwhile for control over the default button.

---

## 2026-09-22 — Post-MVP scope (user decision)
**Chosen:** Build "What Grew" (scan history and growth between scans), Stale Projects (build output in projects untouched for a while), an Other Used Space breakdown, more developer rules (plus drag to the sidebar Trash), and a "What is this folder?" explanation. AI is limited to that explanation.
**Alternatives:** One-click "Clean All Safe"; a menu bar extra with low-space alerts; an AI cleanup planner.
**Why:** User decision. Bulk clean was rejected: "safe to remove doesn't mean I want to remove it", so every deletion stays a deliberate, per-item action. Menu bar extra: not needed. AI planning was rejected because hallucinated advice in a deletion tool can cause data loss; the folder explanation is informational only.
**Trade-offs:** Cleaning many items takes more clicks.
**Revisit if:** The user asks for batch actions with an explicit, reviewable selection.

---

## 2026-09-22 — "What is this folder?" never changes safety or triggers actions
**Chosen:** The explanation first tries deterministic sources (installed apps by bundle identifier, known system folders, the rule catalog); only unknown folders get an on-device Foundation Models explanation. That explanation is labeled as generated, is optional, needs Apple Intelligence, and never alters a safety label or offers a delete action.
**Alternatives:** Always ask the model; use a cloud model.
**Why:** Accuracy and privacy: folder paths stay on the Mac, and deterministic answers are right more often than a small model.
**Trade-offs:** Unavailable on Macs without Apple Intelligence.
**Revisit if:** Moving to Xcode 27 (the macOS 27 model is better at reasoning and tool calling).

---

## 2026-09-22 — What Grew: compact local snapshots, compared with the previous scan
**Chosen:** After each finished scan, a snapshot records sizes by path for the top two levels, anything ≥ 100 MB, every cleanup match, and every path the previous snapshot recorded, plus the folders left unread. It's stored as LZFSE-compressed JSON in `~/Library/Application Support/Temizlikci/Snapshots/<location hash>/`, keeping the last 10 per location. Changes under 10 MB are ignored. The What Grew list hides a folder when one item inside it explains at least 80% of its change.
**Alternatives:** Store full trees; compare only top-level folders; keep history in memory only.
**Why:** Full trees would be hundreds of MB per scan. Recording the previous snapshot's paths means "missing" really means removed, not "shrank below the threshold". Unread folders (no Full Disk Access) are excluded so they never look like they shrank. Folder paths never leave the Mac.
**Trade-offs:** Items first seen above 100 MB show as "new or previously under 100 MB". Deep changes below 100 MB are invisible unless they're developer artifacts.
**Revisit if:** Snapshots on the startup disk grow large (measure), or finer history is wanted.

---

## 2026-09-22 — Growth direction as a warm/cool pair, not green and red
**Chosen:** Growth uses a warm ink (`GrowthUpInk`) and shrinking a cool one (`GrowthDownInk`), each with light, dark, and both increased-contrast variants at 5.4:1 or better on the list background. Direction is also carried by the arrow symbol, the +/− sign, the "Grew"/"Shrank" section heading, and a bar whose length is the change.
**Alternatives:** Reuse the status colors (green/amber); red for growth and green for shrinking; stay monochrome.
**Why:** Green already means "safe to remove" in the same lists, and red means an error elsewhere in the app; reusing them would make two different things look alike. A warm/cool pair stays distinguishable under every kind of color vision, and nothing depends on color alone (HIG "Charts", "Color").
**Trade-offs:** Two more colors to keep validated.
**Revisit if:** The palette is retuned, or growth needs a third state.

---

## 2026-09-22 — What Grew reads saved scans at launch
**Chosen:** When a location hasn't been scanned in this session, What Grew compares the two newest saved snapshots and says so; "Show in Chart" is disabled until there's a live scan. A finished scan replaces that comparison.
**Alternatives:** Show history only after a scan (the previous behavior); rescan automatically at launch.
**Why:** History that disappears when the app quits is worthless — the developer said so directly. Snapshots were already on disk; only the comparison was tied to a scan. Scanning automatically at launch would spend minutes of disk I/O nobody asked for.
**Trade-offs:** The numbers are as old as the last scan, so the view states its dates.
**Revisit if:** Background or scheduled scanning is added.

---

## 2026-09-22 — Stale projects: Git activity over folder dates, tool repositories excluded
**Chosen:** A folder is a project when it holds `.git` or an `*.xcodeproj`/`*.xcworkspace` (both visible in the scan tree), or when a marker file (`package.json`, `Package.swift`, `pubspec.yaml`, `Cargo.toml`, `build.gradle[.kts]`, `go.mod`) sits next to a folder that already contains a build artifact. "Last worked on" is `.git/index`/`HEAD`, or the newest file in the project's own top two levels with artifact folders skipped. Repositories under `~/Library`, `/Library`, `/System`, `/Applications`, `/opt`, `/usr` and `/private` are not listed, and the outermost project owns everything inside it.
**Alternatives:** Ask the disk for markers next to every folder; use folder modification dates; record the newest file date per folder during the scan.
**Why:** Marker lookups for every folder of a startup disk would be hundreds of thousands of extra file-system calls. A folder's date only changes when entries are added or removed, so editing a file leaves it untouched — Git's index is rewritten on every stage, commit and checkout, which is what "working on it" means. Storing a date per node would grow the tree in memory, which is already the tightest budget in the app. Homebrew taps and tool caches hold hundreds of repositories nobody works on; listing them would bury the developer's own projects.
**Trade-offs:** A project with no build output and no Git folder is not found; a project worked on only through a tool that doesn't touch Git may look older than it is; someone keeping real projects in `~/Library` won't see them.
**Revisit if:** Projects are missing in practice, or per-folder activity dates become cheap enough to record during the scan.

---

## 2026-09-22 — Other Used Space is explained from the disk's own layout
**Chosen:** The unattributed segment is split into named parts: the other volumes of the same APFS container (VM, Preboot, Recovery, Update), disk images mounted inside the disk (simulator runtimes), purgeable space, and an honest remainder. Volume usage comes from `diskutil apfs list -plist`, mount points from the kernel's mount table (`getmntinfo`), purgeable from the difference between available-for-important-usage and available capacity. When the named parts exceed the estimate, the total grows to hold them instead of scaling anything down.
**Alternatives:** Capacity APIs only; `tmutil listlocalsnapshots` for snapshots; running `du` over `/System/Volumes/*`.
**Why:** Every volume in an APFS container reports the container's free space, so capacity APIs cannot tell what each volume uses; `diskutil apfs list` can, and needs no privileges or permission prompt. On this Mac it showed 18.25 GB of VM swap, 9 GB of Preboot and ~26 GB of simulator runtimes in separate containers — space the scan steps over because it doesn't cross mount points, which is exactly why it looked unexplained. `tmutil` reported no snapshots here and their space is already counted as purgeable. Scaling parts to fit an estimate would invent numbers.
**Trade-offs:** Depends on `diskutil`'s plist output; if that changes or fails, the breakdown falls back to purgeable plus remainder. The figures are as of the end of the scan.
**Revisit if:** Snapshots need to be listed individually, or the app ever needs the breakdown without a scan.

---

## 2026-09-22 — Cache rules follow each tool's own documentation, not a guess
**Chosen:** 25 more rules, each labelled from the tool's current documentation (read 2026-09-22). "Remove with its tool" for: uv's cache (docs: "it's never safe to modify the cache directly"), pnpm's store (every node_modules links into it; `pnpm store prune` only removes what nothing references), NuGet global-packages (projects reference it directly; `dotnet nuget locals global-packages --clear`), Go's module cache (read-only; `go clean -modcache`), `~/.rustup` (installed toolchains, not a cache), and Docker's disk image (holds every image, container and volume; `docker system prune`). Safe to trash: SwiftPM, Xcode, CocoaPods, Yarn, Bun, electron, node-gyp, Playwright, pip and JetBrains caches, `~/.cargo/registry`, `~/.m2/repository`, and per-project `Pods`, `.build`, `target`, Gradle `build`, Unity `Library`.
**Alternatives:** Label everything under a cache folder as safe; skip the tools not installed on this Mac.
**Why:** Several of these look like plain caches and are not: uv and pnpm say so in their own docs, NuGet's folder is referenced directly by projects, and deleting Docker's disk image loses every image and volume. A wrong label here costs someone their data, so each one is sourced. Rules for tools that aren't installed cost nothing and help on another Mac.
**Trade-offs:** The catalog grows to 49 rules and has to be rechecked when tools change their layout.
**Revisit if:** A tool moves its cache, or the reasons drift from current docs.

---

## 2026-09-22 — The rule search continues inside folders labelled "keep"
**Chosen:** A match stops the search below it, except when its safety is "keep".
**Alternatives:** Always stop at the first match.
**Why:** `~/Library/Containers` is labelled "keep" (app data), and Docker Desktop stores its disk image inside it. Stopping there meant Docker's tens of gigabytes had no label at all.
**Trade-offs:** A folder to keep and a rule inside it are both listed; the nesting is visible in the paths.
**Revisit if:** Kept folders ever get numerous rules inside them and the list becomes noisy.

---

## 2026-09-22 — The last scan is cached and shown at launch
**Chosen:** Every finished scan is written as one compressed archive per location (`Application Support/Temizlikci/Scans`). Opening a location shows that archive straight away; when it is older than the period in Settings (default 3 days, "never" available) a scan starts in the background, leaves the old tree on screen while it runs, and on finish returns the person to the folder they had open. The archive is a compact binary format: pre-order nodes with names only, paths rebuilt from the parent, fixed-width little-endian numbers. Moving to the Trash or undoing rewrites it.
**Alternatives:** Scan on every launch (the old behavior); store the tree as JSON or a property list; refresh on every launch in the background; only refresh when asked.
**Why:** Measured on this Mac's home folder (1,849,681 files): scanning takes 34.4 s, while the archive is 5 MB compressed, takes 2.1 s to write and 1.35 s to read back. Keeping full paths per node would have made the file several times larger, so names plus the parent's URL are stored instead. The developer chose age-based refreshing: always refreshing would spend minutes of disk I/O on every launch, and never refreshing would quietly show stale numbers.
**Trade-offs:** The tree can be up to the chosen period old, so the footer states its age. A cached result has no duration to report, and What Grew compares saved snapshots until a real scan runs.
**Revisit if:** Archives get large on a full startup disk, or the format needs a field (bump `ScanArchive.version`; an older file is ignored, not misread).

---

## 2026-09-22 — "What is this?" answers from the Mac first, from the model only as a fallback
**Chosen:** An inspector card explains the selected item. It uses, in order: the cleanup rule that matched it, a catalog of the folders macOS defines, the installed app behind a container / group container / support folder (looked up by bundle identifier through `NSWorkspace`, or by name in the Applications folders), and a file's type. Only for a folder nothing recognizes is an on-device explanation offered, and only when the person presses "Explain This Folder". The generated text is labelled as written on this Mac by Apple Intelligence, says it can be wrong, is retryable, and never changes a safety label or offers an action. The prompt carries the folder's name, its path with the home folder replaced by `~`, its size and the names of at most eight items inside — never file contents. Without Apple Intelligence the card still explains everything deterministic and says why generation isn't offered.
**Alternatives:** Ask the model about everything; generate automatically on selection; send anything to a server.
**Why:** HIG "Generative AI": keep people in control, label AI clearly, prefer on-device, scope prompts to limit hallucinations, never let generated text drive destructive actions, and work without the feature. Deterministic answers are correct rather than plausible, and most of what fills a developer's disk is recognizable without a model. Automatic generation would spend battery and would look like an authoritative answer nobody asked for.
**Trade-offs:** Unknown folders need one click, and the model's answer may be wrong, which the label states. The catalog needs updating when macOS moves a folder.
**Revisit if:** macOS 27's model gets tool calling worth using, or a structured output would be more useful than free text.

---

## 2026-09-23 — Stale projects show Git work that exists only on this Mac
**Chosen:** For a project recognized by its `.git` folder, the app reads uncommitted changes (staged, unstaged, untracked, conflicted), stashes, whether a remote exists, and commits that no remote-tracking branch contains (in total and per local branch). A row badge says "Unpushed Work" or "Pushed"; the inspector lists the details. Reads happen only for projects on screen, three at a time. Every Git call uses `--no-optional-locks`, and `xcode-select -p` is checked before `/usr/bin/git` is run.
**Alternatives:** Only `git status` (misses other branches and stashes); a Git library; reading `.git` files directly.
**Why:** The developer's case: a project left for six months with its last commits never pushed — deleting the folder would lose them. `git rev-list --count --branches --not --remotes` counts exactly the commits that exist nowhere else, across all branches. A plain `git status` rewrites `.git/index`, and the stale-project date is read from that file, so looking at a project would make it look worked on today; `--no-optional-locks` prevents the write (a test checks the index's date is unchanged). `/usr/bin/git` is a shim that opens an install dialog when the developer tools are missing; `xcode-select -p` never does.
**Trade-offs:** Needs the developer tools. Branches without an upstream are counted individually, capped at 12. Temizlikci still never removes a project itself — the information is for the person deciding.
**Revisit if:** Repositories are large enough that `git status` is slow in practice, or submodules need their own check.

---

## 2026-09-23 — Updates: tell, don't install
**Chosen:** At launch, at most once a day, the app asks GitHub's public API for the latest release (`/repos/akinalpfdn/Temizlikci/releases/latest`, which already excludes drafts and pre-releases). A newer version shows a banner above the content with Download (opens the attached DMG in the browser), Release Notes and Not Now (hides that version only). "Check for Updates…" in the app menu always answers; automatic checks stay silent when offline or when nothing is new. Settings can turn the automatic check off.
**Alternatives:** Sparkle with automatic installation; no update check at all.
**Why:** Developer decision: a download button is enough for a Mac app and simpler than an installer. No account, no appcast to host, no install privileges. One unauthenticated request a day is far below GitHub's 60-per-hour limit per IP, and sends nothing about the Mac or its files.
**Trade-offs:** Updating means replacing the app by hand. The check only works while the repository is public (a private repository answers 404, which reads as "no release").
**Revisit if:** Releases become frequent enough that installing by hand is a chore.

---

## 2026-09-23 — Apple silicon only
**Chosen:** The app is built for arm64 only (`ARCHS = arm64` at the project level).
**Alternatives:** A universal binary that also runs on Intel Macs with macOS 26.
**Why:** Developer decision. There is no Intel Mac to test on, and folder explanations (Apple Intelligence) need Apple silicon anyway; shipping only what has been run keeps the README's requirement true.
**Trade-offs:** Intel Macs on macOS 26 — the last macOS for Intel — can't run the app.
**Revisit if:** Someone asks for Intel support and can test it.
