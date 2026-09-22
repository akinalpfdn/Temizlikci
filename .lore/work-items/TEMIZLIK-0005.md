---
{
  "codeAnchors" : [

  ],
  "completionNotes" : "Actions & access shipped (52a94ea).\n\n- Move to Trash from inspector, list context menu, Edit › Move to Trash (⌘⌫); no alert (undoable); window UndoManager; Undo toast; tree edited in place; Other Used Space rebalanced (trash still uses space); TrashLedger + Trash view with Put Back and Show Trash in Finder; sidebar Trash badge; TrashError with names and next steps.\n- Full Disk Access banner after scans that skipped protected folders; Open Privacy Settings… (legacy Privacy_AllFiles URL); Not Now; access re-probed on app activation.\n- Tests never touch the real Trash (StubTrash); 63 pass.\n- Live test (developer): Move to Trash via context menu on a real item, chart updated, Undo and Put Back worked.\n\nNot verified live: FDA settings deep link → Phase 7. Feedback: drag to sidebar Trash expected → improvementIdea logged.",
  "createdAt" : "2026-09-21T21:25:23Z",
  "createdBy" : "claude",
  "formatVersion" : 1,
  "id" : "TEMIZLIK-0005",
  "plan" : "- [x] Trashing service (FileManager.trashItem + put back), TrashError with names + next steps\n- [x] Tree editing (remove/insert/re-total), Other Used Space rebalanced after trash\n- [x] LocationScanModel: moveToTrash + UndoManager, putBack, confirmation with Undo, error alerts, outdated notice\n- [x] TrashLedger + Trash view with Put Back + Show Trash in Finder; sidebar Trash badge\n- [x] Edit › Move to Trash (⌘⌫), inspector button, list context menu\n- [x] FDA banner after scans that skipped folders, Open Privacy Settings…, Not Now, recheck on app activation\n- [x] Tests with StubTrash (never the real Trash): 63 pass; commit 52a94ea\n- [ ] Live test with the developer: Move to Trash + Undo on a real item they choose; FDA banner + deep link",
  "priority" : "normal",
  "relatedWorkItemIDs" : [

  ],
  "sprintID" : "TEMIZLIK-SPRINT-1",
  "status" : "done",
  "title" : "Phase 005 (MVP-05): Actions & access",
  "type" : "task",
  "updatedAt" : "2026-09-21T23:58:37Z"
}
---

Mirror of `.claude/phases/PHASE-005-MVP-05-*.md`. TrashService with Undo, tree update without rescan, Trash size guidance, Full Disk Access probe + contextual onboarding + deep link, explicit error states.