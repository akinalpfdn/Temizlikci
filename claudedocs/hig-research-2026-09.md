# HIG & Platform Research — September 2026

Researched 2026-09-21. Raw HIG page text lives in `claudedocs/hig/*.md` (see `FETCHED_AT`).
Refresh with `scripts/fetch-hig.sh` before any design-heavy phase — HIG changes several times a year.

## Platform state at research time
| Fact | Source |
|---|---|
| macOS 27 "Golden Gate" released 2026-09-14; announced WWDC26 (2026-06-08). Refines Liquid Glass: better diffusion/legibility, user transparency slider, uniform toolbars, edge-to-edge sidebars, consistent window corner radius applied to all apps. Drops Intel. | [9to5Mac](https://9to5mac.com/2026/09/14/macos-27-golden-gate-now-available-here-is-everything-new/), [MacRumors](https://www.macrumors.com/roundup/macos-27/) |
| Xcode 27 (2026-09-15): runs on macOS 26.6+, Apple silicon only, macOS 27 SDK, Swift 6.4. Xcode 26.6 runs on macOS 26.2–26.x only (not on macOS 27). | [Apple — Xcode support](https://developer.apple.com/support/xcode/), [Michael Tsai](https://mjtsai.com/blog/2026/09/15/xcode-27/) |
| WWDC26 SwiftUI: `@State` became a macro (lazy init, backported to macOS 14; source-breaking when assigning in `init` with a default value), `@ContentBuilder`, toolbar `visibilityPriority`, `ToolbarOverflowMenu`, `appearsActive`, reorderable containers, swipe actions on any view — most are macOS 27+. | [WWDC26 — What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/) |
| HIG reintroduced **Design principles** (June 2026): Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight. | [WWDC26 — Principles of great design](https://developer.apple.com/videos/play/wwdc2026/250/), `hig/design-principles.md` |
| Icon Composer 2 and SF Symbols 8 (betas at WWDC26). Project uses Xcode 26.6, so use the Icon Composer version compatible with it. | [Apple Design — What's new](https://developer.apple.com/design/whats-new/) |

**Project decision:** Xcode 26.6 + macOS 26 deployment target (see DECISIONS.md). macOS-27-only APIs are out of scope until migration.

## Rules that shape Temizlikci
| HIG page | Rule | Consequence |
|---|---|---|
| Materials | Liquid Glass is the control layer; don't use it in the content layer; use sparingly on custom controls; regular variant for text-heavy components | Chart/list/background use standard materials; glass comes from system sidebar/toolbar/inspector |
| Color | Apply color sparingly to glass; colorful content → prefer monochromatic toolbars; macOS app accent applies when system accent is "multicolor" | Category colors live in content only; controls stay monochrome/system accent |
| Charting data | Prefer common chart types; novel charts must teach people how to read them; data that only needs browsing belongs in a list/table (scroll, search, sort) | Sunburst **plus** sortable/searchable list; interactive optional intro |
| Charts | Don't rely on color alone; add separators between contiguous color areas; every chart accessible (labels + Audio Graphs); don't require interaction for critical info; keyboard/Switch Control navigation; announce changes, not only animate | Separators, labels, AXChartDescriptor, keyboard ring/sibling navigation, VoiceOver announcements on drill-down |
| Sidebars | ≤2 levels; deeper hierarchies → split view with content list; icons follow system accent unless a fixed color is meaningful (June 2026 update); don't hide by default; nothing critical at the bottom | Sidebar = locations + insights; folder hierarchy lives in content |
| Toolbars (macOS) | Every toolbar item also available as a menu command | Commands + shortcuts for all actions |
| Keyboards | Option-Command-I = inspector window; Command-F = find | Use standard shortcuts; check `hig/keyboards.md` before adding any |
| The menu bar | Always provide a View menu; Show/Hide Sidebar lives there | Standard menus via SwiftUI `Commands` |
| Alerts | No alerts for common undoable destructive actions; irreversible → alert with specific verb, "Cancel", no destructive default for deliberate actions; caution symbol sparingly | Trash = no alert + Undo; simctl delete = alert |
| Privacy | Request only what you need, only when needed, not at launch; explain clearly | FDA onboarding in context |
| Onboarding | Fast, optional, interactive; if skipped don't show again but keep it findable | Optional sunburst intro, reachable from Help |
| Writing | Clear next steps on empty states; clear, blame-free error messages; consistent capitalization per element type | Title-style buttons/menus; sentence-style informative text |

## Technical facts
- No public API reports Full Disk Access status; probe a TCC-protected path. Deep link: `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles` (verify on macOS 26). [Apple Developer Forums](https://developer.apple.com/forums/thread/741289)
- `getattrlistbulk` performs about the same as `contentsOfDirectory`; `opendir` is faster on APFS. [Michael Tsai](https://mjtsai.com/blog/2019/04/22/performance-considerations-when-reading-directories-on-macos/)
- APFS clones share blocks and macOS offers no API to attribute them; hard links can be deduped by identity. [DaisyDisk guide](https://daisydiskapp.com/guide/4/en/HardLinks/), [Eclectic Light](https://eclecticlight.co/2023/04/28/apfs-hard-links-symlinks-aliases-and-clone-files-a-summary/)
- On this machine `/Library/Developer/CoreSimulator/Volumes/*` are mounted runtime images; `du` counted them (~57 GB) on top of the image files.
