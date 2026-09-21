---
{
  "codeAnchors" : [

  ],
  "createdAt" : "2026-09-21T21:25:23Z",
  "createdBy" : "claude",
  "formatVersion" : 1,
  "id" : "TEMIZLIK-0005",
  "plan" : "- [x] Trashing service (FileManager.trashItem + put back), TrashError with names + next steps\n- [x] Tree editing (remove/insert/re-total), Other Used Space rebalanced after trash\n- [x] LocationScanModel: moveToTrash + UndoManager, putBack, confirmation with Undo, error alerts, outdated notice\n- [x] TrashLedger + Trash view with Put Back + Show Trash in Finder; sidebar Trash badge\n- [x] Edit › Move to Trash (⌘⌫), inspector button, list context menu\n- [x] FDA banner after scans that skipped folders, Open Privacy Settings…, Not Now, recheck on app activation\n- [x] Tests with StubTrash (never the real Trash): 63 pass; commit 52a94ea\n- [ ] Live test with the developer: Move to Trash + Undo on a real item they choose; FDA banner + deep link",
  "priority" : "normal",
  "relatedWorkItemIDs" : [

  ],
  "sprintID" : "TEMIZLIK-SPRINT-1",
  "status" : "inProgress",
  "title" : "Phase 005 (MVP-05): Actions & access",
  "type" : "task",
  "updatedAt" : "2026-09-21T23:35:43Z"
}
---

Mirror of `.claude/phases/PHASE-005-MVP-05-*.md`. TrashService with Undo, tree update without rescan, Trash size guidance, Full Disk Access probe + contextual onboarding + deep link, explicit error states.