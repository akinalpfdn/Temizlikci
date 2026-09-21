---
{
  "codeAnchors" : [

  ],
  "completionNotes" : "Design approved by the developer on 2026-09-22.\n\nShipped:\n- HIG research: `claudedocs/hig-research-2026-09.md`, 32 raw HIG pages in `claudedocs/hig/` (refresh via `scripts/fetch-hig.sh`).\n- Interactive prototype: https://claude.ai/artifact/HjFcHStMX4Lnhigg6v4vbY (source `claudedocs/design/mockups.html`): overview, scanning, first launch, FDA, developer, delete-runtime alert; light/dark.\n- Visual direction: calm, instrument-grade Mac utility; native macOS 26 chrome; sunburst is the only source of color.\n- Approved: color by top-level folder (slots by size, depth = lighter tint, 9th+ → Smaller items); Highlight Reclaimable toggle (green/amber/gray + symbol + label); vocabulary Safe to Remove / Remove with Tool / Keep; click select, double-click open, center/Escape up; sidebar = Locations + Insights; inspector trailing.\n\nGotchas:\n- The `design` canvas skill is user-invoke-only, so an HTML prototype was used instead.\n- High-contrast system color variants could not be read via NSAppearance.performAsCurrentDrawingAppearance — verify in-app in Phase 2.",
  "createdAt" : "2026-09-21T21:25:23Z",
  "createdBy" : "claude",
  "formatVersion" : 1,
  "id" : "TEMIZLIK-0001",
  "priority" : "high",
  "relatedWorkItemIDs" : [
    "83"
  ],
  "sprintID" : "TEMIZLIK-SPRINT-1",
  "status" : "done",
  "title" : "Phase 001 (MVP-01): Design direction & mockups",
  "type" : "task",
  "updatedAt" : "2026-09-21T21:26:13Z"
}
---

Mirror of `.claude/phases/PHASE-001-MVP-01-*.md`. Approved visual design before UI code: visual direction, validated chart palette, interactive prototype of main window states, app icon concept.

Proposal: https://claude.ai/artifact/HjFcHStMX4Lnhigg6v4vbY (source `claudedocs/design/mockups.html`).