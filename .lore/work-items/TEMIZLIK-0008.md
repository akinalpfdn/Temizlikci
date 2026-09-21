---
{
  "codeAnchors" : [

  ],
  "completionNotes" : "Fixed in d4796da. `ScanConfiguration.forScan(access:)` probes Full Disk Access by opening the system TCC.db (silent failure, no prompt). Without FDA, `ProtectedLocations` (Desktop, Documents, Downloads, Music, Pictures, Movies, Library/Mobile Documents, Library/CloudStorage, Library/Containers, Library/Group Containers) are never opened and become `.inaccessible` nodes. Tested on fixtures (`unreadFoldersNotOpened`, `ScanAccessTests`). The benchmark now uses the same configuration and skips `du` when protected folders are inside the root. The one-time, in-context FDA request UI is Phase 5.",
  "createdAt" : "2026-09-21T21:46:04Z",
  "createdBy" : "claude",
  "formatVersion" : 1,
  "id" : "TEMIZLIK-0008",
  "priority" : "high",
  "relatedWorkItemIDs" : [

  ],
  "status" : "done",
  "title" : "Scanner triggers a macOS permission prompt per protected folder",
  "type" : "knownIssue",
  "updatedAt" : "2026-09-21T21:52:07Z"
}
---

Found 2026-09-22 while benchmarking a home-folder scan: without Full Disk Access, the scanner opens TCC-protected folders (~/Music, ~/Pictures, Desktop, Documents, Downloads, Mail, Messages, other apps' Containers…), and macOS shows a separate "Temizlikci would like to access…" prompt for each one. Violates HIG Privacy (ask once, in context) and alarmed the developer.

Expected: without FDA, the scanner does not touch known TCC-protected locations; they appear as "Needs access" nodes, and the app asks for Full Disk Access once, with an explanation (Phase 5 onboarding). With FDA granted, scan everything.

Fix in Phase 3 (scanner skip list + AccessService probe hook), tested on temp fixtures only.