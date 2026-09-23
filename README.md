<h1 align="center">Temizlikci</h1>

<p align="center">
  <strong>See what's filling your Mac. Clean up what's safe. Keep what isn't.</strong><br>
  A native macOS disk analyzer that knows what developer files are and which ones you can delete.
</p>

<p align="center">
  <img alt="macOS 26+" src="https://img.shields.io/badge/macOS-26%2B-black">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-orange">
  <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue">
</p>

<!-- GIF: the sunburst on the startup disk, clicking into Users → Library → Developer. Suggested path: docs/media/overview.gif -->

---

## Why

A developer's Mac fills itself up. On the author's 460 GB MacBook, a full cleanup freed 85 GB — and **117 GB came back within 25 days**: DerivedData, device support files, simulator runtimes, Gradle caches, `node_modules`, build folders.

General disk tools show you *that* a folder is big. They can't tell you whether it's a cache Xcode will rebuild, a simulator you should remove with `simctl`, or your archived builds that you need to read crash reports. So you either leave the space alone or delete things and hope.

Temizlikci shows where the space went and labels every developer file it recognizes. Files only ever go to the Trash, where you can put them back; simulators are removed through Xcode's own tool, after you confirm.

## What it does

### See where your space went
- **Sunburst chart and a synchronized list.** Click into any folder; the chart and the sortable, searchable list follow each other. Arrow keys, Return and Escape work on the chart too.
- **Other Used Space, explained.** The space no folder accounts for is split into what it really is: VM swap, Preboot, Recovery, simulator runtimes mounted as disk images, purgeable space — read from the disk's own APFS layout, with no special permissions.
- **What Grew.** Every scan leaves a small summary (about 60 KB). The next scan tells you what grew and what shrank, and the list shows the change next to every folder.
- **Large Files.** The biggest individual files on the disk, one click from the chart or Finder.

<!-- GIF: What Grew with the Grew / Shrank sections. Suggested path: docs/media/what-grew.gif -->

### Clean up without guessing
- **49 rules for developer files** — Xcode, simulators, Swift Package Manager, CocoaPods, Android and Gradle, Flutter and Dart, Node (npm, Yarn, pnpm, Bun), Rust, Go, Python (pip, uv), .NET, Java and Maven, Docker, Unity, JetBrains IDEs, Homebrew.
- **Three labels, each with a reason:**

  | Label | Meaning | Example |
  |---|---|---|
  | **Safe to Remove** | The tool rebuilds it | DerivedData, `node_modules`, `.build`, Gradle caches |
  | **Remove with Tool** | Deleting it by hand breaks something; the reason names the command | Simulator runtimes (`simctl`), uv's cache (`uv cache clean`), pnpm's store (`pnpm store prune`), Docker's disk image |
  | **Keep** | Your data | Xcode Archives, app containers |

  Labels follow each tool's own documentation — for example, uv states its cache is never safe to delete by hand, so Temizlikci doesn't offer to.
- **Nothing is deleted.** Items go to the Trash, with Undo and Put Back. Anything labelled *Keep* or *Remove with Tool* — and anything inside it — can't be moved from Temizlikci at all. There is no "clean everything" button, on purpose.
- **Simulators managed properly.** Unavailable devices and old runtimes are removed through Xcode's own `simctl`, so Xcode's device list stays consistent.

<!-- GIF: Highlight Reclaimable, then moving DerivedData to the Trash and pressing Undo. Suggested path: docs/media/cleanup.gif -->

### Made for developers
- **Stale projects.** Projects nobody has touched for 30 days to a year, with the build output they still hold. "Last worked on" comes from Git, not from folder dates, which don't change when you edit a file.
- **Unpushed work warnings.** Before you delete an old project, Temizlikci tells you what exists only on this Mac: uncommitted and untracked files, stashes, a missing remote, and commits no remote has — on every branch. It reads Git without writing anything, so looking at a project never changes its date.
- **Open in your editor.** Xcode (the workspace, the project or the package), Android Studio, or Visual Studio Code, straight from the project.

<!-- GIF: Stale Projects with an "Unpushed Work" badge and the Git details in the inspector. Suggested path: docs/media/stale-projects.gif -->

### And it's quick about it
- **Opens instantly.** The last scan is saved and shown at launch — about 1.3 seconds for 1.8 million files, instead of a 34-second rescan — then refreshed in the background once it's older than you choose.
- **Grows while it scans.** Large folders fill the chart as they're read instead of appearing all at once at the end.
- **"What is this folder?"** Temizlikci identifies folders macOS defines, the app behind any container or support folder, and file types. For a folder nothing recognizes, you can ask Apple Intelligence for an explanation — on this Mac, clearly labelled, and never allowed to change a label or delete anything.

## Privacy

- No analytics, no accounts, no tracking.
- The only network request is a check for new versions on GitHub, at most once a day. It sends nothing about your Mac or your files, and you can turn it off in Settings.
- Folder explanations run on this Mac with Apple Intelligence. The prompt contains folder and file names with your home folder replaced by `~`, never file contents.
- Without Full Disk Access, Temizlikci doesn't open folders that would trigger a permission prompt (Desktop, Documents, Downloads, Pictures, iCloud Drive, app containers…) and tells you how many it skipped.

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/akinalpfdn/Temizlikci/releases).
2. Drag Temizlikci to Applications and open it.
3. Optional: give it **Full Disk Access** in System Settings › Privacy & Security to measure every folder.

Temizlikci tells you when a new version is out. It never installs anything by itself; you download the new version and replace the app.

**Requirements:** macOS 26 or later, Apple silicon.

## Build from source

Requires Xcode 26.6 (macOS 26.5 SDK, Swift 6).

```sh
git clone https://github.com/akinalpfdn/Temizlikci.git
cd Temizlikci
xcodebuild -project Temizlikci.xcodeproj -scheme Temizlikci -destination 'platform=macOS' -derivedDataPath build/DerivedData build
xcodebuild -project Temizlikci.xcodeproj -scheme Temizlikci -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```

Or open `Temizlikci.xcodeproj` and run the **Temizlikci** scheme.

The tests use temporary folders and in-memory stores. They never touch your real files, your Trash, or the app's saved data.

## How it's built

SwiftUI and Swift 6 with strict concurrency, and no third-party dependencies; the scanner runs off the main thread. The chart is drawn with `Canvas`. Every user-facing string lives in a string catalog, and every color in the chart has light, dark and increased-contrast variants checked for color-blind safety.

| Path | Contents |
|---|---|
| `Temizlikci/App` | App entry point, scenes, menu commands |
| `Temizlikci/Domain` | The scan tree, cleanup rules, history, projects, Git state — plain Swift with tests |
| `Temizlikci/Services` | Scanner, Trash, `simctl`, `diskutil`, Git, update check — each behind a protocol |
| `Temizlikci/Features` | Screens: a SwiftUI view plus an `@Observable` model each |
| `Temizlikci/Theme` | Chart palette, status colors, spacing and type tokens |
| `TemizlikciTests` | Swift Testing suites |

Why things are the way they are is written down in [DECISIONS.md](DECISIONS.md).

## Contributing

Issues and pull requests are welcome. A few rules keep the app trustworthy:

- A new cleanup rule needs a source for its label (the tool's documentation) and a test that it matches its target and not a look-alike.
- Nothing may delete files except through the Trash or the owning tool.
- User-facing text goes through `L10n` and `Localizable.xcstrings`; a test keeps them in sync.

## License

[MIT](LICENSE) © Akinalp Fidan
