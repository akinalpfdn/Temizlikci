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
