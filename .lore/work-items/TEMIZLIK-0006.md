---
{
  "codeAnchors" : [

  ],
  "completionNotes" : "Developer insights shipped (3e10583).\n\n- 24-rule catalog + RuleEngine (paths, simulator runtime assets under /System/Library/AssetsV2, project folders with marker files, outermost match), off the main actor.\n- Safety levels drive actions: Safe → Move to Trash; Tool → simctl / Android Studio only; Keep → never deletable. Badges in list/inspector, Highlight Reclaimable restored.\n- Developer view: summary chart, ecosystem groups with reclaimable totals and reasons; Simulators section with unavailable devices and runtimes, simctl deletions behind confirmation alerts, errors surfaced.\n- Tests: 78 (77 pass, 1 opt-in).\n- Live test: developer reviewed the Developer view on real data and was happy with it.\n- Found on this Mac: 29 unavailable simulator devices left after runtime removal.",
  "createdAt" : "2026-09-21T21:25:23Z",
  "createdBy" : "claude",
  "formatVersion" : 1,
  "id" : "TEMIZLIK-0006",
  "plan" : "- [x] CleanupRule catalog (24 rules: Xcode, Simulators, Android, Flutter/Dart, Node, Go, Homebrew, App Data) + RuleEngine (paths, child-of patterns, project folders with marker files, outermost match), off-main via @concurrent\n- [x] Safety levels drive actions: Safe → Move to Trash; Tool → simctl / Android Studio only; Keep → never deletable\n- [x] Badges in list and inspector (symbol + label), Highlight Reclaimable restored (toolbar + View menu)\n- [x] Developer view: summary chart (Swift Charts), groups with reclaimable totals, per-item reasons and actions\n- [x] ToolRunner + SimulatorService (JSON), SimulatorsModel: unavailable devices + runtimes, confirmation alerts, errors surfaced\n- [x] Tests: 78 (77 pass, 1 opt-in); commit 3e10583\n- [ ] Live test with the developer on real data (29 unavailable simulators found on this Mac)",
  "priority" : "normal",
  "relatedWorkItemIDs" : [

  ],
  "sprintID" : "TEMIZLIK-SPRINT-1",
  "status" : "done",
  "title" : "Phase 006 (MVP-06): Developer insights",
  "type" : "task",
  "updatedAt" : "2026-09-22T00:27:08Z"
}
---

Mirror of `.claude/phases/PHASE-006-MVP-06-*.md`. CleanupRule strategies + RuleEngine, safety levels (Safe to Remove / Remove with Tool / Keep), Developer view, ToolRunner for simctl (JSON) with confirmation alerts.