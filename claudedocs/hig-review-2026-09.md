# HIG Compliance Review — Phase 7

Reviewed 2026-09-22 against `claudedocs/hig-research-2026-09.md` and the raw pages in `claudedocs/hig/` (fetched 2026-09-21).
Status: ✅ meets the guideline · 🔧 fixed during this review · ⏳ needs a live check with the developer.

| Area (HIG page) | Guideline | Status | Evidence |
|---|---|---|---|
| Materials | Liquid Glass only in the control layer | ✅ | Glass comes from the system sidebar, toolbar, and inspector; the only custom `glassEffect` is the transient Move to Trash confirmation (a control). Chart, list, and banners use standard backgrounds. |
| Color | System colors for UI; custom colors with light, dark, and increased-contrast variants | ✅ | Chart palette validated in all four variants (DECISIONS 2026-09-22); status colors only with symbol and label. |
| Charting data | Novel chart paired with a conventional list; teach it | ✅ 🔧 | Sunburst plus sortable, searchable table; an optional interactive introduction added in Phase 7 (Help › How to Read the Chart). |
| Charts | Don't rely on color alone; separators; accessibility labels; Audio Graphs; keyboard | ✅ | 2 pt separators, labels on large segments, badges in list and inspector, one accessibility element per segment, `AXChartDescriptor`, arrow, Return, and Escape navigation. Developer checked with VoiceOver (2026-09-22). |
| Sidebars | ≤ 2 levels; accent-colored icons; Show/Hide in View menu | ✅ 🔧 | Locations and Insights only; `SidebarCommands`; free-space badge added to match the approved design. |
| Toolbars | Every toolbar item also in the menu bar | ✅ 🔧 | Back/Forward/Enclosing (Go), Rescan/Stop (File), Highlight Reclaimable (View), Inspector (`InspectorCommands`), Search: Edit › Find (Command-F) added in Phase 7. |
| Keyboards | Standard shortcuts | ✅ | Command-O, Command-R, Command-Period, Option-Command-I, Command-F, Command-Y, Command-Delete, Command-[ / Command-] / Command-Up Arrow (DECISIONS "Chart interaction model"). |
| The menu bar | A View menu; no dead items | ✅ 🔧 | The default Help item ("Help isn't available") was replaced by the chart introduction. |
| Alerts | No alerts for undoable actions; specific verbs for irreversible ones | ✅ | Move to Trash has no alert and offers Undo; simctl deletions use "Delete Simulators" / "Delete Runtime" with Cancel. |
| Privacy | Ask only when needed, in context | ✅ | No prompt at launch; consent-prompting folders are never opened without Full Disk Access; a banner explains after a scan. The developer confirmed the deep link opens Full Disk Access on macOS 26. |
| Onboarding | Optional, interactive, not repeated, findable later | ✅ 🔧 | Shown once after the first scan (`hasSeenChartIntro`), clickable example chart, Help menu entry. |
| Writing | Title-style buttons, sentence-style messages, clear next steps, blame-free errors | ✅ | Reviewed every catalog string (174 after removing 4 unused ones): buttons in title style, alert titles as questions or fragments, every error names the item and suggests a next step. A test now fails on unused strings. |
| Accessibility | VoiceOver, Increase Contrast, Reduce Transparency, Reduce Motion | ✅ | Reduce Motion swaps the drill-down scale for a fade; increased-contrast colors are declared and compiled. The developer checked VoiceOver, Increase Contrast, and Reduce Transparency and found no problems (2026-09-22). |
| App icons | Layered icon built with Icon Composer | ✅ | `Temizlikci/Resources/AppIcon.icon`, assembled by the developer from the approved concept; layered stack and .icns fallback verified in the build. |

## Open items
None. All items were verified live with the developer on 2026-09-22.

---

# Re-review for Phases 008–014 (release)

Reviewed 2026-09-23 against the raw pages in `claudedocs/hig/` (fetched 2026-09-21; Settings, Drag and drop, Panels, Generative AI and Machine learning added 2026-09-22/23).

| Feature | HIG page | Guideline | Status | Evidence |
|---|---|---|---|---|
| What Grew colors | Color, Charts | Don't rely on color alone | ✅ | Warm/cool ink plus arrow symbol, +/− sign, section heading and bar length; four validated variants (DECISIONS 2026-09-22). |
| Growth badge | Layout | Content must not break in narrow columns | ✅ 🔧 | Badge wrapped letter by letter in the inspector; now one line with its own row (2026-09-23). |
| Developer sections | Disclosure controls, Accessibility | Progressive disclosure; controls at least 20×20 pt on macOS | ✅ 🔧 | Ten open sections replaced by disclosure groups; the whole header (min 28 pt) toggles, not only the 13 pt triangle; VoiceOver reads Expanded/Collapsed. |
| Developer and Stale Projects rows | Accessibility (mobility, Full Keyboard Access) | Every action reachable without a pointer | ✅ 🔧 | Rows were click-only; now focusable, Return/Space select or open them. |
| Inspector for insight views | Panels, Split views | The inspector reflects the current selection | ✅ 🔧 | Developer and Large Files selections now show in the inspector; the selection clears when the sidebar destination changes. |
| Git warning | Color, Writing | Warnings pair color with a symbol and text; clear next step | ✅ | Orange ink with `exclamationmark.triangle.fill` and "Push or back it up before deleting this project". |
| Drag to Trash | Drag and drop | Menu alternative, undo, feedback on failure | ✅ | Move to Trash ⌘⌫ in the menu; same Undo path; refused drops return to the source. Multi-item drags aren't supported (the list is single-selection). |
| Highlight Reclaimable icon | SF Symbols, Generative AI | Don't imply AI where there is none | ✅ 🔧 | `sparkles` (read as Apple Intelligence) replaced by `wand.and.rays`; disabled state explains why. |
| "What is this?" | Generative AI | On request, labelled, retryable, on-device, no destructive actions, works without AI | ✅ | See DECISIONS 2026-09-22. |
| Update banner | Alerts, Writing | No alert for non-critical news; specific button titles | ✅ | Inline banner, not an alert; Download / Release Notes / Not Now; the manual check answers with an alert because the person asked. |
| Check for Updates… | The menu bar | App menu, after About | ✅ | `CommandGroup(after: .appInfo)`. |
| Settings window | Settings | App menu item and ⌘,; single pane titled "App Name Settings" | ✅ 🔧 | The pane set its title to "General"; removed so the system title "Temizlikci Settings" shows. |
| Scanning progress | Progress indicators, Charts | Show progress that reflects real work | ✅ 🔧 | The chart now grows with each top-level folder's measured size; a late update could replace the finished result, closed by three guards (2026-09-23). |
| About panel | — | Copyright shown in About | ✅ 🔧 | The project set it to an empty string; now "© 2026 Akinalp Fidan. MIT License." |

## Open items
- Live check with the developer: Tab through the Developer view with Full Keyboard Access on, and the Settings window title.
